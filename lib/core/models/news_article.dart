class NewsArticle {
  final String title;
  final String description;
  final String link;
  final String? imageUrl;
  final String pubDate;
  final String source;

  NewsArticle({
    required this.title,
    required this.description,
    required this.link,
    this.imageUrl,
    required this.pubDate,
    required this.source,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title']?.toString() ?? 'No Title',
      description:
          json['description']?.toString() ?? 'No description available.',
      link: json['link']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(), // underscore
      pubDate: json['pubDate']?.toString() ?? '', // camelCase
      source: json['source_id']?.toString().toUpperCase() ?? 'NEWS',
    );
  }
}
