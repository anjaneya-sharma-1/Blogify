# Blogify

A feature-rich blog application built with Flutter that allows users to create, read, update, and delete blog posts. The app includes features like authentication, image upload, categorization, and social interactions such as likes and view counting.

## Features

- **User Authentication**: Secure login and registration system
- **Blog Management**: Create, edit, and delete blog posts
- **Rich Content**: Support for text content and images in blog posts
- **Categories**: Tag blogs with categories for better organization
- **Social Features**: Like and view count tracking
- **User Profiles**: Author information and profile pictures
- **Responsive Design**: Works across different screen sizes and orientations

## Tech Stack

### Frontend
- **Flutter**: Cross-platform UI toolkit for building natively compiled applications
- **Dart**: Programming language optimized for building mobile, desktop, server, and web applications
- **Provider**: State management solution for Flutter applications

### Backend Services
- **Firebase Authentication**: For user authentication and management
- **Cloud Firestore**: NoSQL database for storing blog data


### Packages
- **provider**: For state management across the application
- **cloud_firestore**: Firebase Firestore plugin for Flutter
- **timeago**: For formatting dates in a user-friendly format
- **image_picker**: For selecting images from the device gallery or camera
- **shared_preferences**: For local data persistence

## Getting Started

### Prerequisites
- Flutter SDK (2.0.0 or higher)
- Dart SDK (2.12.0 or higher)
- Android Studio / VS Code with Flutter plugins
- Firebase account

### Installation

1. **Clone the repository**
   ```
   git clone https://github.com/yourusername/blog_app.git
   cd blog_app
   ```

2. **Install dependencies**
   ```
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication, Firestore, and Storage services
   - Download and add the `google-services.json` file to the Android app directory
   - Download and add the `GoogleService-Info.plist` file to the iOS app directory

4. **Run the app**
   ```
   flutter run
   ```

## Project Structure

```
blog_app/
├── lib/
│   ├── models/         # Data models
│   ├── screens/        # UI screens
│   ├── services/       # Business logic and API services
│   ├── widgets/        # Reusable UI components
│   ├── utils/          # Utility functions and constants
│   └── main.dart       # App entry point
├── assets/             # Static assets (images, fonts)
├── test/               # Test files
└── pubspec.yaml        # Project configuration
```

## Usage

### Authentication
- Users can create an account or log in with existing credentials
- Authentication state is persisted between app launches

### Blog Management
- Create new blogs with title, content, and optional image
- Edit existing blogs to update content
- Delete blogs that are no longer needed

### Viewing Blogs
- Browse all available blogs on the home screen
- View blog details including author information and statistics
- Filter blogs by categories

## Development

### Running in Development Mode
```
flutter run
```

### Building for Production
```
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
```


