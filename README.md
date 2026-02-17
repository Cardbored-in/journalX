# JournalX - Your Personal Life Companion

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Android-brightgreen?style=for-the-badge&logo=android" alt="Platform">
  <img src="https://img.shields.io/badge/Framework-Flutter-blue?style=for-the-badge&logo=flutter" alt="Framework">
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License">
</p>

---

## 📱 About JournalX

**JournalX** is a personal all-in-one lifestyle app designed to help you track and record your daily life. It's an offline-first personal hub for self-reflection, lifestyle logging, and utility management.

## 🤔 Why I Built JournalX

We live in a world where we use multiple apps for different purposes - one for tracking expenses, another for logging meals, yet another for taking notes. This fragmentation makes it difficult to maintain a holistic view of our lives.

**JournalX was built to solve this problem** by providing a single, unified app that helps you:

1. **Track Expenses** - Never forget where your money went
2. **Log Meals** - Remember what you ate and when
3. **Capture Thoughts** - Save shayari, quotes, and personal notes
4. **Detect Payments** - Get reminded to log expenses when you make payments

The app is designed to be **privacy-first** - all your data stays on your device. No cloud, no accounts, no tracking.

## ✨ Key Features

### 💰 Expense Tracker
- **Configurable Categories** - Add your own custom expense categories with personalized icons
- **Multiple Payment Modes** - Track Cash, UPI, and Credit Card payments with last 4 digits for identification
- **Smart Detection** - Get notified when you open payment apps like GPay or PhonePe to quickly log expenses
- **Search & Filter** - Find expenses by category or description

### 🍽️ Food Logger
- **Photo Capture** - Snap pictures of your meals
- **Chef's Notes** - Add personal notes about the dish
- **Meal History** - Browse your culinary journey

### 📝 Shayari & Notes
- **Mood Tracking** - Tag your entries with moods
- **Quick Capture** - Fast way to save thoughts, quotes, and shayari
- **Search** - Find your saved notes instantly

### ⚙️ Settings
- **Currency Config** - Support for multiple currencies (₹, $, €, £, ¥, etc.)
- **App Detection** - Toggle payment app detection on/off
- **Data Privacy** - All data stored locally

## 🏗️ Architecture

- **Framework**: Flutter (Dart)
- **Database**: SQLite (sqflite) - Local, offline-first storage
- **State Management**: StatefulWidget with async data loading
- **Architecture Pattern**: Feature-based folder structure

```
lib/
├── core/
│   └── theme/           # App theming (Material Design 3)
├── data/
│   ├── database/        # SQLite database helper
│   └── models/          # Data models (Expense, Meal, Note, etc.)
├── features/
│   ├── expense_tracker/  # Expense tracking feature
│   ├── food_logger/     # Food/meal logging feature
│   ├── search/          # Global search feature
│   ├── settings/        # App settings
│   └── shayari_notes/   # Notes & shayari feature
└── services/
    └── notification_service.dart  # Local notifications
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android SDK

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/journalX.git
cd journalX
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building APK

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/`

## 📱 Play Store Readiness

This app is configured for Google Play Store submission:

- ✅ Proper AndroidManifest with required permissions
- ✅ Accessibility Service disclosure (required for app detection feature)
- ✅ Core library desugaring enabled
- ✅ Target Android API 34
- ✅ Privacy-focused (local-only data)
