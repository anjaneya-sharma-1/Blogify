import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/blog.dart';
import '../models/user.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all blogs
  Stream<List<Blog>> getBlogs() {
    return _firestore
        .collection('blogs')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Blog.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get featured blogs
  Stream<List<Blog>> getFeaturedBlogs() {
    return _firestore
        .collection('blogs')
        .where('featured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Blog.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get blogs by category
  Stream<List<Blog>> getBlogsByCategory(String category) {
    return _firestore
        .collection('blogs')
        .where('categories', arrayContains: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Blog.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get user blogs
  Stream<List<Blog>> getUserBlogs(String userId) {
    return _firestore
        .collection('blogs')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Blog.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get blog by id
  Future<Blog> getBlogById(String blogId) async {
    DocumentSnapshot doc = await _firestore.collection('blogs').doc(blogId).get();
    return Blog.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Create blog
  Future<String> createBlog(
    String title, 
    String content, 
    File? imageFile, 
    UserModel user, 
    [List<String>? categories,
    bool? featured]
  ) async {
    try {
      String? imageBase64;
      
      // Convert image to base64 if provided
      if (imageFile != null) {
        imageBase64 = await _convertImageToBase64(imageFile);
      }
      
      // Create blog document with default values if parameters are missing
      DocumentReference docRef = await _firestore.collection('blogs').add({
        'title': title,
        'content': content,
        'imageBase64': imageBase64, // Store base64 string instead of URL
        'userId': user.id,
        'authorName': user.name,
        'authorPhotoUrl': user.photoUrl,
        'categories': categories ?? ['Uncategorized'],
        'featured': featured ?? false,
        'likes': 0,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      print('Failed to create blog: $e');
      throw Exception('Failed to create blog: $e');
    }
  }

  // Update blog
  Future<void> updateBlog(
    String blogId, 
    String title, 
    String content, 
    File? imageFile, 
    [List<String>? categories,
    bool? featured]
  ) async {
    try {
      Map<String, dynamic> data = {
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Only update categories if provided
      if (categories != null) {
        data['categories'] = categories;
      }
      
      // Only update featured if provided
      if (featured != null) {
        data['featured'] = featured;
      }
      
      // Convert and add new image if provided
      if (imageFile != null) {
        String imageBase64 = await _convertImageToBase64(imageFile);
        data['imageBase64'] = imageBase64;
      }
      
      await _firestore.collection('blogs').doc(blogId).update(data);
    } catch (e) {
      print('Failed to update blog: $e');
      throw Exception('Failed to update blog: $e');
    }
  }

  // Delete blog
  Future<void> deleteBlog(String blogId) async {
    try {
      // No need to delete images separately since they're stored in the document
      await _firestore.collection('blogs').doc(blogId).delete();
    } catch (e) {
      throw Exception('Failed to delete blog: $e');
    }
  }

  // Like blog
  Future<void> likeBlog(String blogId) async {
    try {
      await _firestore.collection('blogs').doc(blogId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      throw Exception('Failed to like blog: $e');
    }
  }

  // View blog
  Future<void> viewBlog(String blogId) async {
    try {
      await _firestore.collection('blogs').doc(blogId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to update view count: $e');
      // Continue even if view count update fails
    }
  }

  // Get all categories
  Future<List<String>> getCategories() async {
    try {
      DocumentSnapshot doc = await _firestore.collection('metadata').doc('categories').get();
      
      if (doc.exists) {
        return List<String>.from(doc.get('list') ?? []);
      } else {
        // Create default categories if they don't exist
        List<String> defaultCategories = [
          'Technology', 
          'Travel', 
          'Food', 
          'Lifestyle', 
          'Health', 
          'Business'
        ];
        
        await _firestore.collection('metadata').doc('categories').set({
          'list': defaultCategories,
        });
        
        return defaultCategories;
      }
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Convert image file to base64 string
  Future<String> _convertImageToBase64(File imageFile) async {
    try {
      // Check if file exists and is accessible
      if (!imageFile.existsSync()) {
        throw Exception('Image file does not exist or is not accessible');
      }

      print('Converting image to base64: ${imageFile.path}');
      final fileSize = await imageFile.length();
      print('File size: $fileSize bytes');
      
      // Read file as bytes
      List<int> imageBytes = await imageFile.readAsBytes();
      
      // Compress image if too large (optional)
      if (fileSize > 500000) { // If over 500KB, compress it
        print('Image too large, compressing...');
        // You may want to add image compression here using a package like flutter_image_compress
        // For now, we'll just warn about it
      }
      
      // Convert bytes to base64
      String base64String = base64Encode(imageBytes);
      print('Conversion successful. Base64 size: ${base64String.length} characters');
      
      return base64String;
    } catch (e) {
      print('Error during image conversion: $e');
      throw Exception('Failed to convert image: $e');
    }
  }
}

