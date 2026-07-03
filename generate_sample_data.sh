#!/bin/bash

echo "🚀 Choir Management System - Sample Data Generator"
echo "=================================================="
echo ""

# Check if dart is available
if ! command -v dart &> /dev/null; then
    echo "❌ Dart is not installed or not in PATH"
    echo "Please install Flutter/Dart first"
    exit 1
fi

echo "📊 Generating sample data for your choir management system..."
echo ""

# Run the sample data generator
dart generate_database_sample_data.dart

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Sample data generation completed successfully!"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Run the app: flutter run"
    echo "2. Navigate to any choir detail screen"
    echo "3. See all the implemented features working with real data!"
    echo ""
    echo "🔐 Sample login accounts:"
    echo "   Admin: admin@choirms.com"
    echo "   Leader: michael.conductor@email.com"
    echo "   Member: alice.soprano@email.com"
else
    echo ""
    echo "❌ Sample data generation failed"
    echo "Please check the error messages above and try again"
    exit 1
fi