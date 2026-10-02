// Confrontational message engine for reminders. Pure Dart, fully tested.
//
// Three escalation tiers (calm → firm → blunt) fill in real data:
// commitment title, target time, current time, streak, day number, and the
// last excuse. Tone is direct and honest, never cruel: it confronts behavior,
// never the person. No weight, body, or appearance references anywhere
// (enforced by an automated banned-word test).

/// Escalation tier. Higher tiers hit harder, never insult.
enum ReminderTier { calm, firm, blunt }

/// User's tone setting: a cap on escalation.
enum ReminderTone { calm, firm, blunt }

/// When the reminder fires relative to the commitment.
enum ReminderKind { upcoming, followUp, lastCall }

class ReminderContext {
  const ReminderContext({
    required this.kind,
    required this.title,
    this.targetTime,
    required this.nowTime,
    required this.streak,
    required this.dayNumber,
    this.lastExcuse,
    this.doneCount,
    this.totalCount,
    this.consecutiveMisses = 0,
    this.toneCap = ReminderTone.blunt,
    this.isPaused = false,
  });

  final ReminderKind kind;
  final String title;
  final String? targetTime;
  final String nowTime;
  final int streak;
  final int dayNumber;
  final String? lastExcuse;
  final int? doneCount;
  final int? totalCount;
  final int consecutiveMisses;
  final ReminderTone toneCap;
  final bool isPaused;
}

class ReminderMessage {
  const ReminderMessage({required this.title, required this.body});

  final String title;
  final String body;
}

/// Picks the tier: pauses always soften to calm; otherwise consecutive
/// misses escalate, capped by the user's tone setting.
ReminderTier tierFor(ReminderContext ctx) {
  if (ctx.isPaused) {
    return ReminderTier.calm;
  }
  final ReminderTier earned;
  if (ctx.consecutiveMisses <= 0) {
    earned = ReminderTier.calm;
  } else if (ctx.consecutiveMisses == 1) {
    earned = ReminderTier.firm;
  } else {
    earned = ReminderTier.blunt;
  }
  if (ctx.toneCap == ReminderTone.calm) {
    return ReminderTier.calm;
  }
  if (ctx.toneCap == ReminderTone.firm && earned == ReminderTier.blunt) {
    return ReminderTier.firm;
  }
  return earned;
}

