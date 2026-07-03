#!/bin/bash

# Web Deployment Script for Choir Management System
# This script deploys the web build to Firebase Hosting

set -e

echo "🌐 Deploying to Firebase Hosting..."
echo "=================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if environment is provided
ENVIRONMENT=${1:-staging}

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    print_error "Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

print_status "Deploying to $ENVIRONMENT environment"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    print_error "Firebase CLI is not installed. Install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    print_error "Not logged in to Firebase. Run 'firebase login' first"
    exit 1
fi

# Set environment variables
export ENVIRONMENT=$ENVIRONMENT

# Pick per-environment Supabase credentials (SUPABASE_URL_STAGING /
# SUPABASE_ANON_KEY_STAGING, or the _PROD equivalents). These must be
# exported in the shell (or CI secrets) before running this script - there
# is no fallback baked into source.
if [ "$ENVIRONMENT" == "production" ]; then
    SB_URL="$SUPABASE_URL_PROD"
    SB_ANON_KEY="$SUPABASE_ANON_KEY_PROD"
else
    SB_URL="$SUPABASE_URL_STAGING"
    SB_ANON_KEY="$SUPABASE_ANON_KEY_STAGING"
fi

if [ -z "$SB_URL" ] || [ -z "$SB_ANON_KEY" ]; then
    print_error "SUPABASE_URL_${ENVIRONMENT^^} and SUPABASE_ANON_KEY_${ENVIRONMENT^^} must be set in the environment before running this script."
    exit 1
fi

# Build the app
print_status "Building Flutter web app for $ENVIRONMENT..."
flutter build web \
    --release \
    --no-tree-shake-icons \
    --dart-define=ENVIRONMENT=$ENVIRONMENT \
    --dart-define=SUPABASE_URL=$SB_URL \
    --dart-define=SUPABASE_ANON_KEY=$SB_ANON_KEY

if [ $? -ne 0 ]; then
    print_error "Flutter build failed"
    exit 1
fi

# Deploy to Firebase. There is a single Firebase Hosting project (set as
# "default" in .firebaserc) - staging deploys to a temporary preview
# channel on that same project rather than a separate project/alias.
print_status "Deploying to Firebase Hosting..."

if [ "$ENVIRONMENT" == "production" ]; then
    # Production deployment - the live channel
    firebase deploy --only hosting
else
    # Staging deployment - a preview channel that auto-expires
    firebase hosting:channel:deploy staging --expires 30d
fi

if [ $? -eq 0 ]; then
    print_success "🚀 Deployment to $ENVIRONMENT completed successfully!"
    
    if [ "$ENVIRONMENT" == "staging" ]; then
        print_status "Staging URL will be displayed above"
    else
        print_status "Production site is now live"
    fi
else
    print_error "Deployment failed"
    exit 1
fi