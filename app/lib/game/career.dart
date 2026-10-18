import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// The career the player has started: the manager and the accepted offer.
class Career {
  const Career({
    required this.trainer,
    required this.offer,
    required this.seed,
    this.wishClubId,
    this.currentLeague,
    this.currentGoal,
  });

  final Trainer trainer;
  final JobOffer offer;

  /// The wish club of the career start; together with the seed it brings
  /// back the same job offers when a saved game is loaded.
  final ClubId? wishClubId;

  /// Seed of the career (the one of the screens that led to it).
  final int seed;

  ClubId get clubId => offer.club.id;

  /// The league of the club in the running season (the one of the offer
  /// until the club moves up or down).
  final League? currentLeague;

  /// The goal of the president for the running season.
  final SeasonGoal? currentGoal;

  League get league => currentLeague ?? offer.league;
  SeasonGoal get goal => currentGoal ?? offer.goal;

  /// The same career in a later season, with the manager as he grew.
  Career inSeason({
    required League league,
    required SeasonGoal goal,
    Trainer? trainer,
  }) => Career(
    trainer: trainer ?? this.trainer,
    offer: offer,
    seed: seed,
    wishClubId: wishClubId,
    currentLeague: league,
    currentGoal: goal,
  );
}

class CareerNotifier extends Notifier<Career?> {
  @override
  Career? build() => null;

  void start({
    required Trainer trainer,
    required JobOffer offer,
    required int seed,
    ClubId? wishClubId,
  }) {
    state = Career(
      trainer: trainer,
      offer: offer,
      seed: seed,
      wishClubId: wishClubId,
    );
  }

  /// The club plays on in a new season, maybe in another league.
  void newSeason({
    required League league,
    required SeasonGoal goal,
    Trainer? trainer,
  }) {
    final career = state;
    if (career == null) return;
    state = career.inSeason(league: league, goal: goal, trainer: trainer);
  }
}

/// Null until a career is started.
final careerProvider = NotifierProvider<CareerNotifier, Career?>(
  CareerNotifier.new,
);

/// What the player has entered on the way to the job offers.
class CareerDraft {
  const CareerDraft({
    required this.seed,
    this.name = '',
    this.appearance = const TrainerAppearance(),
    this.backstoryId,
    this.wishClubId,
  });

  /// Seed of this career: decides the start values and all job offers, so
  /// going back and forth in the screens shows the same offers.
  final int seed;
  final String name;
  final TrainerAppearance appearance;
  final String? backstoryId;
  final ClubId? wishClubId;

  CareerDraft copyWith({
    String? name,
    TrainerAppearance? appearance,
    String? backstoryId,
    ClubId? wishClubId,
    bool clearWish = false,
  }) => CareerDraft(
    seed: seed,
    name: name ?? this.name,
    appearance: appearance ?? this.appearance,
    backstoryId: backstoryId ?? this.backstoryId,
    wishClubId: clearWish ? null : (wishClubId ?? this.wishClubId),
  );
}

class CareerDraftNotifier extends Notifier<CareerDraft> {
  @override
  CareerDraft build() => CareerDraft(seed: Random().nextInt(1 << 30));

  /// Takes over a saved draft (loading a saved game).
  void restore(CareerDraft draft) => state = draft;

  void setName(String name) => state = state.copyWith(name: name);

  void setAppearance(TrainerAppearance appearance) =>
      state = state.copyWith(appearance: appearance);

  void setBackstory(String id) => state = state.copyWith(backstoryId: id);

  void setWish(ClubId? club) => state = club == null
      ? state.copyWith(clearWish: true)
      : state.copyWith(wishClubId: club);
}

final careerDraftProvider = NotifierProvider<CareerDraftNotifier, CareerDraft>(
  CareerDraftNotifier.new,
);
