import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/service_model.dart';

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final content = await rootBundle.loadString('assets/data/category.json');
  final List<dynamic> data = json.decode(content);
  return data.map((json) => Category.fromJson(json)).toList();
});

final rawServicesProvider = FutureProvider<List<Service>>((ref) async {
  final content = await rootBundle.loadString('assets/data/url-data.json');
  final List<dynamic> data = json.decode(content);
  return data.map((json) => Service.fromJson(json)).toList();
});
