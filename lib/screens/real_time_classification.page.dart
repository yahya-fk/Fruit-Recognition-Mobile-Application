import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../widgets/app_drawer.dart';

class RealtimeClassificationScreen extends StatefulWidget {
  @override
  _RealtimeClassificationScreenState createState() =>
      _RealtimeClassificationScreenState();
}

class _RealtimeClassificationScreenState
    extends State<RealtimeClassificationScreen> {
  late Interpreter _interpreter;
  late List<String> _classNames;
  String _predictionResult = "";
  double _confidence = 0.0;
  bool _isProcessing = false;

  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
    _initializeCamera();
  }

  Future<void> _loadModelAndLabels() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model/model.tflite');
      _classNames = [
        'orange',
        'apple',
        'banana',
        'dragon',
        'grapes',
        'lemon',
        'mango',
        'papaya',
        'pineapple',
        'pomegranate',
        'strawberry'
      ];
    } catch (e) {
      print("Error loading model or labels: $e");
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController?.initialize();

    if (!mounted) return;

    setState(() {
      _isCameraInitialized = true;
    });

    // Start continuous classification
    _startClassification();
  }

  Future<void> _startClassification() async {
    if (_cameraController == null) return;

    while (_isCameraInitialized) {
      if (!_isProcessing) {
        _isProcessing = true;
        try {
          final image = await _cameraController!.takePicture();
          await _classifyImage(image);
        } catch (e) {
          print("Error capturing image: $e");
        }
        _isProcessing = false;
      }
      await Future.delayed(
          Duration(milliseconds: 500)); // Adjust delay as needed
    }
  }

  Future<void> _classifyImage(XFile imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) return;

      // Resize image to 32x32
      final resizedImage = img.copyResize(image, width: 32, height: 32);

      // Create buffer for input tensor
      var inputBuffer = List.filled(1 * 32 * 32 * 3, 0.0);
      var inputShape = [1, 32, 32, 3];

      // Fill input buffer with normalized pixel values
      var pixelIndex = 0;
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          final pixel = resizedImage.getPixel(x, y);
          inputBuffer[pixelIndex] = img.getRed(pixel) / 255.0;
          inputBuffer[pixelIndex + 1] = img.getGreen(pixel) / 255.0;
          inputBuffer[pixelIndex + 2] = img.getBlue(pixel) / 255.0;
          pixelIndex += 3;
        }
      }

      // Prepare output buffer
      var outputBuffer = List.filled(1 * _classNames.length, 0.0);
      var outputShape = [1, _classNames.length];

      // Run inference
      _interpreter.run(
        inputBuffer.reshape(inputShape),
        outputBuffer.reshape(outputShape),
      );

      int classIndex = 0;
      double confidence = outputBuffer[0];

      for (var i = 0; i < _classNames.length; i++) {
        if (outputBuffer[i] > confidence) {
          confidence = outputBuffer[i];
          classIndex = i;
        }
      }

      setState(() {
        _predictionResult = _classNames[classIndex];
        _confidence = confidence;
      });
    } catch (e) {
      print("Error during classification: $e");
    }
  }

  @override
  void dispose() {
    _isCameraInitialized = false;
    _cameraController?.dispose();
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double safeAreaPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "REAL-TIME CLASSIFIER",
          style: TextStyle(
            color: Colors.white,
            fontSize: screenSize.width * 0.06,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amber.shade400,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
      ),
      drawer: AppDrawer(),
      body: SafeArea(
        child: Container(
          width: screenSize.width,
          height: screenSize.height - safeAreaPadding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.amber.shade100,
                Colors.white,
              ],
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: _isCameraInitialized
                    ? AspectRatio(
                        aspectRatio: _cameraController!.value.aspectRatio,
                        child: CameraPreview(_cameraController!),
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
              ),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Prediction: $_predictionResult',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.05,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: screenSize.width * 0.04,
                        color: Colors.amber.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
