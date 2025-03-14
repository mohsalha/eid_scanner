

part of eid_scanner;

class EIDScannerCamera extends StatefulWidget {
  final Function(EmirateIdModel?) onScanned;

  const EIDScannerCamera({Key? key, required this.onScanned}) : super(key: key);

  @override
  _EIDScannerCameraState createState() => _EIDScannerCameraState();
}

class _EIDScannerCameraState extends State<EIDScannerCamera> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  late TextRecognizer _textRecognizer;
  bool _isScanning = false;
  String _message = "Position the ID inside the box";
  int _scanCount = 0;

  final GlobalKey _cameraPreviewKey = GlobalKey();
  Rect? _scanBox;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
    await _cameraController?.initialize();
    if (mounted) {
      setState(() {
        _calculateScanBox();
      });
    }
    _startImageStream();
  }

  void _calculateScanBox() {
    final size = MediaQuery.of(context).size;
    double boxWidth = size.width * 0.8;
    double boxHeight = size.height * 0.3;
    double left = (size.width - boxWidth) / 2;
    double top = (size.height - boxHeight) / 2;
    _scanBox = Rect.fromLTWH(left, top, boxWidth, boxHeight);
  }

  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (!_isProcessing) {
        _isProcessing = true;
        await _processImage(image);
        _isProcessing = false;
      }
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isScanning || _scanBox == null) return;
    _isScanning = true;

    final WriteBuffer buffer = WriteBuffer();
    for (var plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    final InputImage inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final RecognizedText recognizedText =
    await _textRecognizer.processImage(inputImage);

    bool idDetected = false;
    for (TextBlock block in recognizedText.blocks) {
      print("Block Text: ${block.text}");

      if (block.text.toLowerCase().contains("resident identity card") ||
          block.text.toLowerCase().contains("united arab emirates")||block.text.length>10) {
        final Rect boundingBox = block.boundingBox;

        if (_scanBox!.contains(boundingBox.center)) {
          idDetected = true;
          break;
        }
      }
    }

    if (idDetected) {
      _scanCount++;

      if (_scanCount >= 3) {
        setState(() {
          _message = "ID detected inside the box! Capturing...";
        });

        _cameraController?.stopImageStream();
        final String imagePath = await _captureImage();
        final File imageFile = File(imagePath);
        final scannedData = await EIDScanner.scanEmirateId(image: imageFile);
        widget.onScanned(scannedData);
        Navigator.pop(context);
      } else {
        setState(() {
          _message = "ID detected, hold steady...";
        });
      }
    } else {
      setState(() {
        _message = "Align the ID properly within the box";
      });
      _scanCount = 0;
    }

    _isScanning = false;
  }

  Future<String> _captureImage() async {
    final Directory tempDir = await getTemporaryDirectory();
    final String imagePath = '${tempDir.path}/eid_scan.jpg';
    await _cameraController?.takePicture();
    return imagePath;
  }

  Future<File> _captureAndCropImage() async {
    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final File file = File(imageFile.path);

      // Decode image for cropping
      final img.Image fullImage = img.decodeImage(await file.readAsBytes())!;

      // Convert scan box coordinates to image coordinates
      final double scaleX = fullImage.width / MediaQuery.of(context).size.width;
      final double scaleY = fullImage.height / MediaQuery.of(context).size.height;

      final int cropX = (_scanBox!.left * scaleX).toInt();
      final int cropY = (_scanBox!.top * scaleY).toInt();
      final int cropWidth = (_scanBox!.width * scaleX).toInt();
      final int cropHeight = (_scanBox!.height * scaleY).toInt();

      // Crop the image
      final img.Image croppedImage =
      img.copyCrop(fullImage,  cropX,  cropY,  cropWidth, cropHeight);

      // Save the cropped image
      final Directory tempDir = await getTemporaryDirectory();
      final String croppedPath = '${tempDir.path}/eid_cropped.jpg';
      await File(croppedPath).writeAsBytes(img.encodeJpg(croppedImage));

      return File(croppedPath);
    } catch (e) {
      debugPrint("Error capturing/cropping image: $e");
      return File('');
    }
  }


  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Scan Emirates ID")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          CameraPreview(_cameraController!),
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ScanBoxPainter(_scanBox),
          ),
          Positioned(
            bottom: 50,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                _message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScanBoxPainter extends CustomPainter {
  final Rect? scanBox;

  ScanBoxPainter(this.scanBox);

  @override
  void paint(Canvas canvas, Size size) {
    if (scanBox == null) return;

    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint borderPaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint overlayPaint = Paint()
      ..color = Colors.black.withOpacity(0.5);

    // Draw dark overlay outside the scan box
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRect(scanBox!),
    );

    canvas.drawPath(path, overlayPaint);

    // Draw scan box
    canvas.drawRect(scanBox!, paint);

    // Draw corner lines
    double cornerLength = 30;
    double strokeWidth = 4;

    // Top-left corner
    canvas.drawLine(scanBox!.topLeft,
        scanBox!.topLeft.translate(cornerLength, 0), borderPaint);
    canvas.drawLine(scanBox!.topLeft,
        scanBox!.topLeft.translate(0, cornerLength), borderPaint);

    // Top-right corner
    canvas.drawLine(scanBox!.topRight,
        scanBox!.topRight.translate(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanBox!.topRight,
        scanBox!.topRight.translate(0, cornerLength), borderPaint);

    // Bottom-left corner
    canvas.drawLine(scanBox!.bottomLeft,
        scanBox!.bottomLeft.translate(cornerLength, 0), borderPaint);
    canvas.drawLine(scanBox!.bottomLeft,
        scanBox!.bottomLeft.translate(0, -cornerLength), borderPaint);

    // Bottom-right corner
    canvas.drawLine(scanBox!.bottomRight,
        scanBox!.bottomRight.translate(-cornerLength, 0), borderPaint);
    canvas.drawLine(scanBox!.bottomRight,
        scanBox!.bottomRight.translate(0, -cornerLength), borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
