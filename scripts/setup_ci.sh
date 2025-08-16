#!/bin/bash

# Pfandler CI/CD Setup Script
# This script helps set up the local environment for CI/CD

set -e

echo "🚀 Pfandler CI/CD Setup Script"
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check Flutter installation
echo ""
echo "📱 Checking Flutter installation..."
if command_exists flutter; then
    print_status "Flutter is installed"
    flutter --version
else
    print_error "Flutter is not installed"
    echo "Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# Check Ruby installation (for Fastlane)
echo ""
echo "💎 Checking Ruby installation..."
if command_exists ruby; then
    print_status "Ruby is installed: $(ruby -v)"
else
    print_warning "Ruby is not installed (required for Fastlane)"
    echo "Install Ruby using: brew install ruby"
fi

# Check Fastlane installation
echo ""
echo "🚀 Checking Fastlane installation..."
if command_exists fastlane; then
    print_status "Fastlane is installed: $(fastlane -v)"
else
    print_warning "Fastlane is not installed"
    echo "Install Fastlane using: gem install fastlane"
fi

# Check Bitrise CLI installation
echo ""
echo "🔧 Checking Bitrise CLI installation..."
if command_exists bitrise; then
    print_status "Bitrise CLI is installed"
else
    print_warning "Bitrise CLI is not installed"
    echo "Install Bitrise CLI using: brew install bitrise"
fi

# Check for environment files
echo ""
echo "📝 Checking environment configuration..."

if [ -f ".env" ]; then
    print_status "Root .env file exists"
else
    print_warning "Root .env file not found"
    echo "Creating template .env file..."
    cat > .env.template << EOF
# API Configuration
API_BASE_URL=http://localhost:8080
STAGING_API_URL=https://staging-api.pfandler.app
PRODUCTION_API_URL=https://api.pfandler.app

# Slack
SLACK_WEBHOOK_URL=

# Apple
APPLE_APP_ID=
APPLE_TEAM_ID=

# Google
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON=

# Firebase
FIREBASE_APP_ID_ANDROID=
FIREBASE_SERVICE_ACCOUNT=
EOF
    print_status "Created .env.template - Copy to .env and fill in values"
fi

# Create necessary directories
echo ""
echo "📁 Setting up directories..."

directories=(
    ".github/workflows"
    "ios/fastlane"
    "android/fastlane"
    "scripts"
    "certificates"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_status "Created directory: $dir"
    else
        print_status "Directory exists: $dir"
    fi
done

# Setup Git hooks
echo ""
echo "🔗 Setting up Git hooks..."

if [ ! -f ".git/hooks/pre-commit" ]; then
    cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook for Pfandler

echo "Running pre-commit checks..."

# Run Flutter analyze
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Flutter analyze failed"
    exit 1
fi

# Run Flutter format check
flutter format --set-exit-if-changed lib/ test/
if [ $? -ne 0 ]; then
    echo "❌ Code formatting issues found"
    echo "Run 'flutter format lib/ test/' to fix"
    exit 1
fi

# Run tests
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

echo "✅ All pre-commit checks passed"
EOF
    chmod +x .git/hooks/pre-commit
    print_status "Created pre-commit hook"
else
    print_status "Pre-commit hook already exists"
fi

# Check for secrets files
echo ""
echo "🔐 Checking for secrets..."

secrets_needed=(
    "ios/Runner/GoogleService-Info.plist"
    "android/app/google-services.json"
)

for secret in "${secrets_needed[@]}"; do
    if [ -f "$secret" ]; then
        print_status "Found: $secret"
    else
        print_warning "Missing: $secret"
    fi
done

# Initialize Fastlane if needed
echo ""
echo "⚡ Fastlane setup..."

if [ ! -f "ios/fastlane/Appfile" ]; then
    print_warning "iOS Fastlane not initialized"
    echo "Run 'cd ios && fastlane init' to set up iOS deployment"
fi

if [ ! -f "android/fastlane/Appfile" ]; then
    print_warning "Android Fastlane not initialized"
    echo "Run 'cd android && fastlane init' to set up Android deployment"
fi

# Validate Bitrise configuration
echo ""
echo "✅ Validating Bitrise configuration..."

if [ -f "bitrise.yml" ]; then
    if command_exists bitrise; then
        bitrise validate -c bitrise.yml
        if [ $? -eq 0 ]; then
            print_status "Bitrise configuration is valid"
        else
            print_error "Bitrise configuration has errors"
        fi
    else
        print_warning "Bitrise CLI not installed, skipping validation"
    fi
else
    print_error "bitrise.yml not found"
fi

# Summary
echo ""
echo "================================"
echo "📊 Setup Summary"
echo "================================"

echo ""
echo "Next steps:"
echo "1. Copy .env.template to .env and fill in your values"
echo "2. Add your certificates to the certificates/ directory"
echo "3. Configure code signing for iOS and Android"
echo "4. Set up secrets in your CI/CD platform (Bitrise/GitHub)"
echo "5. Initialize Fastlane for iOS and Android if needed"

echo ""
echo "Useful commands:"
echo "  flutter test                    - Run tests"
echo "  flutter analyze                  - Analyze code"
echo "  flutter build apk --release      - Build Android APK"
echo "  flutter build ios --release      - Build iOS app"
echo "  bitrise run test-and-build       - Run Bitrise workflow locally"
echo "  cd ios && fastlane beta          - Deploy iOS beta"
echo "  cd android && fastlane beta      - Deploy Android beta"

echo ""
print_status "Setup check complete!"