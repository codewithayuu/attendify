# Attendance Tracker App

A comprehensive Flutter application for tracking student attendance with offline-first approach, beautiful analytics, and modern UI design.

## Features

### 📊 Core Functionality

- **Subject Management**: Add, edit, and delete subjects with custom colors
- **Attendance Tracking**: Mark present/absent/late/excused with one tap
- **Offline-First**: All data stored locally using Hive database
- **Real-time Calculations**: Automatic attendance percentage calculations
- **Smart Thresholds**: Configurable warning thresholds (default 75%)

### 📈 Analytics & Insights

- **Beautiful Charts**: Pie charts and trend graphs using fl_chart
- **Weekly/Monthly Reports**: Detailed attendance statistics
- **30-Day Trends**: Visual attendance patterns over time
- **Subject Breakdown**: Individual subject performance analysis

### 🎨 Modern UI/UX

- **Material 3 Design**: Latest Material Design principles
- **Dark Mode Support**: Toggle between light and dark themes
- **Smooth Animations**: Flutter Animate for delightful interactions
- **Responsive Design**: Optimized for all screen sizes
- **Gradient Cards**: Beautiful gradient backgrounds for status indicators

### 🔔 Smart Notifications

- **Daily Reminders**: Configurable time for attendance reminders
- **Low Attendance Alerts**: Warnings when attendance drops below threshold
- **Weekly Summaries**: Automated weekly performance reports
- **Monthly Reports**: Comprehensive monthly attendance analysis

### ☁️ Cloud Sync (Optional)

- **Firebase Integration**: Optional cloud backup with Firestore
- **Real-time Sync**: Automatic synchronization across devices
- **Offline Resilience**: Works seamlessly without internet connection

### 📤 Data Management

- **Export Options**: CSV and Excel export functionality
- **Import Support**: Import data from external sources
- **Backup & Restore**: Complete data backup and restoration
- **Data Security**: Local-first approach ensures privacy

## Tech Stack

### Frontend

- **Flutter**: Cross-platform mobile development
- **Dart**: Programming language
- **Material 3**: Modern UI design system

### State Management

- **Riverpod**: Reactive state management
- **Provider Pattern**: Clean architecture with providers

### Local Database

- **Hive**: Fast, lightweight NoSQL database
- **Type Adapters**: Type-safe data serialization

### Cloud Services (Optional)

- **Firebase Auth**: User authentication
- **Cloud Firestore**: Cloud database
- **Real-time Sync**: Live data synchronization

### Charts & Analytics

- **fl_chart**: Beautiful and responsive charts
- **Custom Widgets**: Tailored chart components

### Notifications

- **awesome_notifications**: Local notification system
- **Scheduled Notifications**: Time-based reminders

### Animations

- **flutter_animate**: Smooth and performant animations
- **Lottie**: Vector animations (ready for implementation)

### Data Export

- **CSV**: Comma-separated values export
- **Excel**: Microsoft Excel file generation
- **Share Plus**: Native sharing functionality

## Project Structure

```
lib/
├── models/                 # Data models
│   ├── subject.dart       # Subject data model
│   ├── attendance_record.dart # Attendance record model
│   └── app_settings.dart  # App settings model
├── services/              # Business logic services
│   ├── hive_service.dart  # Local database operations
│   ├── firebase_service.dart # Cloud sync operations
│   ├── notification_service.dart # Notification management
│   └── export_service.dart # Data export functionality
├── providers/             # State management
│   ├── subject_provider.dart # Subject state management
│   ├── attendance_provider.dart # Attendance state management
│   └── settings_provider.dart # Settings state management
├── screens/               # App screens
│   ├── home_screen.dart   # Main dashboard
│   ├── add_subject_screen.dart # Add/edit subjects
│   ├── analytics_screen.dart # Analytics dashboard
│   └── settings_screen.dart # App settings
├── widgets/               # Reusable UI components
│   ├── subject_card.dart  # Subject display card
│   ├── attendance_summary_card.dart # Summary statistics
│   ├── quick_actions.dart # Quick attendance actions
│   ├── empty_state_widget.dart # Empty state display
│   ├── attendance_chart.dart # Chart components
│   └── attendance_trend_chart.dart # Trend visualization
├── utils/                 # Utility functions
│   └── app_theme.dart     # Theme configuration
└── main.dart              # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio / VS Code / Cursor
- Android device or emulator

### Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd attendance_tracker
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run code generation** (if needed)

   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup (Optional)

1. **Create Firebase project**

   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication and Firestore

2. **Add configuration files**

   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`

3. **Enable cloud sync**
   - Open app settings
   - Toggle "Cloud Sync" option
   - Sign in with your account

## Usage

### Adding Subjects

1. Tap the "+" button on the home screen
2. Enter subject name and description
3. Choose a color for the subject
4. Tap "Add Subject"

### Marking Attendance

1. On the home screen, find your subject
2. Tap "Present" or "Absent" button
3. Attendance is automatically calculated and updated

### Viewing Analytics

1. Navigate to the "Analytics" tab
2. View overall statistics and trends
3. Check weekly and monthly reports
4. Analyze subject-wise performance

### Configuring Settings

1. Go to the "Settings" tab
2. Toggle dark mode, notifications, etc.
3. Set notification time and attendance threshold
4. Configure cloud sync preferences

### Exporting Data

1. Go to Settings > Data Management
2. Choose "Export Data"
3. Select CSV or Excel format
4. Share or save the exported file

## Key Features Explained

### Offline-First Architecture

- All data is stored locally using Hive database
- App works without internet connection
- Cloud sync is optional and runs in background
- Data is always available and fast to access

### Smart Notifications

- Daily reminders at configurable time
- Low attendance warnings
- Weekly and monthly summaries
- Respects user preferences and settings

### Beautiful Analytics

- Pie charts for attendance distribution
- Line charts for trend analysis
- Color-coded status indicators
- Responsive and interactive charts

### Modern UI Design

- Material 3 design system
- Smooth animations and transitions
- Dark mode support
- Gradient backgrounds and modern cards

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email support@attendancetracker.com or create an issue in the repository.

## Roadmap

### Upcoming Features

- [ ] Lottie animations for empty states
- [ ] Advanced filtering and search
- [ ] Custom attendance statuses
- [ ] Attendance history editing
- [ ] Multiple user profiles
- [ ] Advanced analytics and insights
- [ ] Integration with calendar apps
- [ ] Voice commands for attendance marking
- [ ] Widget support for quick access
- [ ] Backup to Google Drive/Dropbox

### Performance Improvements

- [ ] Lazy loading for large datasets
- [ ] Image optimization
- [ ] Memory usage optimization
- [ ] Faster chart rendering
- [ ] Improved sync performance

---

**Built with ❤️ using Flutter**

