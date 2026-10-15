import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The ids of the mails that were opened. Shared by the post screen and the
/// badge on the desk.
class MailReadNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void markRead(String id) {
    if (state.contains(id)) return;
    state = {...state, id};
  }
}

final mailReadProvider = NotifierProvider<MailReadNotifier, Set<String>>(
  MailReadNotifier.new,
);
