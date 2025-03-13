import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';
import '../services/auth_service.dart';
import 'create_blog_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class BlogDetailScreen extends StatefulWidget {
  final String blogId;
  final String title;

  const BlogDetailScreen({
    Key? key,
    required this.blogId,
    required this.title,
  }) : super(key: key);

  @override
  _BlogDetailScreenState createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final BlogService _blogService = BlogService();
  bool _isLoading = true;
  Blog? _blog;
  String? _error;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _loadBlog();
  }

  Future<void> _loadBlog() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      Blog blog = await _blogService.getBlogById(widget.blogId);
      
      // Update view count
      await _blogService.viewBlog(widget.blogId);
      
      if (mounted) {
        setState(() {
          _blog = blog;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _likeBlog() async {
    if (_liked) return;
    
    try {
      await _blogService.likeBlog(widget.blogId);
      setState(() {
        _liked = true;
        if (_blog != null) {
          _blog = Blog(
            id: _blog!.id,
            title: _blog!.title,
            content: _blog!.content,
            imageBase64: _blog!.imageBase64, // Changed from imageUrl
            userId: _blog!.userId,
            authorName: _blog!.authorName,
            authorPhotoUrl: _blog!.authorPhotoUrl,
            categories: _blog!.categories,
            featured: _blog!.featured,
            likes: _blog!.likes + 1,
            views: _blog!.views,
            createdAt: _blog!.createdAt,
            updatedAt: _blog!.updatedAt,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error liking blog: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteBlog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Blog'),
        content: Text('Are you sure you want to delete this blog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await _blogService.deleteBlog(widget.blogId);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blog deleted successfully')),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final bool isAuthor = _blog != null && authService.currentUser != null && 
                          _blog!.userId == authService.currentUser!.id;
    
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Error loading blog',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBlog,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: _blog!.imageBase64 != null && _blog!.imageBase64!.isNotEmpty ? 300 : 0, // Changed from imageUrl
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _blog!.imageBase64 != null && _blog!.imageBase64!.isNotEmpty
                            ? Image.memory(
                                base64Decode(_blog!.imageBase64!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      actions: [
                        if (isAuthor)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => CreateBlogScreen(
                                      blogId: widget.blogId,
                                      initialTitle: _blog!.title,
                                      initialContent: _blog!.content,
                                      initialImageBase64: _blog!.imageBase64, // Change parameter name to match CreateBlogScreen
                                    ),
                                  ),
                                ).then((_) => _loadBlog());
                              } else if (value == 'delete') {
                                _deleteBlog();
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _blog!.title,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                  backgroundImage: _blog!.authorPhotoUrl != null && _blog!.authorPhotoUrl!.isNotEmpty
                                      ? NetworkImage(_blog!.authorPhotoUrl!)
                                      : null,
                                  child: _blog!.authorPhotoUrl == null || _blog!.authorPhotoUrl!.isEmpty
                                      ? Text(
                                          _blog!.authorName.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        )
                                      : null,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _blog!.authorName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        timeago.format(_blog!.createdAt),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _liked ? Icons.favorite : Icons.favorite_border,
                                        color: _liked ? Colors.red : null,
                                      ),
                                      onPressed: _likeBlog,
                                    ),
                                    Text(
                                      _blog!.likes.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Icon(Icons.remove_red_eye, size: 20),
                                    SizedBox(width: 4),
                                    Text(
                                      _blog!.views.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            if (_blog!.categories.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _blog!.categories.map((category) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 24),
                            ],
                            Text(
                              _blog!.content,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 32),
                            Divider(),
                            SizedBox(height: 16),
                            Text(
                              'Share this article',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.facebook, color: Colors.blue),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.link, color: Colors.green),
                                  onPressed: () {},
                                ),
                                IconButton(
                                  icon: Icon(Icons.email, color: Colors.red),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _blog != null && !_isLoading
          ? FloatingActionButton(
              onPressed: _likeBlog,
              child: Icon(_liked ? Icons.favorite : Icons.favorite_border),
              backgroundColor: _liked ? Colors.red : Theme.of(context).primaryColor,
              tooltip: 'Like this blog',
            )
          : null,
    );
  }
}

