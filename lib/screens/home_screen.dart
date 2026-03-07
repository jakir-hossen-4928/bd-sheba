import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fuzzy;
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../models/service_model.dart';
import '../providers/services_provider.dart';
import '../providers/settings_provider.dart';
import '../data/data_provider.dart';
import '../widgets/service_card.dart';
import '../utils/strings.dart';
import '../utils/ad_helper.dart';
import 'settings_screen.dart';

import '../providers/ads_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategorySlug;

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    // Preload exit ad
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adsProvider.notifier).loadExitAd();
    });
  }

  void _loadBannerAd() async {
    if (!await AdHelper.hasConnection()) return;
    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size:
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQueryData.fromView(View.of(context)).size.width.toInt(),
          ) ??
          AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  List<Service> _getFilteredServices(List<Service> allServices) {
    // ... (rest of filtering logic remains same)
    List<Service> baseServices = allServices;

    if (_selectedCategorySlug != null) {
      baseServices = baseServices
          .where((s) => s.categorySlug == _selectedCategorySlug)
          .toList();
    }

    if (_searchQuery.isEmpty) return baseServices;

    final List<MapEntry<Service, int>> scoredServices = [];

    for (final service in baseServices) {
      final titleScore = fuzzy.partialRatio(
        _searchQuery.toLowerCase(),
        service.title.toLowerCase(),
      );
      final descScore = fuzzy.partialRatio(
        _searchQuery.toLowerCase(),
        service.description.toLowerCase(),
      );
      final maxScore = [
        titleScore,
        descScore,
      ].reduce((curr, next) => curr > next ? curr : next);

      if (maxScore > 60) {
        scoredServices.add(MapEntry(service, maxScore));
      }
    }

    scoredServices.sort((a, b) => b.value.compareTo(a.value));
    return scoredServices.map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.locale.languageCode;
    final allServices = ref.watch(servicesProvider);
    final popularServices = ref.watch(popularServicesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final filteredServices = _getFilteredServices(allServices);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/app-logo.png', height: 24, width: 24),
                      const SizedBox(width: 8),
                      Text(
                        'BD Sheba',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 16),
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: InputDecoration(
                          hintText: AppStrings.searchPlaceholder(lang),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor:
                              Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.7)
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withValues(alpha: 0.5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    categoriesAsync.when(
                      data: (categories) => SizedBox(
                        height: 50,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ChoiceChip(
                                label: Text(lang == 'bn' ? 'সব' : 'All'),
                                selected: _selectedCategorySlug == null,
                                onSelected: (selected) {
                                  setState(() => _selectedCategorySlug = null);
                                },
                              );
                            }
                            final cat = categories[index - 1];
                            return ChoiceChip(
                              label: Text(cat.name),
                              selected: _selectedCategorySlug == cat.slug,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategorySlug = selected
                                      ? cat.slug
                                      : null;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (_searchQuery.isEmpty &&
                  _selectedCategorySlug == null &&
                  popularServices.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      AppStrings.popularServices(lang),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: popularServices.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 250,
                          child: AnimatedOpacity(
                            opacity: 1.0,
                            duration: const Duration(milliseconds: 300),
                            child: ServiceCard(service: popularServices[index]),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    _searchQuery.isEmpty
                        ? AppStrings.allServices(lang)
                        : (lang == 'bn' ? 'ফলাফল' : 'Results'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index >= filteredServices.length) return null;
                    return ServiceCard(service: filteredServices[index]);
                  }, childCount: filteredServices.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: AdWidget(ad: _bannerAd!),
              ),
            ),
        ],
      ),
    );
  }
}
