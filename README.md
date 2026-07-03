# Choir Management System

A fully-featured Flutter application for comprehensive choir management including member registration, attendance tracking, QR code scanning, payment processing, automated status updates, notifications, and detailed analytics with export capabilities.

## Features

### 🔐 Role-Based Access Control
- **Admin**: Full system access, manages choirs and leaders
- **Choir Leader**: Manages members, attendance, and payments for their choir
- **Choir Member**: Views personal attendance and payment history

### 👥 Member Management
- Register new choir members
- Generate unique registration numbers and QR codes
- Track member status (Active/Inactive)
- Member profile management

### ✅ Attendance Tracking
- Create attendance sessions for different event types
- Manual attendance marking or QR code scanning
- Automatic late/absent status based on timing
- Attendance history and analytics

### 💰 Payment Management
- Flexible fee structures (weekly, monthly, quarterly, annual)
- Payment recording with multiple methods
- Outstanding fees tracking
- Payment history and reports

### 🤖 Automation
- Automatic member status updates based on attendance and payments
- Smart notifications and reminders
- Status change alerts

### 📊 Reports & Analytics
- Attendance reports and statistics
- Payment summaries
- Member activity reports
- Export to PDF and Excel

### 🔔 Notifications
- Practice reminders
- Payment reminders
- Absence warnings
- Status change notifications

## Technology Stack

- **Frontend**: Flutter (Cross-platform: Android, iOS, Web)
- **Backend**: Supabase (Database, Authentication, Real-time subscriptions)
- **State Management**: Provider + GetX
- **Database**: PostgreSQL (via Supabase)
- **Authentication**: Supabase Auth
- **File Export**: PDF & Excel generation (using pdf & excel packages)
- **QR Code**: Generation (qr_flutter) and scanning (mobile_scanner)
- **Notifications**: Local notifications and push notifications
- **Form Handling**: Flutter Form Builder with validators
- **UI Components**: Material Design with custom widgets
- **Localization**: Multi-language support (English & Swahili)

## Getting Started

### Prerequisites

- Flutter SDK (>= 3.9.0)
- Firebase account
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/choir-management-system.git
   cd choir-management-system
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Create Cloud Firestore database
   - Enable Cloud Messaging
   - Enable Firebase Storage

4. **Configure Firebase**
   - Install Firebase CLI: `npm install -g firebase-tools`
   - Login: `firebase login`
   - Configure project: `flutter pub global activate flutterfire_cli`
   - Generate config: `flutterfire configure`

5. **Update Firebase Options**
   - Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration

6. **Run the application**
   ```bash
   flutter run
   ```

## Features Implementation Status

- [x] Project setup and dependencies
- [x] Database schema design  
- [x] Authentication system
- [x] Basic UI structure and navigation
- [x] Choir management functionality
- [x] Member registration module
- [x] Attendance tracking system
- [x] QR code generation and scanning
- [x] Payment management
- [x] Automated status updates
- [x] Notifications system
- [x] Reports and analytics
- [x] Data export (PDF/Excel)
- [x] Testing and error handling

## User Roles & Permissions

### Administrator
- Create and manage choirs
- Assign choir leaders
- View system-wide reports
- Manage all users
- System configuration

### Choir Leader
- Register choir members
- Take attendance
- Record payments
- View choir reports
- Manage choir settings

### Choir Member
- View personal attendance history
- View payment status
- Receive notifications
- Update profile information

## 🚀 Implemented Features

### Core Modules
- **Authentication System**: Secure login/logout with session management
- **Choir Management**: Create, update, delete choirs with leader assignment
- **Member Registration**: Add members with auto-generated registration numbers and QR codes
- **Attendance Tracking**: Create sessions, mark attendance manually or via QR scanning
- **Payment Management**: Record payments, track outstanding fees, multiple payment methods
- **Automated Member Status**: Rule-based status updates based on attendance and payments
- **Notification System**: Push notifications for reminders and announcements
- **Reports & Analytics**: Comprehensive reports with charts and statistics
- **Data Export**: Export reports to PDF and Excel formats

### Technical Features
- **QR Code Integration**: Generate unique QR codes for members and scan for attendance
- **Real-time Updates**: Live data synchronization across devices
- **Offline Capability**: Local data storage with sync when online
- **Multi-language Support**: English and Swahili localization
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Responsive Design**: Works on mobile, tablet, and web platforms
- **Security**: Role-based access control and secure data handling

### Automation Features
- **Smart Status Updates**: Automatically update member status based on attendance and payment patterns
- **Attendance Rules**: Configurable rules for late arrival and absence tracking
- **Payment Reminders**: Automatic notifications for overdue payments
- **Session Management**: Auto-close attendance sessions after grace period

---

**Note**: This is a complete, production-ready choir management system. To deploy, you'll need to configure Supabase with your own project credentials. Update the values in `supabase_options.dart` with your actual Supabase configuration.