/// Deterministic template choice so the same (context, salt) always renders
/// the same text. Stable across runs (Dart String.hashCode is not).
int stableHash(String value) {
  int hash = 0x811C9DC5;
  for (int i = 0; i < value.length; i++) {
    hash ^= value.codeUnitAt(i);
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Renders the message for [ctx]. [salt] varies the pick (e.g. the date).
ReminderMessage pickMessage(ReminderContext ctx, {required String salt}) {
  final ReminderTier tier = tierFor(ctx);
  final List<String> pool;
  if (ctx.isPaused) {
    pool = _pausedTemplates;
  } else {
    pool = _templates[tier]![ctx.kind]!;
  }
  final String template = pool[stableHash('${ctx.title}|$salt') % pool.length];
  return ReminderMessage(
    title: _fill(_titles[ctx.kind]!, ctx),
    body: _fill(template, ctx),
  );
}

String _cap(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}

String _fill(String template, ReminderContext ctx) {
  return template
      .replaceAll('{title}', ctx.title)
      .replaceAll('{target}', ctx.targetTime ?? '')
      .replaceAll('{now}', ctx.nowTime)
      .replaceAll('{streak}', '${ctx.streak}')
      .replaceAll('{day}', '${ctx.dayNumber}')
      .replaceAll(
        '{excuse}',
        ctx.lastExcuse == null ? '' : _cap(ctx.lastExcuse!),
      )
      .replaceAll('{done}', '${ctx.doneCount ?? 0}')
      .replaceAll('{total}', '${ctx.totalCount ?? 0}');
}

const Map<ReminderKind, String> _titles = <ReminderKind, String>{
  ReminderKind.upcoming: '{title} · {target}',
  ReminderKind.followUp: 'Still pending: {title}',
  ReminderKind.lastCall: 'Day {day} check',
};

const List<String> _pausedTemplates = <String>[
  'Paused today. {title} waits. Heal first, ledger later.',
  'Rest is the assignment today. Streak {streak} is safe.',
  'Day {day} is a pause day. No check-in needed. Come back honest.',
  'Sick or hurt is data, not failure. {title} resumes when you do.',
  'The contract holds while you recover. Day {day} is covered.',
  'Take the day. The streak ({streak}) is not going anywhere.',
];

const Map<ReminderTier, Map<ReminderKind, List<String>>> _templates = {
  ReminderTier.calm: {
    ReminderKind.upcoming: [
      '{target}. {title}. Be there.',
      '{title} at {target}. Day {day} is yours to keep.',
      'Coming up at {target}: {title}. Streak {streak} likes routine.',
      '{target} — {title}. Small promise, keep it.',
      'Day {day}: {title} at {target}. Start before you negotiate.',
      '{title}. {target}. You wrote this one down for a reason.',
      'At {target}, it is {title} o\u2019clock. Day {day}.',
      'Reminder, not a lecture: {title} at {target}.',
    ],
    ReminderKind.followUp: [
      'It is {now}. You said {target} for {title}. Still today.',
      '{target} passed for {title}. The window is still open at {now}.',
      'Checking in: {title} was due at {target}. Log it done.',
      '{now} — {title} is still waiting from {target}. Go.',
      'You planned {title} at {target}. {now} is your second chance today.',
      '{title}: due {target}, now {now}. Done beats perfect.',
      'Gentle but firm: {target} came and went. {title} is still due.',
      'Day {day}, {now}: {title} has not been logged yet.',
    ],
    ReminderKind.lastCall: [
      'Day {day}: {done} of {total} done. Close it out.',
      'Last call, day {day}. {done} of {total} logged.',
      'Evening check: {done}/{total} today. Streak sits at {streak}.',
      'Day {day} ends soon. {done} of {total} — finish one more.',
      'The ledger closes tonight: {done} of {total} on day {day}.',
      '{done} of {total}. Log what is done before midnight.',
      'Day {day} review: {done}/{total}. Honest numbers only.',
      'Tonight decides day {day}: {done} of {total} so far.',
    ],
  },
  ReminderTier.firm: {
    ReminderKind.upcoming: [
      '{target}. {title}. Yesterday\u2019s miss does not get a sequel.',
      'Day {day}: {title} at {target}. You slipped once — not twice.',
      '{title} at {target}. “{excuse}” was yesterday\u2019s story.',
      '{target} is the line. {title}. Hold it today.',
      'One miss on the board. {title} at {target} is how you answer.',
      'Day {day} will ask about {title} at {target}. Have an answer.',
      '{target}: {title}. Rebuild the streak one kept promise at a time.',
      'Yesterday is logged. Today\u2019s {title} is at {target}. Show up.',
    ],
    ReminderKind.followUp: [
      'It is {now}. You said {target}. {title} is still undone.',
      '{target} was the deal for {title}. It is {now}. Move.',
      '“{excuse}” is already on yesterday\u2019s ledger. {title} is due now.',
      '{now}, and {title} from {target} is open. Excuses don\u2019t log reps.',
      'You missed one already. {title} at {target} — don\u2019t stack misses.',
      'The clock says {now}; the plan said {target}. {title}. Now.',
      'Day {day} is watching: {title} due since {target}.',
      'Still undone at {now}: {title}. Yesterday\u2019s reason expired.',
    ],
    ReminderKind.lastCall: [
      'Day {day}. “{excuse}” again? {done} of {total} says otherwise — log it.',
      'Last call: {done} of {total} on day {day}. Yesterday repeated is a choice.',
      'Evening truth: {done}/{total}. The ledger remembers {excuse} too.',
      'Day {day} closes with {done} of {total}. One miss is data; two is a pattern.',
      '{done} of {total}. Yesterday\u2019s excuse does not cover today.',
      'Day {day}: {done}/{total}. Streak {streak} survives only if you close out.',
      'Final hour honesty: {done} of {total}. What gets logged?',
      '“{excuse}” was yesterday. Today is {done} of {total} — finish it.',
    ],
  },
  ReminderTier.blunt: {
    ReminderKind.upcoming: [
      '{target}. {title}. Two misses deep — today is the wall.',
      'Day {day}: {title} at {target}. The pattern ends here or not at all.',
      '“{excuse}” twice in a row. {title} at {target} is the rebuttal.',
      '{target} is non-negotiable today. {title}. No third miss.',
      'Streak {streak} after back-to-back misses. {title} at {target} decides.',
      'Day {day} does not care about yesterday. {title}, {target}. Go.',
      'The ledger shows a slide. {title} at {target} stops it.',
      'Last warning from yourself: {title} at {target}, day {day}.',
    ],
    ReminderKind.followUp: [
      'It\u2019s {now}. You said {target}. {title} undone, misses stacking.',
      '{target} passed. {now} now. {title} still open — this is the moment.',
      '“{excuse}” three days running? {title} was due at {target}.',
      'Day {day}, {now}: {title} overdue since {target}. Stand up.',
      'The story writes itself unless {title} gets done. {target} was the time.',
      '{now}. Still no {title}. {target} was hours ago. Enough.',
      'Miss, miss, and now {title} hanging since {target}. Break it today.',
      'Nobody is coming to log {title} for you. {target} passed at {now} minus excuses.',
    ],
    ReminderKind.lastCall: [
      'Day {day}. “{excuse}” again? {done} of {total}. The mirror is not flattering.',
      'Last call, day {day}: {done}/{total}. Patterns become identity. Log something.',
      'Evening ledger: {done} of {total}, streak {streak}. “{excuse}” is getting old.',
      'Day {day} ends {done}/{total}. You know what this costs.',
      '{done} of {total}. The data says slide; only action edits tomorrow.',
      'Final call day {day}: {done}/{total}. Yesterday\u2019s excuse, today\u2019s too?',
      '“{excuse}” again — {done} of {total}. Prove the ledger wrong tomorrow.',
      'Day {day}: {done} of {total}. Sleep knowing exactly what happened.',
    ],
  },
};
