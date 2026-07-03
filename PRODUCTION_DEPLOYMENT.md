# Production Deployment Guide

This guide provides comprehensive instructions for deploying the Choir Management System to production environments.

## 🚀 Quick Start

1. **Configure Environment Variables**
2. **Run Production Build**
3. **Deploy to Hosting Platform**
4. **Configure Monitoring**

## 📋 Pre-deployment Checklist

### Configuration Requirements

- [ ] Supabase project created and configured
- [ ] Environment variables set up
- [ ] Firebase project created (for hosting and notifications)
- [ ] Domain name configured (if applicable)
- [ ] SSL certificate obtained
- [ ] Backup strategy in place

### Security Requirements

- [ ] All placeholder credentials replaced
- [ ] Security headers configured
- [ ] CSP (Content Security Policy) reviewed
- [ ] API keys secured
- [ ] Database access restricted
- [ ] HTTPS enforced

### Testing Requirements

- [ ] All tests passing
- [ ] Security scan completed
- [ ] Performance testing done
- [ ] Cross-browser testing completed
- [ ] Mobile responsiveness verified

## 🔧 Environment Configuration

### 1. Create Environment Files

Copy the example environment file:
```bash
cp .env.example .env.production
```

Edit `.env.production` with your production values:
```bash
# Environment Configuration
ENVIRONMENT=production

# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-production-anon-key

# Security Configuration
SECRET_KEY=your-secure-secret-key
SESSION_TIMEOUT=4

# Features Configuration
ENABLE_ANALYTICS=true
ENABLE_CRASH_REPORTING=true
ENABLE_LOGGING=false
ENABLE_PUSH_NOTIFICATIONS=true
```

### 2. Supabase Setup

