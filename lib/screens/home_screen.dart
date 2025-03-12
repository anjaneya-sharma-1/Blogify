import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/blog_service.dart';
import '../models/blog.dart';
import '../widgets/featured_blog_card.dart';
import '../widgets/blog_card.dart';
import '../widgets/category_chip.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final BlogService _blogService = BlogService();
  late TabController _tabController;
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categories = await _blogService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category == _selectedCategory ? null : category;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              snap: true,
              title: Text(
                'Blogify',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    // Search functionality
                  },
                ),
                IconButton(
                  icon: CircleAvatar(
                    radius: 14,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/profile');
                  },
                ),
                SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor,
                        Color(0xFF8A80FF),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 16, bottom: 50),
                      child: Text(
                        'Discover Stories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'For You'),
                  Tab(text: 'Following'),
                ],
              ),
            ),
          ];
        },
        body: Column(
          children: [
            if (!_isLoading) ...[
              SizedBox(height: 16),
              Container(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: _categories[index],
                        isSelected: _selectedCategory == _categories[index],
                        onTap: () => _selectCategory(_categories[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // For You Tab
                  RefreshIndicator(
                    onRefresh: () async {
                      // Refresh blogs
                      setState(() {});
                    },
                    child: CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Featured',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // View all featured
                                  },
                                  child: Text('View All'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Container(
                            height: 240,
                            child: StreamBuilder<List<Blog>>(
                              stream: _blogService.getFeaturedBlogs(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return Center(child: CircularProgressIndicator());
                                }
                                
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Text('No featured blogs yet'),
                                  );
                                }
                                
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: snapshot.data!.length,
                                  itemBuilder: (context, index) {
                                    Blog blog = snapshot.data![index];
                                    return FeaturedBlogCard(
                                      blog: blog,
                                      onTap: () {
                                        Navigator.of(context).pushNamed(
                                          '/blog-detail',
                                          arguments: {
                                            'blogId': blog.id,
                                            'title': blog.title,
                                          },
                                        );
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                            child: Text(
                              _selectedCategory != null ? _selectedCategory! : 'Recent Posts',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        StreamBuilder<List<Blog>>(
                          stream: _selectedCategory != null
                              ? _blogService.getBlogsByCategory(_selectedCategory!)
                              : _blogService.getBlogs(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return SliverFillRemaining(
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.article_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 16),
                                      Text(
                                        'No blogs found',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            
                            return SliverPadding(
                              padding: EdgeInsets.all(16),
                              sliver: SliverAnimatedList(
                                initialItemCount: snapshot.data!.length,
                                itemBuilder: (context, index, animation) {
                                  Blog blog = snapshot.data![index];
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: Duration(milliseconds: 375),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: BlogCard(
                                          blog: blog,
                                          isAuthor: blog.userId == user?.id,
                                          onTap: () {
                                            Navigator.of(context).pushNamed(
                                              '/blog-detail',
                                              arguments: {
                                                'blogId': blog.id,
                                                'title': blog.title,
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Following Tab
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Follow authors to see their posts here',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            _tabController.animateTo(0);
                          },
                          child: Text('Discover Authors'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-blog');
        },
        child: Icon(Icons.add),
        tooltip: 'Create Blog',
      ),
    );
  }
}

