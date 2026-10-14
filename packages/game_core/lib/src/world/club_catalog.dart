import '../model/club.dart';
import '../model/ids.dart';
import '../model/region.dart';
import '../result/result.dart';
import '../rules/rules.dart';

/// Why the club list could not be used.
class CatalogError {
  const CatalogError(this.message);

  final String message;

  @override
  String toString() => 'CatalogError: $message';
}

/// One row of the reviewed club list.
class ClubEntry {
  const ClubEntry({
    required this.id,
    required this.name,
    required this.place,
    required this.tier,
    required this.region,
    required this.secondTeam,
  });

  /// Fixed id: the position in the file, starting at 1. New clubs may only
  /// be appended, never inserted, so ids never change.
  final ClubId id;
  final String name;
  final String place;

  /// 1 to 4 are the league tiers, 5 marks a pool club.
  final int tier;

  /// Home region (for the first three tiers taken from the place).
  final Region region;
  final bool secondTeam;

  bool get isPool => tier == poolTier;

  static const int poolTier = 5;
}

/// The 206 fictional clubs with fixed ids, read from
/// `tools/data/vereine_2026_27.csv` (semicolon separated).
class ClubCatalog {
  const ClubCatalog._(this.entries);

  final List<ClubEntry> entries;

  static const Map<int, int> _expectedPerTier = {
    1: 18,
    2: 18,
    3: 20,
    4: 90,
    5: 60,
  };

  static Result<ClubCatalog, CatalogError> parse(String csv) {
    try {
      return Ok(ClubCatalog._(List.unmodifiable(_parse(csv))));
    } on CatalogError catch (e) {
      return Err(e);
    }
  }

  static List<ClubEntry> _parse(String csv) {
    final rows = _rows(csv);
    if (rows.isEmpty) throw const CatalogError('Empty club list');
    final header = rows.first;
    int column(String name) {
      final i = header.indexOf(name);
      if (i < 0) throw CatalogError('Missing column $name');
      return i;
    }

    final cTier = column('Ebene');
    final cName = column('Fiktiver Verein');
    final cPlace = column('Ort');
    final cSecond = column('Zweitmannschaft');
    final cRegion = column('Heimatregion');

    final entries = <ClubEntry>[];
    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.length < header.length) {
        throw CatalogError('Row ${i + 1} has too few columns');
      }
      final tier = int.tryParse(row[cTier]);
      if (tier == null || tier < 1 || tier > 5) {
        throw CatalogError('Row ${i + 1}: invalid tier "${row[cTier]}"');
      }
      final regions = Region.values.where((r) => r.id == row[cRegion]);
      if (regions.isEmpty) {
        throw CatalogError('Row ${i + 1}: unknown region "${row[cRegion]}"');
      }
      final second = row[cSecond];
      if (second != 'Ja' && second != 'Nein') {
        throw CatalogError('Row ${i + 1}: Zweitmannschaft must be Ja or Nein');
      }
      if (row[cName].isEmpty || row[cPlace].isEmpty) {
        throw CatalogError('Row ${i + 1}: name or place is empty');
      }
      entries.add(
        ClubEntry(
          id: ClubId(i),
          name: row[cName],
          place: row[cPlace],
          tier: tier,
          region: regions.first,
          secondTeam: second == 'Ja',
        ),
      );
    }

    if (entries.map((e) => e.name).toSet().length != entries.length) {
      throw const CatalogError('Club names must be unique');
    }
    for (final MapEntry(key: tier, value: count) in _expectedPerTier.entries) {
      final actual = entries.where((e) => e.tier == tier).length;
      if (actual != count) {
        throw CatalogError('Tier $tier has $actual clubs, expected $count');
      }
    }
    for (final region in Region.values) {
      final inLeague = entries
          .where((e) => e.tier == 4 && e.region == region)
          .length;
      final inPool = entries
          .where((e) => e.tier == ClubEntry.poolTier && e.region == region)
          .length;
      if (inLeague != 18 || inPool != 12) {
        throw CatalogError(
          'Region ${region.id} has $inLeague league and $inPool pool clubs, '
          'expected 18 and 12',
        );
      }
    }
    return entries;
  }

  /// The club objects with their league for the start of the game.
  /// Pool clubs get no league.
  Result<List<Club>, CatalogError> clubs(Rules rules) {
    LeagueId? leagueFor(ClubEntry e) {
      if (e.isPool) return null;
      final matches = rules.leagues.where(
        (l) => l.level == e.tier && (e.tier < 4 || l.region == e.region),
      );
      return matches.isEmpty ? null : LeagueId(matches.first.id);
    }

    final result = <Club>[];
    for (final e in entries) {
      final league = leagueFor(e);
      if (league == null && !e.isPool) {
        return Err(CatalogError('No league for ${e.name}'));
      }
      result.add(
        Club(
          id: e.id,
          name: e.name,
          shortName: e.name,
          place: e.place,
          region: e.region,
          leagueId: league,
        ),
      );
    }
    return Ok(result);
  }

  /// Region of every club, as needed by the pyramid for clubs that are
  /// relegated from the third tier.
  Map<ClubId, Region> get regionOfClub => {
    for (final e in entries) e.id: e.region,
  };

  /// Pool clubs per region in file order (longest waiting first).
  Map<Region, List<ClubId>> get pools => {
    for (final r in Region.values)
      r: [
        for (final e in entries)
          if (e.isPool && e.region == r) e.id,
      ],
  };

  /// Splits semicolon separated text into rows. Handles a byte order mark,
  /// CRLF line ends and double-quoted fields.
  static List<List<String>> _rows(String text) {
    var input = text;
    if (input.startsWith('﻿')) input = input.substring(1);
    final rows = <List<String>>[];
    var row = <String>[];
    final field = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (inQuotes) {
        if (ch == '"') {
          if (i + 1 < input.length && input[i + 1] == '"') {
            field.write('"');
            i++;
          } else {
            inQuotes = false;
          }
        } else {
          field.write(ch);
        }
      } else if (ch == '"') {
        inQuotes = true;
      } else if (ch == ';') {
        row.add(field.toString());
        field.clear();
      } else if (ch == '\n' || ch == '\r') {
        if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        row.add(field.toString());
        field.clear();
        if (row.length > 1 || row.first.isNotEmpty) rows.add(row);
        row = <String>[];
      } else {
        field.write(ch);
      }
    }
    if (field.isNotEmpty || row.isNotEmpty) {
      row.add(field.toString());
      rows.add(row);
    }
    return rows;
  }
}
