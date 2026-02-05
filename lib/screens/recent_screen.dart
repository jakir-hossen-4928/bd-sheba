import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../providers/services_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/service_card.dart';

class RecentScreen extends ConsumerWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyIds = ref.watch(historyProvider);
    final allServices = ref.watch(servicesProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.locale.languageCode;

    // Map history IDs to Service objects in reverse order (most recent first)
    // Only include services that actually exist in the provider
    final recentServices = historyIds.reversed
        .map((id) {
          return allServices.where((s) => s.id == id).firstOrNull;
        })
        .whereType<Service>()
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(lang == 'bn' ? 'সাম্প্রতিক' : 'Recent')),
      body: recentServices.isEmpty
          ? const Center(child: Text('No recently opened services'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: recentServices.length,
              itemBuilder: (context, index) {
                return ServiceCard(service: recentServices[index]);
              },
            ),
    );
  }
}
