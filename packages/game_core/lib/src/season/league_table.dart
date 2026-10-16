import '../model/ids.dart';

/// One line of a league table.
class TableEntry {
  TableEntry(this.club);

  final ClubId club;
  int played = 0;
  int won = 0;
  int drawn = 0;
  int lost = 0;
  int goalsFor = 0;
  int goalsAgainst = 0;

  int get points => won * 3 + drawn;
  int get goalDifference => goalsFor - goalsAgainst;
}

/// A league table. Order: points, goal difference, goals scored, club id
/// (so that the order is always the same for the same results).
class LeagueTable {
  LeagueTable(List<ClubId> clubs)
    : _entries = {for (final c in clubs) c: TableEntry(c)};

  final Map<ClubId, TableEntry> _entries;

  /// An independent copy, for example to add live scores to it.
  LeagueTable copy() {
    final table = LeagueTable(_entries.keys.toList());
    for (final e in _entries.values) {
      table._entries[e.club]!
        ..played = e.played
        ..won = e.won
        ..drawn = e.drawn
        ..lost = e.lost
        ..goalsFor = e.goalsFor
        ..goalsAgainst = e.goalsAgainst;
    }
    return table;
  }

  void record(ClubId home, ClubId away, int homeGoals, int awayGoals) {
    final h = _entries[home]!;
    final a = _entries[away]!;
    h
      ..played += 1
      ..goalsFor += homeGoals
      ..goalsAgainst += awayGoals;
    a
      ..played += 1
      ..goalsFor += awayGoals
      ..goalsAgainst += homeGoals;
    if (homeGoals > awayGoals) {
      h.won += 1;
      a.lost += 1;
    } else if (homeGoals < awayGoals) {
      a.won += 1;
      h.lost += 1;
    } else {
      h.drawn += 1;
      a.drawn += 1;
    }
  }

  TableEntry entryOf(ClubId club) => _entries[club]!;

  /// Entries from first to last place.
  List<TableEntry> get standing {
    final list = _entries.values.toList()
      ..sort((a, b) {
        var c = b.points.compareTo(a.points);
        if (c != 0) return c;
        c = b.goalDifference.compareTo(a.goalDifference);
        if (c != 0) return c;
        c = b.goalsFor.compareTo(a.goalsFor);
        if (c != 0) return c;
        return a.club.value.compareTo(b.club.value);
      });
    return list;
  }

  List<ClubId> get order => [for (final e in standing) e.club];
}
