import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/service_model.dart';
import '../providers/services_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
import '../utils/strings.dart';
import '../utils/ad_helper.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'web_view_screen.dart';

class ServiceDetailsScreen extends ConsumerStatefulWidget {
  final Service service;

  const ServiceDetailsScreen({super.key, required this.service});

  @override
  ConsumerState<ServiceDetailsScreen> createState() =>
      _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends ConsumerState<ServiceDetailsScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.mediumRectangle,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  String _getSmartViews(String id, int clickCount) {
    // Reusing the smart view logic for consistency
    final seed = id.codeUnits.fold(0, (prev, curr) => prev + curr);
    final baseViews = (seed % 800) + 120;
    final totalViews = baseViews + clickCount * 3;

    if (totalViews > 1000) {
      return '${(totalViews / 1000).toStringAsFixed(1)}k';
    }
    return totalViews.toString();
  }

  Future<void> _launchService(BuildContext context) async {
    ref.read(servicesProvider.notifier).incrementClick(widget.service.id);
    ref.read(historyProvider.notifier).addToHistory(widget.service.id);

    final useInAppBrowser = ref.read(settingsProvider).useInAppBrowser;

    if (useInAppBrowser) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(service: widget.service),
        ),
      );
    } else {
      final uri = Uri.parse(widget.service.url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not launch URL')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.locale.languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    // Listen to changes for this specific service to update the UI (e.g. favorite status)
    // We might need to find the specific service from the provider list to get real-time updates
    // simpler approach: just read 'isFavorite' from the passed object,
    // BUT since we toggle favorite status, we should ideally watch the service provider for this ID.
    // For now, we'll assume the passed service object might be stale if we toggle and don't pop.
    // However, usually we can just rely on the parent provider updates rebuilding this if we passed the ID,
    // but here we pass the object.
    // Improved: Watch the list and find the updated service object.
    final serviceList = ref.watch(servicesProvider);
    final updatedService = serviceList.firstWhere(
      (s) => s.id == widget.service.id,
      orElse: () => widget.service,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: updatedService.imageUrl,
                fit: BoxFit.cover,
                fadeInDuration: Duration.zero,
                fadeOutDuration: Duration.zero,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image,
                    size: 64,
                    color: colorScheme.error,
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        updatedService.title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref
                            .read(servicesProvider.notifier)
                            .toggleFavorite(updatedService.id);
                      },
                      icon: Icon(
                        updatedService.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: updatedService.isFavorite
                            ? Colors.red
                            : colorScheme.onSurface,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility,
                            size: 16,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_getSmartViews(updatedService.id, updatedService.clickCount)} Views',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: updatedService.type == 'premium'
                            ? Colors.amber
                            : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        updatedService.type == 'premium'
                            ? AppStrings.premiumBadge(lang)
                            : AppStrings.newBadge(lang),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'About Service',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  updatedService.description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 32),
                if (_isAdLoaded && _bannerAd != null)
                  Center(
                    child: SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: FilledButton.icon(
            onPressed: () => _launchService(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Service'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
