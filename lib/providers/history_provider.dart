import 'dart:convert';
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
    final historyList = _box.get('history_list');
    if (historyList != null) {
      return List<String>.from(jsonDecode(historyList));
    }
    return [];
  }

  void addToHistory(String id) {
    final newState = List<String>.from(state);
    newState.remove(id);
    newState.add(id);

    if (newState.length > 20) {
      newState.removeAt(0);
    }

    state = newState;
    _box.put('history_list', jsonEncode(newState));
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<String>>(
  HistoryNotifier.new,
);
