import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../providers/ads_provider.dart';
import '../providers/update_provider.dart';
import '../utils/strings.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'favorites_screen.dart';
import 'recent_screen.dart';

class MainWrapper extends ConsumerStatefulWidget {
  const MainWrapper({super.key});

  @override
  ConsumerState<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends ConsumerState<MainWrapper> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adsProvider.notifier).loadExitAd();
    });
  }

  Future<void> _handleExit() async {
    final ads = ref.read(adsProvider.notifier);
    await ads.showExitAd(() {
      SystemNavigator.pop();
    });
  }

  void _showUpdateDialog(BuildContext context, UpdateInfo updateInfo) {
    showDialog(
      context: context,
      barrierDismissible: !updateInfo.forceUpdate,
      builder: (context) => PopScope(
        canPop: !updateInfo.forceUpdate,
        child: UpdateDialog(updateInfo: updateInfo),
      ),
    );
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const CategoriesScreen(),
    const FavoritesScreen(),
    const RecentScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final lang = settings.locale.languageCode;
    final adState = ref.watch(adsProvider);

    // Listen for updates
    ref.listen(updateProvider, (previous, next) {
      if (next.hasUpdate && next.updateInfo != null) {
        _showUpdateDialog(context, next.updateInfo!);
      }
    });

    // Ensure ad is preloaded if missing
    if (adState.exitAd == null && !adState.isExitAdLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adsProvider.notifier).loadExitAd();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        _handleExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: IndexedStack(index: _currentIndex, children: _screens),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: AppStrings.home(lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.category_outlined),
                selectedIcon: const Icon(Icons.category),
                label: AppStrings.categories(lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.favorite_outline),
                selectedIcon: const Icon(Icons.favorite),
                label: AppStrings.favorites(lang),
              ),
              NavigationDestination(
                icon: const Icon(Icons.history_outlined),
                selectedIcon: const Icon(Icons.history),
                label: lang == 'bn' ? 'সাম্প্রতিক' : 'Recent',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UpdateDialog extends StatelessWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.system_update, color: colorScheme.primary),
          const SizedBox(width: 12),
          const Text('Update Available'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A new version (${updateInfo.latestVersionName}) is available. Please update to continue using the app with new features and improvements.',
            style: const TextStyle(fontSize: 14),
          ),
          if (updateInfo.releaseNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'What\'s New:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              updateInfo.releaseNotes,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!updateInfo.forceUpdate)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
        FilledButton(
          onPressed: () async {
            final uri = Uri.parse(updateInfo.updateUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
          child: const Text('Update Now'),
        ),
      ],
    );
  }
}
