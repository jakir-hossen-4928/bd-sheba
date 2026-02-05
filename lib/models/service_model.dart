import 'package:hive/hive.dart';

part 'service_model.g.dart';

@HiveType(typeId: 0)
class Service extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String url;
  @HiveField(3)
  final String categorySlug;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final String type; // free, premium, new
  @HiveField(6)
  final String description;
  @HiveField(7)
  int clickCount;
  @HiveField(8)
  bool isFavorite;

  Service({
    required this.id,
    required this.title,
    required this.url,
    required this.categorySlug,
    required this.imageUrl,
    required this.type,
    required this.description,
    this.clickCount = 0,
    this.isFavorite = false,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['url'] ?? '',
      categorySlug: json['category'] ?? '',
      imageUrl: json['imageurl'] ?? '',
      type: json['type'] ?? 'free',
      description: json['description'] ?? '',
      clickCount: json['click_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'category': categorySlug,
      'imageurl': imageUrl,
      'type': type,
      'description': description,
      'click_count': clickCount,
    };
  }

  Service copyWith({int? clickCount, bool? isFavorite}) {
    return Service(
      id: id,
      title: title,
      url: url,
      categorySlug: categorySlug,
      imageUrl: imageUrl,
      type: type,
      description: description,
      clickCount: clickCount ?? this.clickCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
