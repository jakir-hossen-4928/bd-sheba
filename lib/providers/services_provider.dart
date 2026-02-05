import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/service_model.dart';
import '../data/data_provider.dart';

final servicesBoxProvider = Provider<Box<Service>>(
  (ref) => throw UnimplementedError(),
);

class ServicesNotifier extends Notifier<List<Service>> {
  late Box<Service> _box;

  @override
  List<Service> build() {
    _box = ref.watch(servicesBoxProvider);
    final rawServicesAsync = ref.watch(rawServicesProvider);

    return rawServicesAsync.maybeWhen(
      data: (rawServices) {
        if (rawServices.isEmpty) return [];
        final List<Service> services = [];
        for (var raw in rawServices) {
          final cached = _box.get(raw.id);
          if (cached != null) {
            services.add(
              raw.copyWith(
                clickCount: cached.clickCount,
                isFavorite: cached.isFavorite,
              ),
            );
          } else {
            services.add(raw);
          }
        }
        return services;
      },
      orElse: () => [],
    );
  }

  void incrementClick(String id) {
    final index = state.indexWhere((s) => s.id == id);
    if (index != -1) {
      final service = state[index];
      final updated = service.copyWith(clickCount: service.clickCount + 1);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
      _box.put(id, updated);
    }
  }

  void toggleFavorite(String id) {
    final index = state.indexWhere((s) => s.id == id);
    if (index != -1) {
      final service = state[index];
      final updated = service.copyWith(isFavorite: !service.isFavorite);
      state = [
        ...state.sublist(0, index),
        updated,
        ...state.sublist(index + 1),
      ];
      _box.put(id, updated);
    }
  }
}

final servicesProvider = NotifierProvider<ServicesNotifier, List<Service>>(
  ServicesNotifier.new,
);

final popularServicesProvider = Provider<List<Service>>((ref) {
  final services = ref.watch(servicesProvider);
  final sorted = List<Service>.from(services)
    ..sort((a, b) => b.clickCount.compareTo(a.clickCount));
  return sorted.take(10).toList();
});

final favoriteServicesProvider = Provider<List<Service>>((ref) {
  final services = ref.watch(servicesProvider);
  return services.where((s) => s.isFavorite).toList();
});
