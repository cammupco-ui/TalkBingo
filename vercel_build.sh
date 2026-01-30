#!/bin/bash

# Navigate to the app directory
cd app

# Deploy trigger: Force update (Safety Net)
# Create .env file from Vercel Environment Variables
echo "Generating .env file..."
echo "SUPABASE_URL=$SUPABASE_URL" > .env
echo "SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY" >> .env

# Install Flutter SDK if not available
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Configure and Build
# Exit on error
set -e

# Configure and Build
echo "Building Flutter Web..."
./flutter/bin/flutter config --enable-web
./flutter/bin/flutter pub get
./flutter/bin/flutter build web --release

# Ensure output is available for Vercel
# Assuming Vercel Output Directory is set to 'public' or root. 
# We copy to a root 'public' folder just in case.
mkdir -p ../public
cp -r build/web/* ../public/
echo "Build complete. Output copied to public/"
