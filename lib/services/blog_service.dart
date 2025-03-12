import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/blog.dart';
import '../models/user.dart';

class BlogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
    List<String> categories,
    bool featured,
  ) async {
    try {
      String? imageUrl;
      
      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile, user.id);
      }
      
      // Create blog document
      DocumentReference docRef = await _firestore.collection('blogs').add({
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'userId': user.id,
        'authorName': user.name,
        'authorPhotoUrl': user.photoUrl,
        'categories': categories,
        'featured': featured,
        'likes': 0,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create blog: $e');
    }
  }

  // Update blog
  Future<void> updateBlog(
    String blogId, 
    String title, 
    String content, 
    File? imageFile, 
    List<String> categories,
    bool featured,
  ) async {
    try {
      Map<String, dynamic> data = {
        'title': title,
        'content': content,
        'categories': categories,
        'featured': featured,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Upload new image if provided
      if (imageFile != null) {
        String imageUrl = await _uploadImage(imageFile, blogId);
        data['imageUrl'] = imageUrl;
      }
      
      await _firestore.collection('blogs').doc(blogId).update(data);
    } catch (e) {
      throw Exception('Failed to update blog: $e');
    }
  }

  // Delete blog
  Future<void> deleteBlog(String blogId) async {
    try {
      // Get the blog to check if it has an image
      Blog blog = await getBlogById(blogId);
      
      // Delete the image if it exists
      if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty) {
        await _deleteImage(blog.imageUrl!);
      }
      
      // Delete the blog document
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

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile, String userId) async {
    try {
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_$userId';
      Reference storageRef = _storage.ref().child('blog_images/$fileName');
      
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      return await taskSnapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Firebase Storage
  Future<void> _deleteImage(String imageUrl) async {
    try {
      Reference storageRef = _storage.refFromURL(imageUrl);
      await storageRef.delete();
    } catch (e) {
      print('Failed to delete image: $e');
      // Continue with blog deletion even if image deletion fails
    }
  }
}

