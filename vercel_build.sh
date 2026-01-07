#!/bin/bash

# Navigate to the app directory
cd app

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
echo "Building Flutter Web..."
./flutter/bin/flutter config --enable-web
./flutter/bin/flutter pub get
./flutter/bin/flutter build web --release
