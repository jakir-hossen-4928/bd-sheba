import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final historyBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError(),
);

class HistoryNotifier extends Notifier<List<String>> {
  late Box<String> _box;

  @override
  List<String> build() {
    _box = ref.watch(historyBoxProvider);
    final initial = List<String>.from(_box.values);
    if (initial.length > 20) {
      return initial.sublist(initial.length - 20);
    }
    return initial;
  }

  void addToHistory(String id) {
    // If state was trimmed in build, use it.
    // Logic: remove if exists, add to end (most recent).
    final newState = List<String>.from(state);
    newState.remove(id);
    newState.add(id);

    if (newState.length > 20) {
      newState.removeAt(0);
    }

    state = newState;
    // Update box (simple implementation specific to this app logic)
    // Note: box logic in original code was clear+addAll, keeping it.
    _box.clear();
    _box.addAll(newState);
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<String>>(
  HistoryNotifier.new,
);
