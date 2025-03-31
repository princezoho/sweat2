# Step Count Integration

This document outlines the implementation of step count tracking in the SweatPet app using the Health API.

## Overview

The app integrates with:
- Apple HealthKit on iOS
- Google Fit on Android

This allows the app to:
1. Request permission to access the user's step count data
2. Retrieve the current day's step count
3. Feed this data to the pet evolution system

## Implementation

### Architecture

The implementation follows a service-based architecture:

1. **HealthService** - Handles communication with the platform-specific health APIs
2. **HealthStepInput** - UI widget that displays the data and allows adding steps to the game
3. **Permission handling** - Setup for both iOS and Android platforms

### Files

- `lib/services/health_service.dart` - Core service for health data access
- `lib/widgets/health_step_input.dart` - UI widget for displaying health data
- `ios/Runner/Info.plist` - iOS HealthKit permission setup
- `android/app/src/main/AndroidManifest.xml` - Android activity recognition permission

### Dependencies

- `health: ^9.0.0` - Main package for health data access
- `permission_handler: ^11.0.0` - For handling permission requests

## Usage

Users can:
1. Connect the app to their Health app data
2. View their current day's step count
3. Add those steps to their pet's progress
4. Refresh the step count data at any time

## Technical Notes

### iOS HealthKit Integration

iOS requires specific entitlements and usage descriptions in Info.plist:

```xml
<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to count steps and track your progress.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We need access to your health data to count steps and track your progress.</string>
```

The app also needs the HealthKit capability added to the project.

### Android Google Fit Integration

Android requires:

```xml
<uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />
```

### Health Data Access

Steps are retrieved using:

```dart
final steps = await _health.getTotalStepsInInterval(start, end);
```

## Future Improvements

1. Background step syncing
2. Step history visualization
3. Weekly/monthly step goals
4. More detailed fitness metrics integration 