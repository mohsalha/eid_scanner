part of eid_scanner;

/// A widget that allows users to scan an Emirates ID using the device's camera.
class EIDScannerCamera extends StatefulWidget {
  /// Callback function that is triggered when the Emirates ID is successfully scanned.
  /// The scanned data is passed as an `EmirateIdModel` object.
  final Function(EmirateIdModel?) onScanned;

  /// Creates an [EIDScannerCamera] widget.
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

  Rect? _scanBox;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _textRecognizer = GoogleMlKit.vision.textRecognizer();
  }

  /// Initializes the camera and sets up the camera controller to start image stream.
  /// This function also sets the initial scan box position and size.
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
  /// This ensures the scan box is centered and scaled according to the device's screen size.
  void _calculateScanBox() {
    final size = MediaQuery.of(context).size;
    double boxWidth = size.width * 0.8;
    double boxHeight = size.height * 0.3;
    double left = (size.width - boxWidth) / 2;
    double top = (size.height - boxHeight) / 2;
    _scanBox = Rect.fromLTWH(left, top, boxWidth, boxHeight);
  }

  /// Starts the image stream from the camera, processes each frame, and looks for Emirates ID.
  /// This function is responsible for handling the scanning state and calling the image processing method.
  void _startImageStream() {
    _cameraController?.startImageStream((CameraImage image) async {
      if (!_isProcessing) {
        _isProcessing = true;
        await _processImage(image);
        _isProcessing = false;
      }
    });
  }

  /// Processes the captured image to detect Emirates ID text and determine if it matches the required criteria.
  /// The scanning state is updated based on whether the ID is detected or not.
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
    String feedbackMessage = "Align the ID properly inside the box";

    for (TextBlock block in recognizedText.blocks) {
      final Rect boundingBox = block.boundingBox;

      // ✅ Check if the text block is INSIDE the scan box
      if (_scanBox!.contains(boundingBox.center)) {
        print("Text inside box: ${block.text}");

        if (block.text.toLowerCase().contains("resident identity card") ||
            block.text.toLowerCase().contains("united arab emirates") ||
            block.text.length > 10) {
          idDetected = true;
          break;
        }
      }
    }

    // 🔥 Enhanced User Messages Based on ID Detection
    if (idDetected) {
      _scanCount++;
      if (_scanCount >= 3) {
        feedbackMessage = "ID detected! Capturing...";
        _cameraController?.stopImageStream();
        final String imagePath = await _captureImage();
        final File imageFile = File(imagePath);
        final scannedData = await EIDScanner.scanEmirateId(
            sourceType: ImageSourceType.file, file: imageFile);
        widget.onScanned(scannedData);
        Navigator.pop(context);
      } else {
        feedbackMessage = "ID detected, hold steady...";
      }
    } else {
      _scanCount = 0;

      // 🔹 Improve error messages based on positioning issues
      if (recognizedText.blocks.isEmpty) {
        feedbackMessage = "No text detected. Ensure the ID is clearly visible.";
      } else {
        // 🔹 Check if ID is outside the scan box
        bool isOutsideBox = recognizedText.blocks
            .any((block) => !_scanBox!.contains(block.boundingBox.center));
        if (isOutsideBox) {
          feedbackMessage = "Move the ID inside the box.";
        }
      }
    }

    setState(() {
      _message = feedbackMessage;
    });

    _isScanning = false;
  }

  /// Captures an image from the camera and returns its file path.
  /// This function saves the captured image temporarily and returns the path to the file.
  Future<String> _captureImage() async {
    final Directory tempDir = await getTemporaryDirectory();
    final String imagePath = '${tempDir.path}/eid_scan.jpg';
    await _cameraController?.takePicture();
    return imagePath;
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
