import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../providers/services_provider.dart';
import '../widgets/service_card.dart';

class CategoryDetailScreen extends ConsumerWidget {
  final Category category;
  const CategoryDetailScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allServices = ref.watch(servicesProvider);
    final categoryServices = allServices
        .where((s) => s.categorySlug == category.slug)
        .toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: true,
              title: Text(category.name),
              centerTitle: true,
            ),
            if (categoryServices.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Text('No services found in this category'),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return ServiceCard(service: categoryServices[index]);
                  }, childCount: categoryServices.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
