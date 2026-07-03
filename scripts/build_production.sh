#!/bin/bash

# Production Build Script for Choir Management System
# This script builds the app for all platforms with production optimizations

set -e  # Exit on any error

echo "🚀 Starting Production Build Process..."
echo "======================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Check Flutter version
print_status "Checking Flutter version..."
flutter --version

# Set environment to production
export ENVIRONMENT=production

# Require production Supabase credentials to be supplied via the environment
# (e.g. exported from your secrets manager / CI secrets). There is no
# fallback in source, so a missing value here means a missing value in the
# built app - it will fail to configure at runtime instead.
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_ANON_KEY" ]; then
    print_error "SUPABASE_URL and SUPABASE_ANON_KEY must be set in the environment before running this script."
    exit 1
fi

DART_DEFINES="--dart-define=ENVIRONMENT=production --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY"

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
flutter pub get

# Run static analysis
print_status "Running static analysis..."
if ! flutter analyze --fatal-warnings; then
    print_error "Static analysis failed. Please fix the issues before building for production."
    exit 1
fi

# Run tests
print_status "Running tests..."
if ! flutter test; then
    print_error "Tests failed. Please fix the failing tests before building for production."
    exit 1
fi

# Format code
print_status "Checking code formatting..."
if ! dart format --output=none --set-exit-if-changed .; then
    print_warning "Code formatting issues detected. Run 'dart format .' to fix them."
fi

# Create build directory
mkdir -p build_output/production

# Build for Web
print_status "Building for Web (Production)..."

flutter build web \
    --release \
    --no-tree-shake-icons \
    --base-href "/" \
    $DART_DEFINES

if [ $? -eq 0 ]; then
    print_success "Web build completed successfully"
    
    # Create web build archive
    print_status "Creating web build archive..."
    cd build/web
    tar -czf ../../build_output/production/web-production-$(date +%Y%m%d_%H%M%S).tar.gz .
    cd ../..
else
    print_error "Web build failed"
    exit 1
fi

# Build for Android
print_status "Building for Android (Production)..."

# Build APK
flutter build apk \
    --release \
    --split-per-abi \
    $DART_DEFINES

if [ $? -eq 0 ]; then
    print_success "Android APK build completed successfully"
    
    # Copy APKs to output directory
    cp build/app/outputs/flutter-apk/*.apk build_output/production/
else
    print_error "Android APK build failed"
    exit 1
fi

# Build App Bundle (for Play Store)
flutter build appbundle \
    --release \
    $DART_DEFINES

if [ $? -eq 0 ]; then
    print_success "Android App Bundle build completed successfully"
    
    # Copy AAB to output directory
    cp build/app/outputs/bundle/release/app-release.aab build_output/production/
else
    print_error "Android App Bundle build failed"
    exit 1
fi

# Build size analysis
print_status "Analyzing build sizes..."
echo "Build Size Analysis:" > build_output/production/build_analysis.txt
echo "===================" >> build_output/production/build_analysis.txt
echo "" >> build_output/production/build_analysis.txt

# Web build size
if [ -d "build/web" ]; then
    WEB_SIZE=$(du -sh build/web | cut -f1)
    echo "Web build size: $WEB_SIZE" >> build_output/production/build_analysis.txt
fi

# APK sizes
for apk in build_output/production/*.apk; do
    if [ -f "$apk" ]; then
        APK_SIZE=$(du -sh "$apk" | cut -f1)
        APK_NAME=$(basename "$apk")
        echo "APK size ($APK_NAME): $APK_SIZE" >> build_output/production/build_analysis.txt
    fi
done

# AAB size
if [ -f "build_output/production/app-release.aab" ]; then
    AAB_SIZE=$(du -sh build_output/production/app-release.aab | cut -f1)
    echo "App Bundle size: $AAB_SIZE" >> build_output/production/build_analysis.txt
fi

# Security check - look for sensitive data in build
print_status "Running security checks..."
SECURITY_ISSUES=0

# Check for debug information in release builds
if grep -r "flutter_tools" build/web/ &>/dev/null; then
    print_warning "Debug information found in web build"
    ((SECURITY_ISSUES++))
fi

# Check for development URLs
if grep -r "localhost" build/web/ &>/dev/null; then
    print_warning "Localhost references found in build"
    ((SECURITY_ISSUES++))
fi

# Check for placeholder credentials
if grep -rE "(your-|placeholder|example\.com)" build/web/ &>/dev/null; then
    print_warning "Placeholder credentials or URLs found in build"
    ((SECURITY_ISSUES++))
fi

if [ $SECURITY_ISSUES -eq 0 ]; then
    print_success "No security issues detected"
else
    print_warning "$SECURITY_ISSUES potential security issues detected"
fi

# Generate build manifest
print_status "Generating build manifest..."
cat > build_output/production/build_manifest.json << EOF
{
  "build_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')",
  "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
  "flutter_version": "$(flutter --version | head -n1)",
  "environment": "production",
  "builds": {
    "web": true,
    "android_apk": true,
    "android_aab": true
  },
  "security_checks": {
    "issues_found": $SECURITY_ISSUES,
    "scanned": true
  }
}
EOF

# Final summary
print_success "🎉 Production build completed successfully!"
echo ""
echo "Build artifacts are available in: build_output/production/"
echo ""
echo "Contents:"
ls -la build_output/production/
echo ""

if [ $SECURITY_ISSUES -gt 0 ]; then
    print_warning "Please review and fix the security issues before deploying to production"
else
    print_success "All security checks passed - ready for production deployment"
fi

echo ""
echo "Next steps:"
echo "1. Review the build analysis in build_analysis.txt"
echo "2. Test the builds in a staging environment"
echo "3. Deploy using your preferred deployment method"
echo ""
echo "🚀 Happy deploying!"