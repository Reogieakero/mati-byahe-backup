import 'package:flutter/material.dart';
import '../../core/constant/app_colors.dart';
import '../../core/models/news_article.dart';
import '../../core/services/news_api_service.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final NewsApiService _apiService = NewsApiService();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<NewsArticle>>(
              future: _apiService.fetchNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    _query.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.darkNavy),
                  );
                }

                final articles = (snapshot.data ?? []).where((a) {
                  final searchLower = _query.toLowerCase();
                  return a.title.toLowerCase().contains(searchLower) ||
                      a.description.toLowerCase().contains(searchLower);
                }).toList();

                return RefreshIndicator(
                  color: AppColors.darkNavy,
                  onRefresh: () async => setState(() {}),
                  child: articles.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 10,
                          ),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: articles.length,
                          itemBuilder: (context, index) =>
                              _newsCard(articles[index]),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, bottom: 20, left: 10, right: 20),
      decoration: const BoxDecoration(
        color: AppColors.darkNavy,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new, // Professional IOS-style back icon
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Text(
                "World News",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 48,
            ), // Align with the text above
            child: const Text(
              "World and Local Updates",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value.trim()),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: "Search news...",
          prefixIcon: const Icon(
            Icons.public,
            size: 20,
            color: AppColors.darkNavy,
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _newsCard(NewsArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  article.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(),
                ),
              ),
            ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkNavy.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  article.source.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.darkNavy,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                article.pubDate.split(' ')[0],
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            article.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.darkNavy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            article.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              height: 1.4,
              color: AppColors.textGrey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No news available."));
  }
}
