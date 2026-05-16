import '../../config/app_config.dart';

class SliderItem {
  const SliderItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  final String id;
  final String title;
  final String description;
  final String? imageUrl;

  factory SliderItem.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    String? url;
    if (image is String && image.isNotEmpty) {
      url = AppConfig.normalizeMediaUrl(image);
    }
    return SliderItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      imageUrl: url,
    );
  }
}
