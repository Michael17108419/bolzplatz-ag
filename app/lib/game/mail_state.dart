import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The ids of the mails that were opened. Shared by the post screen and the
/// badge on the desk.
class MailReadNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  /// Takes over the mails read in a saved game.
  void restore(Set<String> read) => state = Set.unmodifiable(read);

  void markRead(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
  }

  void markAllRead(Iterable<String> ids) => state = {...state, ...ids};
}

final mailReadProvider = NotifierProvider<MailReadNotifier, Set<String>>(
  MailReadNotifier.new,
);
