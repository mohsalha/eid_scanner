import 'package:eid_scanner/eid_scanner.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmiratesIdScannerExample(),
    );
  }
}

class EmiratesIdScannerExample extends StatefulWidget {
  @override
  _EmiratesIdScannerExampleState createState() => _EmiratesIdScannerExampleState();
}

class _EmiratesIdScannerExampleState extends State<EmiratesIdScannerExample> {
  XFile? _pickedFile;
  CroppedFile? _croppedFile;

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(

        sourcePath: _pickedFile!.path,

        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Select Pic',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            activeControlsWidgetColor: Colors.blue,
            lockAspectRatio: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
          IOSUiSettings(
            title: 'Select Pic',
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ],
          ),
        ],
      );
      if (croppedFile != null) {
        _croppedFile = croppedFile;
        // ignore: use_build_context_synchronously
        EmirateIdModel? data = await EIDScanner.scanEmirateId(image: File(_croppedFile!.path));
        setState(() {
          scannedData = data;
          isScanning = false;
        });

      }
    }
    else{

    }
  }

  Future<void> _selectImage(ImageSource imageSource) async {
    final pickedFile =
    await ImagePicker().pickImage(source: imageSource);
    if (pickedFile != null) {
      _pickedFile = pickedFile;
      _cropImage();
    }
  }

  EmirateIdModel? scannedData;
  bool isScanning = false;

  Future<void> _scanEIDCard() async {
    Navigator.push(context, MaterialPageRoute(builder: (context) => EIDScannerCamera(onScanned: (data) {
      scannedData = data;
    })));
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Emirates ID Scanner Example')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: isScanning ? null : (){
                _selectImage(ImageSource.gallery);
              },
              child: Text(isScanning ? 'Scanning...' : 'Gallery'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isScanning ? null : (){
                _selectImage(ImageSource.camera);
              },
              child: Text(isScanning ? 'Scanning...' : 'Camera'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isScanning ? null : _scanEIDCard,
              child: Text(isScanning ? 'Scanning...' : 'Scan Emirates ID'),
            ),
            SizedBox(height: 20),
            scannedData != null
                ? Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  scannedData.toString(),
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
                : Text('No data scanned yet.'),
          ],
        ),
      ),
    );
  }
}
