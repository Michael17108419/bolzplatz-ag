import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_core/game_core.dart';

/// The career the player has started: who manages which club.
class Career {
  const Career({required this.managerName, required this.clubId});

  final String managerName;
  final ClubId clubId;
}

class CareerNotifier extends Notifier<Career?> {
  @override
  Career? build() => null;

  void start({required String managerName, required ClubId clubId}) {
    state = Career(managerName: managerName.trim(), clubId: clubId);
  }
}

/// Null until a career is started.
final careerProvider = NotifierProvider<CareerNotifier, Career?>(
  CareerNotifier.new,
);
