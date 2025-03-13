import 'package:cloud_firestore/cloud_firestore.dart';

class Blog {
  final String id;
  final String title;
  final String content;
  final String? imageBase64;
  final String userId;
  final String authorName;
  final String? authorPhotoUrl;
  final List<String> categories;
  final bool featured;
  final int likes;
  final int views;
  final DateTime createdAt;
  final DateTime updatedAt;

  Blog({
    required this.id,
    required this.title,
    required this.content,
    this.imageBase64,
    required this.userId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.categories,
    required this.featured,
    required this.likes,
    required this.views,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Blog.fromMap(String id, Map<String, dynamic> data) {
    // Support migration from imageUrl to imageBase64
    String? imageData = data['imageBase64'];
    if (imageData == null && data['imageUrl'] != null) {
      // For old data using imageUrl - this will help during transition
      imageData = data['imageUrl'];
      // Note: These URLs won't display correctly since we're expecting base64 now
      // You might need a migration strategy to convert all imageUrl to imageBase64
    }
    
    return Blog(
      id: id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      imageBase64: imageData,
      userId: data['userId'] ?? '',
      authorName: data['authorName'] ?? 'Anonymous',
      authorPhotoUrl: data['authorPhotoUrl'],
      categories: List<String>.from(data['categories'] ?? []),
      featured: data['featured'] ?? false,
      likes: data['likes'] ?? 0,
      views: data['views'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'imageBase64': imageBase64,
      'userId': userId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'categories': categories,
      'featured': featured,
      'likes': likes,
      'views': views,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

