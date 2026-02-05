import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/services_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/service_card.dart';
import '../utils/strings.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteServices = ref.watch(favoriteServicesProvider);
    final settings = ref.watch(settingsProvider);
    final lang = settings.locale.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.favorites(lang))),
      body: favoriteServices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(AppStrings.noFavorites(lang)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: favoriteServices.length,
              itemBuilder: (context, index) {
                return ServiceCard(service: favoriteServices[index]);
              },
            ),
    );
  }
}
