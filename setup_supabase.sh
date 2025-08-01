#!/bin/bash

# HouseHelp Supabase Database Setup Script
# This script sets up the complete database schema for the HouseHelp application

echo "🏠 HouseHelp Database Setup Starting..."
echo "Project URL: https://ptqsxaewfmebptcuoptc.supabase.co"

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found. Please install it first:"
    echo "npm install -g supabase"
    exit 1
fi

echo "✅ Supabase CLI found"

# Login to Supabase (you'll need to authenticate)
echo "🔐 Please authenticate with Supabase..."
supabase login

# Link to your project
echo "🔗 Linking to your Supabase project..."
supabase link --project-ref ptqsxaewfmebptcuoptc

# Apply database migrations
echo "📊 Setting up database schema..."

# Create the main database schema
supabase db push

echo "✅ Database schema applied successfully!"

# Generate TypeScript types (optional but helpful)
echo "🔧 Generating TypeScript types..."
supabase gen types typescript --local > lib/types/database.types.ts

echo "🎉 HouseHelp database setup complete!"
echo ""
echo "Next steps:"
echo "1. Run 'flutter pub get' to install dependencies"
echo "2. Update your Flutter app with the new database URL"
echo "3. Test the authentication and basic functionality"
echo ""
echo "Your Supabase project is ready for HouseHelp! 🚀"
