import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// The career the player has started: the manager and the accepted offer.
class Career {
  const Career({
    required this.trainer,
    required this.offer,
    required this.seed,
  });

  final Trainer trainer;
  final JobOffer offer;

  /// Seed of the career (the one of the screens that led to it).
  final int seed;

  ClubId get clubId => offer.club.id;
}

class CareerNotifier extends Notifier<Career?> {
  @override
  Career? build() => null;

  void start({
    required Trainer trainer,
    required JobOffer offer,
    required int seed,
  }) {
    state = Career(trainer: trainer, offer: offer, seed: seed);
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
