# Sample Data Generator

This directory contains tools to populate your choir management system with realistic sample data so you can see all the implemented features working.

## 🚀 Quick Start

### Option 1: Database Integration (Recommended)
This will create real records in your Supabase database:

```bash
dart generate_database_sample_data.dart
```

### Option 2: In-App Generator
Run the app and use the sample data screen:

```bash
flutter run lib/sample_data_app.dart
```

## 📊 What Gets Generated

### Users (10 total)
- **1 Admin**: `admin@choirms.com`
- **3 Choir Leaders**: 
  - `michael.conductor@email.com`
  - `emily.harmony@email.com` 
  - `david.music@email.com`
- **6 Choir Members**:
  - `alice.soprano@email.com`
  - `james.tenor@email.com`
  - `maria.alto@email.com`
  - `robert.bass@email.com`
  - `linda.soprano@email.com`
  - `carlos.tenor@email.com`

### Choirs (5 total)
1. **St. Mary's Cathedral Choir** - Traditional sacred music
2. **Harmony Youth Ensemble** - Contemporary Christian music
3. **Gospel Voices United** - Soulful gospel choir
4. **Chamber Singers** - Renaissance and Baroque music
5. **Christmas Carol Ensemble** - Seasonal choir (inactive)

### Realistic Data Includes
- ✅ Choir memberships with attendance records
- ✅ Payment history and outstanding fees
- ✅ User profile images from Unsplash
- ✅ Realistic join dates and activity timestamps
- ✅ Different member statuses (active, inactive, suspended)
- ✅ Attendance rates and session data

## 🎯 Features You Can Test

After generating sample data, all these features will work with real data:

### ✅ Fixed Features
1. **Member Name Display** - Shows actual member names instead of user IDs
2. **Edit Form Fields** - Admin/leader email lookup and validation
3. **Dynamic Statistics** - Real attendance rates and session counts
4. **Image Upload** - Full image picker and upload system
5. **Activity Feed** - Dynamic activity feed with real timestamps

### 🔍 What You'll See
- **Choir Detail Screen**: Real member names, calculated statistics, dynamic activities
- **Member Lists**: Proper user profiles with realistic data
- **Reports**: Actual attendance percentages and session counts
- **Edit Forms**: Working email lookup for admin/leader changes
- **Create Forms**: Image upload with preview functionality

## 🛠️ Technical Details

### Database Tables Used
- `users` - User profiles and authentication data
- `choirs` - Choir information and metadata
- `choir_members` - Membership records with attendance/payment data

### Services Created
- `DatabaseSampleDataService` - Inserts data directly into Supabase
- `SampleDataService` - In-memory sample data generation
- `ActivityService` - Manages choir activity feed

## 🔧 Troubleshooting

### If the generator fails:
1. **Check Supabase connection**: Verify credentials in `lib/supabase_options.dart`
2. **Database tables**: Ensure all required tables exist in your Supabase project
3. **Permissions**: Check your Supabase RLS (Row Level Security) policies

### Common Issues:
- **"Sample data already exists"**: Run with clear option or manually delete sample records
- **"Connection failed"**: Check your internet connection and Supabase URL/key
- **"Table not found"**: Run your database migrations first

## 🎉 Ready to Test!

Once sample data is generated:

1. Run the app: `flutter run`
2. Navigate to any choir detail screen
3. See real member names, statistics, and activities
4. Try creating/editing choirs with image upload
5. Test the admin/leader email lookup functionality

All the features we implemented will now work with realistic data instead of placeholders!