import 'reporter_texts_de.dart';

/// The texts of the radio reporter (step 10d2). A text is found by a key
/// such as `goal.own.e3` or `step.dribble.won.pretty`; the reporter asks
/// several keys from special to general and takes the first that has texts.
///
/// Placeholders: `{p}` the player on the ball (scorer, culprit, player
/// coming on), `{o}` his opponent in a duel (in a lost ball the winner),
/// `{q}` the second player (assist, player going off), `{team}` the club of
/// the event, `{opp}` the other club, `{home}`, `{away}`, `{score}` home to
/// away, `{ours}` the score seen from the reporter's club, `{where}` a word
/// for the lane, `{n}` a number (minutes of stoppage), `{days}`, `{k}` the
/// keeper who faced a shot, `{ref}` the referee (step 10e1).
///
/// Keys with `own` are for the club the reporter sides with ("wir"), keys
/// with `opp` for the other one. Another language is one more
/// implementation.
abstract interface class ReporterStrings {
  /// The texts for [key]; empty if there are none.
  List<String> texts(String key);

  /// All keys with texts (for tests).
  Iterable<String> get keys;
}

class ReporterStringsDe implements ReporterStrings {
  const ReporterStringsDe();

  @override
  List<String> texts(String key) => reporterTextsDe[key] ?? const [];

  @override
  Iterable<String> get keys => reporterTextsDe.keys;
}
