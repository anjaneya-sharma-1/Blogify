import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool isLoading = false;
  String? error;

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = UserModel.fromMap(userData);
        notifyListeners();
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _saveUserToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', json.encode(user.toMap()));
  }

  Future<bool> signIn(String email, String password) async {
    setLoading(true);
    
    try {
      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));
      
      // Check if user exists in shared preferences
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final List<dynamic> users = json.decode(usersJson);
      
      final userIndex = users.indexWhere((user) => 
        user['email'] == email && user['password'] == password
      );
      
      if (userIndex >= 0) {
        _currentUser = UserModel.fromMap(users[userIndex]);
        await _saveUserToPrefs(_currentUser!);
        setLoading(false);
        notifyListeners();
        return true;
      } else {
        setLoading(false);
        error = 'Invalid email or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      setLoading(false);
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    setLoading(true);
    
    try {
      // Simulate network delay
      await Future.delayed(Duration(seconds: 1));
      
      // Check if user already exists
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      List<dynamic> users = json.decode(usersJson);
      
      final userExists = users.any((user) => user['email'] == email);
      
      if (userExists) {
        setLoading(false);
        error = 'User with this email already exists';
        notifyListeners();
        return false;
      }
      
      // Create new user
      final userId = DateTime.now().millisecondsSinceEpoch.toString();
      final newUser = UserModel(
        id: userId,
        name: name,
        email: email,
        password: password, // In a real app, you would hash this
        photoUrl: '',
        createdAt: DateTime.now(),
      );
      
      // Add to users list
      users.add(newUser.toMap());
      await prefs.setString('users', json.encode(users));
      
      // Set as current user
      _currentUser = newUser;
      await _saveUserToPrefs(newUser);
      
      setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      setLoading(false);
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    if (_currentUser == null) return;
    
    try {
      // Update current user
      _currentUser = UserModel(
        id: _currentUser!.id,
        name: name ?? _currentUser!.name,
        email: _currentUser!.email,
        password: _currentUser!.password,
        photoUrl: photoUrl ?? _currentUser!.photoUrl,
        createdAt: _currentUser!.createdAt,
      );
      
      // Update in shared preferences
      await _saveUserToPrefs(_currentUser!);
      
      // Update in users list
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      List<dynamic> users = json.decode(usersJson);
      
      final userIndex = users.indexWhere((user) => user['id'] == _currentUser!.id);
      
      if (userIndex >= 0) {
        users[userIndex] = _currentUser!.toMap();
        await prefs.setString('users', json.encode(users));
      }
      
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  void setLoading(bool value) {
    isLoading = value;
    error = null;
    notifyListeners();
  }
}

