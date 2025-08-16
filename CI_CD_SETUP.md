# CI/CD Setup Guide for Pfandler App

This guide explains how to set up and use the CI/CD pipelines for the Pfandler Flutter application.

## 📋 Table of Contents

- [Overview](#overview)
- [Bitrise Setup](#bitrise-setup)
- [GitHub Actions Setup](#github-actions-setup)
- [Fastlane Setup](#fastlane-setup)
- [Environment Variables](#environment-variables)
- [Deployment Workflow](#deployment-workflow)

## 🔍 Overview

The Pfandler app uses multiple CI/CD tools for automated testing, building, and deployment:

1. **Bitrise** - Primary CI/CD platform for mobile apps
2. **GitHub Actions** - Alternative CI/CD integrated with GitHub
3. **Fastlane** - Automation tool for iOS and Android deployment

## 🔧 Bitrise Setup

### 1. Import the Project

1. Sign up/Login to [Bitrise.io](https://www.bitrise.io)
2. Click "Add New App"
3. Connect your GitHub repository
4. Select the repository containing the Pfandler app
5. Bitrise will auto-detect Flutter configuration

### 2. Configure Workflows

The `bitrise.yml` file contains pre-configured workflows:

- **test-and-build**: Runs on pull requests
- **deploy-staging**: Deploys to staging on develop branch
- **deploy-production**: Deploys to production on main branch
- **nightly-build**: Scheduled nightly builds

### 3. Set Up Code Signing

#### iOS
1. Upload your certificates to Bitrise:
   - Development certificate
   - Distribution certificate
   - Provisioning profiles

2. Use Bitrise's automatic provisioning:
   ```
   Settings → Code Signing → iOS Auto Provision
   ```

#### Android
1. Upload your keystore:
   ```
   Settings → Code Signing → Android Keystore File
   ```

2. Configure keystore credentials as secrets

### 4. Configure Secrets

Add these secrets in Bitrise:

```env
# Slack
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Apple
APPLE_APP_ID=your_apple_app_id
APPLE_APP_SPECIFIC_PASSWORD=your_app_specific_password
APPLE_TEAM_ID=your_team_id

# Google Play
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON={"type":"service_account",...}

# Firebase
FIREBASE_APP_ID_ANDROID=your_firebase_app_id
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}

# Android Keystore
BITRISEIO_ANDROID_KEYSTORE_URL=file://path/to/keystore
BITRISEIO_ANDROID_KEYSTORE_PASSWORD=your_keystore_password
BITRISEIO_ANDROID_KEYSTORE_ALIAS=your_keystore_alias
BITRISEIO_ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD=your_key_password

# Code Coverage
CODECOV_TOKEN=your_codecov_token
```

## 🐙 GitHub Actions Setup

### 1. Enable GitHub Actions

GitHub Actions is automatically enabled. The workflows are defined in `.github/workflows/`.

### 2. Configure Secrets

Go to Settings → Secrets and variables → Actions, and add:

```env
# Google Play
GOOGLE_PLAY_SERVICE_ACCOUNT_JSON={"type":"service_account",...}

# Firebase
FIREBASE_APP_ID_ANDROID=your_firebase_app_id
FIREBASE_SERVICE_ACCOUNT={"type":"service_account",...}

# Slack
SLACK_WEBHOOK=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### 3. Configure Environments

Create two environments:
- **staging**: For develop branch deployments
- **production**: For main branch deployments

Set up environment protection rules for production.

## 🚀 Fastlane Setup

### 1. Install Fastlane

```bash
# Install using Homebrew (macOS)
brew install fastlane

# Or using RubyGems
gem install fastlane
```

### 2. iOS Setup

```bash
cd ios
fastlane init
```

Configure your Apple Developer account:
```bash
fastlane match init
fastlane match appstore
fastlane match development
```

### 3. Android Setup

```bash
cd android
fastlane init
```

Create service account for Google Play:
1. Go to Google Play Console
2. Settings → API access
3. Create service account
4. Download JSON key

### 4. Environment Variables

Create `.env` files:

```bash
# ios/.env
APPLE_APP_ID=your_app_id
APPLE_TEAM_ID=your_team_id
SLACK_WEBHOOK_URL=your_webhook_url

# android/.env
GOOGLE_PLAY_JSON_KEY_PATH=/path/to/google-play-key.json
FIREBASE_APP_ID=your_firebase_app_id
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/firebase-key.json
SLACK_WEBHOOK_URL=your_webhook_url
```

## 📦 Deployment Workflow

### Development Workflow

1. Create feature branch from `develop`
2. Make changes and commit
3. Push to GitHub - triggers PR build
4. Merge to `develop` - triggers staging deployment

### Production Workflow

1. Create release branch from `develop`
2. Update version in `pubspec.yaml`
3. Create PR to `main`
4. Merge to `main` - triggers production deployment
5. Create GitHub release with tag `v1.0.0`

### Manual Deployment

#### Using Fastlane

```bash
# iOS Beta
cd ios && fastlane beta

# iOS Release
cd ios && fastlane release

# Android Beta
cd android && fastlane beta

# Android Release
cd android && fastlane release

# Firebase Distribution
cd android && fastlane firebase
```

#### Using Bitrise CLI

```bash
# Install Bitrise CLI
brew install bitrise

# Run workflow locally
bitrise run test-and-build

# Deploy to staging
bitrise run deploy-staging

# Deploy to production
bitrise run deploy-production
```

## 🔄 Versioning Strategy

### Version Format
- Production: `major.minor.patch` (e.g., 1.2.3)
- Build number: Auto-incremented by CI/CD

### Updating Version

1. Update `pubspec.yaml`:
```yaml
version: 1.2.3+100  # version+buildNumber
```

2. Commit with message:
```bash
git commit -m "Bump version to 1.2.3"
git tag v1.2.3
git push origin main --tags
```

## 🏗️ Build Configuration

### Environment-Specific Builds

The app supports different API endpoints for different environments:

- **Local Development**: `http://localhost:8080`
- **Staging**: `https://staging-api.pfandler.app`
- **Production**: `https://api.pfandler.app`

These are automatically configured during CI/CD builds.

### Build Flavors

```bash
# Development build
flutter build apk --debug --dart-define=ENV=development

# Staging build
flutter build apk --release --dart-define=ENV=staging

# Production build
flutter build apk --release --dart-define=ENV=production
```

## 📊 Monitoring

### Build Status

- **Bitrise Dashboard**: View build status, logs, and artifacts
- **GitHub Actions**: Check Actions tab in GitHub repository
- **Slack Notifications**: Automated notifications for build status

### Code Coverage

Code coverage reports are automatically uploaded to Codecov:
- View at: https://codecov.io/gh/YOUR_ORG/pfandler

### App Analytics

Monitor app performance and crashes:
- Firebase Crashlytics
- Firebase Analytics
- App Store Connect Analytics
- Google Play Console Statistics

## 🆘 Troubleshooting

### Common Issues

1. **iOS Build Fails - Code Signing**
   ```bash
   fastlane match nuke distribution
   fastlane match appstore
   ```

2. **Android Build Fails - Keystore**
   - Verify keystore file exists
   - Check keystore password and alias

3. **Flutter Version Mismatch**
   - Update `FLUTTER_VERSION` in CI configuration
   - Ensure local and CI Flutter versions match

4. **API Endpoint Issues**
   - Verify environment-specific endpoints
   - Check API server status

### Support

For CI/CD issues:
- Check build logs in Bitrise/GitHub Actions
- Review Fastlane output
- Contact DevOps team

## 📚 Additional Resources

- [Bitrise Documentation](https://devcenter.bitrise.io/)
- [GitHub Actions for Flutter](https://docs.github.com/en/actions)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Flutter Build & Release](https://flutter.dev/docs/deployment/cd)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)