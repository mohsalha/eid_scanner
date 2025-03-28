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
  eid_scanner: ^0.0.5
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
Check the `example/` directory for a full implementation of the package in use.

## Repository
The source code for this package is hosted on GitHub:
[GitHub Repository](https://github.com/amjadHamdoun/eid_scanner)

## Metadata
- **Package Name:** eid_scanner
- **Version:** 0.0.5
- **Author:** Amjad Hamdoun
- **License:** Apache-2.0
- **Repository:** [GitHub Repository](https://github.com/amjadHamdoun/eid_scanner)

## Contributing

We welcome contributions to this project! Please follow the guidelines below to get started:

1. Fork the repository.
2. Create a new branch (`git checkout -b feature-branch`).
3. Make your changes.
4. Run the tests (`flutter test`).
5. Submit a pull request.

For more details, see the [Contributing Guide](https://github.com/amjadHamdoun/eid_scanner/blob/main/CONTRIBUTING.md).

## License
This package is licensed under the Apache-2.0 License. See [LICENSE](https://github.com/amjadHamdoun/eid_scanner/blob/main/LICENSE) for more details.