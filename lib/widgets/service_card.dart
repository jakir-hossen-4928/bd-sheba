import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/service_model.dart';
import '../providers/services_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/strings.dart';
import '../screens/service_details_screen.dart';

class ServiceCard extends ConsumerWidget {
  final Service service;
  const ServiceCard({super.key, required this.service});

  String _getSmartViews(String id) {
    // Generate a consistent pseudo-random number based on ID
    final seed = id.codeUnits.fold(0, (prev, curr) => prev + curr);
    final baseViews = (seed % 800) + 120; // 120 to 919 base views
    final totalViews = baseViews + service.clickCount * 3;

    if (totalViews > 1000) {
      return '${(totalViews / 1000).toStringAsFixed(1)}k';
    }
    return totalViews.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.locale.languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.3 : 0.5,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        color: isDark
            ? colorScheme.surface.withValues(alpha: 0.7)
            : colorScheme.surface,
        child: InkWell(
          onTap: () {
            // Navigate to Details Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ServiceDetailsScreen(service: service),
              ),
            );
          },
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isDark ? 10 : 0,
              sigmaY: isDark ? 10 : 0,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: service.imageUrl,
                                  fit: BoxFit.cover,
                                  fadeInDuration: Duration.zero,
                                  fadeOutDuration: Duration.zero,
                                  placeholder: (context, url) => Container(
                                    color: colorScheme.surfaceContainerHighest,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Icon(
                                    Icons.broken_image,
                                    color: colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                service.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            service.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Row: Views | Badge | Favorite
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_getSmartViews(service.id)} views',
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (service.type != 'free') ...[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: service.type == 'premium'
                                  ? Colors.amber
                                  : Colors.green,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              service.type == 'premium'
                                  ? AppStrings.premiumBadge(lang)
                                  : AppStrings.newBadge(lang),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      // Favorite Icon at bottom right
                      InkWell(
                        onTap: () {
                          ref
                              .read(servicesProvider.notifier)
                              .toggleFavorite(service.id);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            service.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: service.isFavorite
                                ? Colors.red
                                : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
