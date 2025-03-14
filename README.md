# Emirates ID Scanner

A Flutter package for detecting and scanning Emirates ID cards using the device camera. The package utilizes Google ML Kit for text recognition and object detection to ensure accurate ID card scanning before extracting text data.

## Features
- Real-time camera preview with ID detection
- Automatic capture when the ID is properly positioned
- Text recognition to extract Emirates ID details
- Bounding box for accurate scanning
- Lightweight and easy to integrate

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  eid_scanner: ^0.0.1
```

Then, run:

```sh
flutter pub get
```

## Permissions

Make sure to add camera permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

For iOS, add these to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan your Emirates ID.</string>
```

## Example App

Check the `example/` directory for a full implementation.

## Contributing

Pull requests are welcome! If you encounter any issues, please open an issue on the repository.

## License

MIT License. See `LICENSE` for more details.

#   e i d _ s c a n n e r 
 
 