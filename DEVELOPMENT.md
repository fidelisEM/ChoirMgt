# Development Guide

## Project Structure Overview

This Flutter project follows a clean architecture pattern with clear separation of concerns:

```
lib/
├── controllers/         # State management (Provider + GetX)
│   └── auth_controller.dart
├── models/             # Data models for Firebase
│   ├── user_model.dart
│   ├── choir_model.dart
│   ├── choir_member_model.dart
│   ├── attendance_model.dart
│   ├── payment_model.dart
│   ├── notification_model.dart
│   └── models.dart
├── screens/            # UI screens organized by feature
│   ├── auth/          # Login, register, forgot password
│   ├── home/          # Dashboard
│   ├── choir/         # Choir management (coming soon)
│   ├── member/        # Member management (coming soon)
│   ├── attendance/    # Attendance tracking (coming soon)
│   ├── payment/       # Payment management (coming soon)
│   ├── reports/       # Analytics (coming soon)
│   └── splash_screen.dart
├── services/          # Business logic and API services
│   ├── auth_service.dart
│   ├── user_service.dart
│   └── choir_service.dart
├── widgets/           # Reusable UI components (empty, ready for use)
├── utils/             # Helper functions (empty, ready for use)
├── firebase_options.dart
└── main.dart
```

## Current Implementation Status

### ✅ Completed Features

1. **Project Setup**
   - Flutter project with multi-platform support
   - All necessary dependencies configured
   - Firebase integration ready

2. **Data Models**
   - Complete data models for all entities
   - Firebase serialization/deserialization
   - Type-safe enums for statuses and roles

3. **Authentication System**
   - Firebase Auth integration
   - Role-based access control
   - Sign in, sign up, password reset
   - User profile management

4. **Basic UI Structure**
   - Splash screen with animations
   - Login and registration screens
   - Dashboard with role-based navigation
   - Clean Material Design 3 theme

5. **Services Layer**
   - AuthService for authentication operations
   - UserService for user management
   - ChoirService foundation

### 🚧 Next Steps (In Priority Order)

1. **Choir Management** (Next)
   - Create choir screens
   - Choir CRUD operations
   - Leader assignment

2. **Member Registration**
   - Member registration forms
   - QR code generation
   - Member profile management

3. **Attendance System**
   - Session creation
   - QR code scanning
   - Manual attendance marking

4. **Payment Management**
   - Fee structure setup
   - Payment recording
   - Status tracking

5. **Reports & Analytics**
   - Dashboard widgets
   - Export functionality

## Development Setup

### Prerequisites

- Flutter SDK 3.9.0 or higher
- Dart SDK (included with Flutter)
- Firebase project with proper configuration
- Android Studio / VS Code
- Git

### Local Development

1. **Clone and Setup**
   ```bash
   git clone [repository-url]
   cd choir-management-system
   flutter pub get
   ```

2. **Firebase Configuration**
   - Create a Firebase project
   - Enable Authentication, Firestore, Storage, Messaging
   - Replace placeholder values in `firebase_options.dart`
   - Or use `flutterfire configure` to auto-generate

3. **Running the App**
   ```bash
   # Check for issues
   flutter analyze
   
   # Run tests
   flutter test
   
   # Start development server
   flutter run
   
   # For web development
   flutter run -d chrome
   ```

### Code Quality Standards

1. **Linting**: Follow the rules in `analysis_options.yaml`
2. **Formatting**: Use `dart format .` before committing
3. **Testing**: Add tests for new services and widgets
4. **Documentation**: Document complex business logic

### Firebase Security Rules

For development, use these Firestore rules (update for production):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Choirs - leaders and admins can manage
    match /choirs/{choirId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
        (resource.data.leaderId == request.auth.uid || 
         resource.data.adminId == request.auth.uid);
    }
    
    // For development - allow all authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Architecture Decisions

### State Management
- **Provider** for authentication and global state
- **GetX** for navigation and simple state management
- **Local state** for form management and simple UI states

### Database Design
- **Firestore Collections**: Normalized structure for scalability
- **Real-time Updates**: Using Firestore streams where needed
- **Offline Support**: Firestore handles offline caching automatically

### Navigation
- **GetX Navigation**: Simple and powerful
- **Role-based Routes**: Different flows for different user types

### Folder Structure Rationale
- **Feature-based**: Screens organized by app features
- **Layered**: Services, controllers, models separated
- **Scalable**: Easy to add new features without restructuring

## Common Development Tasks

### Adding a New Feature

1. **Create Models** (if needed)
   ```dart
   // lib/models/new_feature_model.dart
   class NewFeatureModel {
     // Implementation
   }
   ```

2. **Create Service**
   ```dart
   // lib/services/new_feature_service.dart
   class NewFeatureService {
     // Business logic
   }
   ```

3. **Create Controller** (if complex state needed)
   ```dart
   // lib/controllers/new_feature_controller.dart
   class NewFeatureController extends ChangeNotifier {
     // State management
   }
   ```

4. **Create Screens**
   ```dart
   // lib/screens/new_feature/
   ```

5. **Add Navigation**
   - Update dashboard navigation
   - Add route permissions

### Adding a New Screen

1. Create in appropriate folder under `lib/screens/`
2. Follow naming convention: `feature_action_screen.dart`
3. Use consistent app bar and navigation patterns
4. Add proper error handling and loading states

### Working with Firebase

1. **Collections**: Follow the established naming conventions
2. **Indexes**: Create composite indexes as needed
3. **Security**: Update Firestore rules for new features
4. **Testing**: Use Firebase Emulator for development

## Testing Strategy

### Current Tests
- Basic widget test for app initialization
- Service layer ready for unit testing

### Recommended Testing Approach
1. **Unit Tests**: All service methods
2. **Widget Tests**: Key user flows
3. **Integration Tests**: Critical business processes
4. **Firebase Emulator**: For service testing

## Deployment Preparation

### Before Production
1. Update Firebase security rules
2. Enable appropriate Firebase features
3. Test on real devices
4. Performance testing
5. Update app metadata and icons

### Build Commands
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS  
flutter build ios --release

# Web
flutter build web --release
```

## Troubleshooting

### Common Issues

1. **Firebase not connecting**: Check `firebase_options.dart` configuration
2. **Build errors**: Run `flutter clean && flutter pub get`
3. **Dependency conflicts**: Update pubspec.yaml versions
4. **State not updating**: Check Provider/GetX setup

### Debug Tools
- Flutter Inspector for UI debugging
- Firebase console for data inspection
- Chrome DevTools for web debugging
- VS Code Flutter extension

## Contributing Guidelines

1. Follow the existing code structure
2. Add tests for new features
3. Update documentation
4. Use descriptive commit messages
5. Test on multiple devices before submitting

---

This project is designed to be scalable and maintainable. Each feature is self-contained and follows consistent patterns throughout the codebase.