1. Create a new Supabase project at [supabase.com](https://supabase.com)
2. Run the database setup script:
   ```sql
   -- Run database_setup.sql in your Supabase SQL editor
   ```
3. Configure Row Level Security (RLS) policies
4. Set up authentication providers
5. Configure storage buckets

### 3. Firebase Setup (Optional - for hosting and notifications)

1. Create a Firebase project
2. Enable Hosting
3. Enable Cloud Messaging
4. Configure `firebase.json`
5. Initialize Firebase in your project:
   ```bash
   firebase init hosting
   ```

## 🏗️ Building for Production

### Automated Build

Use the production build script:
```bash
./scripts/build_production.sh
```

This script will:
- Run static analysis
- Execute tests
- Build for all platforms
- Run security checks
- Generate build artifacts

### Manual Build

If you prefer to build manually:

`SUPABASE_URL` / `SUPABASE_ANON_KEY` are compile-time `--dart-define` values now — there
is no hardcoded fallback in source, so every build below must pass them explicitly
(export them from your secrets manager first).

#### Web Build
```bash
flutter build web \
  --release \
  --no-tree-shake-icons \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

#### Android Build
```bash
# APK for direct distribution
flutter build apk \
  --release \
  --split-per-abi \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

# App Bundle for Play Store
flutter build appbundle \
  --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
```

## 🌐 Web Deployment Options

### Option 1: Firebase Hosting (Recommended)

1. **Install Firebase CLI:**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login and initialize:**
   ```bash
   firebase login
   firebase init hosting
   ```

3. **Deploy:**
   ```bash
   # Staging
   ./scripts/deploy_web.sh staging
   
   # Production
   ./scripts/deploy_web.sh production
   ```

### Option 2: Netlify

1. Build the app locally or use CI/CD
2. Deploy the `build/web` directory to Netlify
3. Configure redirects in `netlify.toml`:
   ```toml
   [[redirects]]
     from = "/*"
     to = "/index.html"
     status = 200
   ```

### Option 3: Vercel

1. Install Vercel CLI: `npm i -g vercel`
2. Deploy: `vercel --prod build/web`

### Option 4: Traditional Web Server

1. Copy `build/web` contents to your web server
2. Ensure `.htaccess` file is properly configured
3. Configure SSL and security headers
4. Set up URL rewriting for SPA routing

## 📱 Mobile App Deployment

### Android (Google Play Store)

1. **Prepare for release:**
   - Update version in `pubspec.yaml`
   - Create release notes
   - Update store listing

2. **Upload to Play Console:**
   ```bash
   # Upload the AAB file from build_output/production/
   ```

3. **Release process:**
   - Internal testing
   - Closed testing (beta)
   - Open testing
   - Production release

### iOS (App Store)

1. **Build with Xcode:**
   ```bash
   flutter build ios --release
   ```

2. **Archive and upload:**
   - Open `ios/Runner.xcworkspace` in Xcode
   - Archive the app
   - Upload to App Store Connect

## 🔄 CI/CD Pipeline

### GitHub Actions

The project includes automated CI/CD workflows:

- **CI Pipeline** (`.github/workflows/ci.yml`):
  - Runs tests and analysis
  - Builds for all platforms
  - Performs security scans

- **Release Pipeline** (`.github/workflows/release.yml`):
  - Triggered on release tags
  - Builds and deploys to production
  - Uploads to app stores

### Setting up GitHub Secrets

Add these secrets to your GitHub repository:

```bash
# Firebase - one project (see .firebaserc), staging and production are
# separate Hosting channels ("staging" preview channel vs "live"), not
# separate Firebase projects.
FIREBASE_SERVICE_ACCOUNT
FIREBASE_PROJECT_ID

# Google Play
GOOGLE_PLAY_SERVICE_ACCOUNT

# Supabase - separate projects: choir_management_system (dev/test) and
# choir-management-production (production). CI's build-web job picks
# _STAGING vs _PROD based on branch (develop vs main).
SUPABASE_URL_PROD
SUPABASE_ANON_KEY_PROD
SUPABASE_URL_STAGING
SUPABASE_ANON_KEY_STAGING
```

## 📊 Monitoring and Maintenance

### 1. Application Monitoring

Set up monitoring for:
- Application errors and crashes
- Performance metrics
- User analytics
- API response times

### 2. Infrastructure Monitoring

Monitor:
- Server uptime and performance
- Database performance
- CDN performance
- SSL certificate expiration

### 3. Security Monitoring

Implement:
- Security scanning
- Dependency vulnerability checks
- Access log monitoring
- Intrusion detection

### 4. Backup Strategy

Set up regular backups for:
- Database (Supabase automatic backups)
- User-uploaded files
- Application configuration
- SSL certificates

## 🚨 Incident Response

### Production Issues

1. **Immediate Response:**
   - Check monitoring dashboards
   - Review error logs
   - Implement temporary fixes if necessary

2. **Communication:**
   - Notify stakeholders
   - Update status page
   - Communicate with users

3. **Resolution:**
   - Identify root cause
   - Implement permanent fix
   - Deploy hotfix if needed

### Rollback Procedure

1. **Web App:**
   ```bash
   # Revert to previous Firebase deployment
   firebase hosting:clone SOURCE_SITE_ID:SOURCE_CHANNEL TARGET_SITE_ID:live
   ```

2. **Mobile Apps:**
   - Use staged rollout features
   - Revert to previous version in app stores

## 📈 Performance Optimization

### Web Performance

1. **Enable compression** (gzip/brotli)
2. **Configure caching headers**
3. **Use CDN** for static assets
4. **Implement service workers**
5. **Optimize images and fonts**

### Mobile Performance

1. **App size optimization:**
   ```bash
   flutter build apk --analyze-size
   ```

2. **Memory usage monitoring**
3. **Battery usage optimization**
4. **Network efficiency**

## 🔐 Security Best Practices

### Runtime Security

1. **API Security:**
   - Rate limiting
   - Input validation
   - SQL injection prevention
   - XSS protection

2. **Authentication:**
   - Strong password requirements
   - Multi-factor authentication
   - Session management
   - JWT token validation

3. **Data Protection:**
   - Encryption at rest and in transit
   - Regular security audits
   - Compliance with data protection laws
   - Secure data deletion

### Infrastructure Security

1. **Network Security:**
   - Firewall configuration
   - VPN access for admin
   - DDoS protection
   - SSL/TLS configuration

2. **Access Control:**
   - Principle of least privilege
   - Regular access reviews
   - Secure API keys storage
   - Environment separation

## 📞 Support and Maintenance

### Regular Maintenance Tasks

- [ ] Weekly security updates
- [ ] Monthly dependency updates
- [ ] Quarterly performance reviews
- [ ] Semi-annual security audits
- [ ] Annual disaster recovery tests

### Support Channels

- Technical issues: Create GitHub issues
- Security vulnerabilities: security@choirmanagement.com
- General support: support@choirmanagement.com

### Documentation Updates

Keep these documents updated:
- API documentation
- User manuals
- Deployment guides
- Security procedures

---

## 📋 Post-Deployment Checklist

After successful deployment:

- [ ] Verify all features work correctly
- [ ] Test user authentication
- [ ] Check database connections
- [ ] Validate email notifications
- [ ] Test mobile app functionality
- [ ] Verify analytics tracking
- [ ] Check error reporting
- [ ] Test backup/restore procedures
- [ ] Update documentation
- [ ] Train support team

## 🎉 Success!

Your Choir Management System is now live in production! 

Remember to:
- Monitor the application closely for the first 24-48 hours
- Have a rollback plan ready
- Keep stakeholders informed of the deployment status
- Celebrate the successful launch! 🎉

For any issues or questions, refer to the troubleshooting section or contact the development team.