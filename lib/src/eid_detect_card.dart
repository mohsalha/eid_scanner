part of eid_scanner;

/// A widget that allows users to scan an Emirates ID using the device's camera.
class EIDDetectCard extends StatefulWidget {
  /// Callback function that is triggered when the Emirates ID is successfully scanned.
  /// The scanned data is passed as an `EmirateIdModel` object.
  final Function(EmirateIdModel?) onScanned;

  /// Creates an [EIDDetectCard] widget.
  const EIDDetectCard({Key? key, required this.onScanned}) : super(key: key);

  @override
  _EIDDetectCardState createState() => _EIDDetectCardState();
}

class _EIDDetectCardState extends State<EIDDetectCard> {
  CameraController? _cameraController;
  bool _isProcessing = false;
  bool _isScanning = false;
  String _message = "Position the ID inside the box";
  int _scanCount = 0;

  Rect? _scanBox;
  late ObjectDetector _objectDetector;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _objectDetector = GoogleMlKit.vision.objectDetector(
      options: ObjectDetectorOptions(
        classifyObjects: false,
        multipleObjects: false,
        mode: DetectionMode.stream,
      ),
    );
  }

  /// Initializes the camera and sets up the camera controller to start the image stream.
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup:
          Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
    );
    await _cameraController?.initialize();
    if (mounted) {
      setState(() {
        _calculateScanBox();
      });
    }
    _startImageStream();
  }

  /// Calculates the scan box area where the Emirates ID should be placed for scanning.
  void _calculateScanBox() {
    final size = MediaQuery.of(context).size;
    double boxWidth = size.width * 0.8;
    double boxHeight = size.height * 0.3;
    double left = (size.width - boxWidth) / 2;
    double top = (size.height - boxHeight) / 2;
    _scanBox = Rect.fromLTWH(left, top, boxWidth, boxHeight);
  }

  /// Starts the image stream from the camera, processes each frame, and looks for the Emirates ID.
  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (!_isProcessing) {
        _isProcessing = true;
        await _processImage(image);
        _isProcessing = false;
      }
    });
  }

  /// Processes the captured image to detect an ID card and determines if it matches the required criteria.
  Future<void> _processImage(CameraImage image) async {
    if (_isScanning || _scanBox == null) return;
    _isScanning = true;

    final InputImage inputImage = _convertCameraImageToInputImage(image);

    // 🔥 Detect objects (ID card)
    final List<DetectedObject> detectedObjects =
        await _objectDetector.processImage(inputImage);

    bool idDetected = false;
    Rect? idBoundingBox;

    for (DetectedObject obj in detectedObjects) {
      if (obj.boundingBox.width > 100 && obj.boundingBox.height > 50) {
        // Ensure the bounding box dimensions are appropriate for an ID card
        idDetected = true;
        idBoundingBox = obj.boundingBox;
        break;
      }
    }

    if (idDetected &&
        idBoundingBox != null &&
        _scanBox!.contains(idBoundingBox.center)) {
      _scanCount++;
      setState(() {
        _message = "ID detected, hold steady...";
      });

      if (_scanCount >= 3) {
        _cameraController?.stopImageStream();
        final String imagePath = await _captureImage();
        final File imageFile = File(imagePath);
        final scannedData = await EIDScanner.scanEmirateId(
            sourceType: ImageSourceType.file, file: imageFile);
        widget.onScanned(scannedData);
        Navigator.pop(context);
      }
    } else {
      _scanCount = 0;
      setState(() {
        _message = "Position the ID properly inside the box";
      });
    }

    _isScanning = false;
  }

  /// Converts CameraImage to InputImage format for processing with the Object Detector.
  InputImage _convertCameraImageToInputImage(CameraImage image) {
    final WriteBuffer buffer = WriteBuffer();
    for (var plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    final bytes = buffer.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  /// Captures an image from the camera and returns its file path.
  Future<String> _captureImage() async {
    final Directory tempDir = await getTemporaryDirectory();
    final String imagePath = '${tempDir.path}/eid_scan.jpg';
    await _cameraController?.takePicture();
    return imagePath;
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _objectDetector.close();
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
