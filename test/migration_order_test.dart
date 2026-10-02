// Migration dependency-order regression test.
//
// Postgres validates CREATE POLICY / CREATE TRIGGER / FK references at
// creation time, so every referenced table, trigger function, and policy
// target must already exist. A policy referencing a later-created table
// fails the whole migration with 42P01 (this bit Stage 5B on first push:
// squads_select_member referenced squad_members before its CREATE TABLE).
//
// The test scans supabase/migrations/*.sql in filename order with regexes
// (function bodies are dollar-quoted out first: plpgsql validates those at
// first call, not at creation, so they are order-exempt by design).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _stripDollarQuoted(String src) {
  // Blank out everything between $$ pairs (plpgsql function bodies).
  // Bodies validate at first call, not at creation, so they are
  // order-exempt by design. Also strip -- line comments so prose never
  // matches the statement matchers below.
  final List<String> parts = src.split('\$\$');
  final StringBuffer out = StringBuffer();
  for (int i = 0; i < parts.length; i++) {
    out.write(i.isEven ? parts[i] : '/*fn*/');
  }
  final List<String> lines = out.toString().split('\n');
  return lines
      .map((String line) {
        final int comment = line.indexOf('--');
        return comment < 0 ? line : line.substring(0, comment);
      })
      .join('\n');
}

void main() {
  test('policies, triggers, and FKs only reference earlier-created tables', () {
    final Directory dir = Directory('supabase/migrations');
    expect(
      dir.existsSync(),
      isTrue,
      reason: 'run flutter test from the project root',
    );
    final List<File> files =
        dir
            .listSync()
            .whereType<File>()
            .where((File f) => f.path.endsWith('.sql'))
            .toList()
          ..sort((File a, File b) => a.path.compareTo(b.path));
    expect(files, isNotEmpty);

    // Global creation order across files: table name -> event index.
    final Map<String, int> tableCreatedAt = <String, int>{};
    final Map<String, int> functionCreatedAt = <String, int>{};
    final List<String> problems = <String>[];
    int clock = 0;

    final RegExp createTable = RegExp(
      r'create\s+table\s+(?:if\s+not\s+exists\s+)?public\.(\w+)',
      caseSensitive: false,
    );
    final RegExp createFunction = RegExp(
      r'create\s+(?:or\s+replace\s+)?function\s+public\.(\w+)\s*\(',
      caseSensitive: false,
    );
    // Trigger targets and executed functions:
    //   [DROP TRIGGER IF EXISTS n ON] public.T ... EXECUTE FUNCTION public.f()
    final RegExp triggerOn = RegExp(
      r'(?:create\s+trigger\s+\w+\s+before\s+\w+.*?on\s+public\.(\w+))|'
      r'(?:drop\s+trigger\s+if\s+exists\s+\w+\s+on\s+public\.(\w+))',
      caseSensitive: false,
      dotAll: true,
    );
    final RegExp triggerFn = RegExp(
      r'execute\s+function\s+public\.(\w+)\s*\(\)',
      caseSensitive: false,
    );
    // Policy targets and referenced tables:
    //   [DROP POLICY IF EXISTS "n" ON] public.T ... [USING (...) / WITH CHECK (...)]
    final RegExp policyOn = RegExp(
      r'(?:create\s+policy\s+.*?\s+on\s+public\.(\w+))|'
      r'(?:drop\s+policy\s+if\s+exists\s+.*?\s+on\s+public\.(\w+))',
      caseSensitive: false,
      dotAll: true,
    );
    final RegExp publicRef = RegExp(r'public\.(\w+)');
    final RegExp fkRef = RegExp(
      r'references\s+public\.(\w+)',
      caseSensitive: false,
    );

    for (final File file in files) {
      final String name = file.path.split(Platform.pathSeparator).last;
      final String flat = _stripDollarQuoted(file.readAsStringSync());
      // Split into statements on top-level semicolons.
      final List<String> statements = flat.split(';');
      for (final String stmt in statements) {
        clock += 1;
        final String lower = stmt.toLowerCase();
        final bool isCreateTable = lower.contains('create table');
        final bool isCreatePolicy = lower.contains('create policy');
        final bool isCreateTrigger = lower.contains('create trigger');

        for (final RegExpMatch m in createTable.allMatches(stmt)) {
          tableCreatedAt.putIfAbsent(m.group(1)!, () => clock);
        }
        for (final RegExpMatch m in createFunction.allMatches(stmt)) {
          functionCreatedAt.putIfAbsent(m.group(1)!, () => clock);
        }
        if (isCreateTable) {
          for (final RegExpMatch m in fkRef.allMatches(stmt)) {
            final String? ref = m.group(1);
            final int? at = tableCreatedAt[ref];
            if (at == null || at >= clock) {
              problems.add(
                '$name: FK references public.$ref before it is created',
              );
            }
          }
        }
        if (isCreatePolicy || lower.contains('drop policy')) {
          for (final RegExpMatch m in policyOn.allMatches(stmt)) {
            final String? target = m.group(1) ?? m.group(2);
            if (target != null) {
              final int? at = tableCreatedAt[target];
              if (at == null || at >= clock) {
                problems.add(
                  '$name: policy targets public.$target before it exists',
                );
              }
            }
          }
          if (isCreatePolicy) {
            for (final RegExpMatch m in publicRef.allMatches(stmt)) {
              final String? ref = m.group(1);
              // Skip the policy's own target table match duplication is
              // harmless: a target always exists by the check above.
              final int? at = tableCreatedAt[ref];
              if (at == null || at >= clock) {
                problems.add(
                  '$name: policy references public.$ref before it is created',
                );
              }
            }
          }
        }
        if (isCreateTrigger || lower.contains('drop trigger')) {
          for (final RegExpMatch m in triggerOn.allMatches(stmt)) {
            final String? target = m.group(1) ?? m.group(2);
            if (target != null) {
              final int? at = tableCreatedAt[target];
              if (at == null || at >= clock) {
                problems.add(
                  '$name: trigger targets public.$target before it exists',
                );
              }
            }
          }
          for (final RegExpMatch m in triggerFn.allMatches(stmt)) {
            final String? fn = m.group(1);
            final int? at = functionCreatedAt[fn];
            if (at == null || at >= clock) {
              problems.add(
                '$name: trigger executes public.$fn() before it is created',
              );
            }
          }
        }
      }
    }

    expect(
      problems,
      isEmpty,
      reason: 'migration ordering problems:\n${problems.join('\n')}',
    );
  });

  test('squads_select_member is created after squad_members (regression)', () {
    final String src = File('supabase/migrations/20261002140000_squads.sql')
        .readAsStringSync();
    final int tablePos = src.indexOf(
      'create table if not exists public.squad_members',
    );
    final int policyPos = src.indexOf('create policy "squads_select_member"');
    expect(tablePos, greaterThanOrEqualTo(0));
    expect(policyPos, greaterThanOrEqualTo(0));
    expect(
      policyPos,
      greaterThan(tablePos),
      reason:
          'squads_select_member references squad_members, so its CREATE '
          'POLICY must come after the CREATE TABLE (else 42P01 on push)',
    );
  });
}
