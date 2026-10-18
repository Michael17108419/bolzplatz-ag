import 'dart:convert';
import 'dart:math' as math;

import 'club.dart';
import 'ids.dart';

/// A town on the map (engine 2, step 10e4).
class Place {
  const Place({
    required this.latitude,
    required this.longitude,
    required this.population,
  });

  final double latitude;
  final double longitude;

  /// In thousands.
  final int population;
}

/// The ground of a club: its name, how many it holds, how good the grass
/// is (1 to 100).
class Stadium {
  const Stadium({
    required this.name,
    required this.capacity,
    required this.pitch,
  });

  final String name;
  final int capacity;
  final int pitch;
}

/// Places, stadiums and the big rivalries (engine 2, step 10e4).
class VenueData {
  VenueData({
    required Map<String, Place> places,
    required Map<ClubId, Stadium> stadiums,
    required Map<String, (int, String)> derbies,
  }) : places = Map.unmodifiable(places),
       stadiums = Map.unmodifiable(stadiums),
       _derbies = Map.unmodifiable(derbies);

  factory VenueData.fromJson(String text) {
    final m = jsonDecode(text) as Map<String, dynamic>;
    final places = <String, Place>{
      for (final e in (m['places'] as Map<String, dynamic>).entries)
        e.key: Place(
          latitude: ((e.value as Map<String, dynamic>)['lat'] as num)
              .toDouble(),
          longitude: ((e.value as Map<String, dynamic>)['lon'] as num)
              .toDouble(),
          population: (e.value as Map<String, dynamic>)['population'] as int,
        ),
    };
    final stadiums = <ClubId, Stadium>{
      for (final c in m['clubs'] as List<dynamic>)
        ClubId((c as Map<String, dynamic>)['club'] as int): Stadium(
          name: c['stadium'] as String,
          capacity: c['capacity'] as int,
          pitch: c['pitch'] as int,
        ),
    };
    final derbies = <String, (int, String)>{
      for (final d in m['derbies'] as List<dynamic>)
        _key(
          ClubId((d as Map<String, dynamic>)['a'] as int),
          ClubId(d['b'] as int),
        ): (
          d['level'] as int,
          d['name'] as String,
        ),
    };
    return VenueData(places: places, stadiums: stadiums, derbies: derbies);
  }

  final Map<String, Place> places;
  final Map<ClubId, Stadium> stadiums;
  final Map<String, (int, String)> _derbies;

  static String _key(ClubId a, ClubId b) => a.value < b.value
      ? '${a.value}:${b.value}'
      : '${b.value}:${a.value}';

  /// Distance in kilometres as the crow flies, 0 if a place is unknown.
  double distanceKm(String a, String b) {
    final p = places[a];
    final q = places[b];
    if (p == null || q == null || a == b) return 0;
    const r = 6371.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(q.latitude - p.latitude);
    final dLon = rad(q.longitude - p.longitude);
    final h =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(p.latitude)) *
            math.cos(rad(q.latitude)) *
            math.pow(math.sin(dLon / 2), 2);
    return 2 * r * math.asin(math.sqrt(h));
  }

  /// How hot a match is, 0 (none) to 3 (city derby or a great rivalry):
  /// the same place, under 50 km, the same region under 120 km, or a
  /// rivalry from the list, whichever is highest. A club and its second
  /// team are no derby.
  int derbyLevel(Club a, Club b) {
    if (a.id == b.id) return 0;
    if (a.parentClubId == b.id || b.parentClubId == a.id) return 0;
    final level = _derbies[_key(a.id, b.id)]?.$1 ?? 0;
    final km = distanceKm(a.place, b.place);
    final near = a.place == b.place
        ? 3
        : km < 50
        ? 2
        : (a.region == b.region && km < 120)
        ? 1
        : 0;
    return math.max(level, near);
  }

  /// The name of a great rivalry, null for a derby by distance only.
  String? derbyName(Club a, Club b) => _derbies[_key(a.id, b.id)]?.$2;
}
