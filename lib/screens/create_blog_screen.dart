import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/blog_service.dart';
import '../services/auth_service.dart';

class CreateBlogScreen extends StatefulWidget {
  final String? blogId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialImageUrl;

  const CreateBlogScreen({
    Key? key,
    this.blogId,
    this.initialTitle,
    this.initialContent,
    this.initialImageUrl,
  }) : super(key: key);

  @override
  _CreateBlogScreenState createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final BlogService _blogService = BlogService();

  File? _imageFile;
  String? _existingImageUrl;
  bool _isLoading = false;
  List<String> _categories = [];
  List<String> _selectedCategories = [];
  bool _isFeatured = false;

  @override
  void initState() {
    super.initState();
    
    // Set initial values if editing an existing blog
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    
    if (widget.initialContent != null) {
      _contentController.text = widget.initialContent!;
    }
    
    if (widget.initialImageUrl != null) {
      _existingImageUrl = widget.initialImageUrl;
    }
    
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _existingImageUrl = null; // Clear existing image if a new one is selected
      });
    }
  }

  Future<void> _saveBlog() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        if (user == null) {
          throw Exception('You must be logged in to create a blog');
        }
        
        if (widget.blogId != null) {
          // Update existing blog
          await _blogService.updateBlog(
            widget.blogId!,
            _titleController.text,
            _contentController.text,
            _imageFile,
            _selectedCategories,
            _isFeatured,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Blog updated successfully')),
            );
            Navigator.of(context).pop();
          }
        } else {
          // Create new blog
          String blogId = await _blogService.createBlog(
            _titleController.text,
            _contentController.text,
            _imageFile,
            user,
            _selectedCategories,
            _isFeatured,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Blog created successfully')),
            );
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blogId != null ? 'Edit Blog' : 'Create Blog'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'Enter blog title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            Text(
              'Categories',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategories.contains(category);
                return GestureDetector(
                  onTap: () => _toggleCategory(category),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            SwitchListTile(
              title: Text(
                'Featured Post',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text('Mark this blog as featured'),
              value: _isFeatured,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (value) {
                setState(() {
                  _isFeatured = value;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                hintText: 'Write your blog content here',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 10,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some content';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            Text(
              'Blog Image',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            if (_imageFile != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (_existingImageUrl != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_existingImageUrl!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No image selected',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.image),
              label: Text('Select Image'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveBlog,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(widget.blogId != null ? 'Update Blog' : 'Create Blog'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

