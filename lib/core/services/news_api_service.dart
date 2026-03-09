import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../models/news_article.dart';

class NewsApiService {
  // Pulling from your .env based on your main.dart setup
  final String _apiKey = dotenv.env['NEWSDATA_API_KEY'] ?? '';

  Future<List<NewsArticle>> fetchNews() async {
    try {
      // Using the exact URL format you used in Postman
      final url =
          'https://newsdata.io/api/1/latest?apikey=$_apiKey&q=philippines&language=en';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List? results = data['results'];

        if (results == null || results.isEmpty) {
          debugPrint("NewsData: Success but 0 results found.");
          return [];
        }

        return results.map((json) => NewsArticle.fromJson(json)).toList();
      } else {
        debugPrint("NewsData Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("NewsData Catch: $e");
      return [];
    }
  }
}
