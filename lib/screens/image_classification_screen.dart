import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../widgets/app_drawer.dart';

class ImageClassificationScreen extends StatefulWidget {
  @override
  _ImageClassificationScreenState createState() =>
      _ImageClassificationScreenState();
}
class _ImageClassificationScreenState extends State<ImageClassificationScreen> {
  late Interpreter _interpreter;
  late List<String> _classNames;
  String _predictionResult = "";
  double _confidence = 0.0;
  File? _image;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadModelAndLabels();
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

  Future<void> _classifyImage(File imageFile) async {
    try {
      print("Starting image classification");

      if (_classNames.isEmpty) {
        throw Exception("Labels not loaded");
      }

      final imageBytes = await imageFile.readAsBytes();
      print("Image bytes loaded");

      final image = img.decodeImage(imageBytes);
      if (image == null) {
        throw Exception('Failed to decode image file');
      }
      print("Image decoded : $image");

      // Resize image to 32x32
      final resizedImage = img.copyResize(image, width: 32, height: 32);
      print("Image resized to 32x32 : $resizedImage");

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
      print("Input buffer filled with normalized pixel values");

      // Prepare output buffer
      var outputBuffer = List.filled(1 * _classNames.length, 0.0);
      var outputShape = [1, _classNames.length];

      // Run inference
      print("Running inference");
      _interpreter.run(
        inputBuffer.reshape(inputShape),
        outputBuffer.reshape(outputShape),
      );
      print("Inference completed");

      int classIndex = 0;
      double confidence = outputBuffer[0];

      for (var i = 0; i < _classNames.length; i++) {
        if (outputBuffer[i] > confidence) {
          confidence = outputBuffer[i];
          classIndex = i;
        }
      }
      print("Classification result: ${_classNames[classIndex]} with confidence $confidence");

      setState(() {
        _predictionResult = _classNames[classIndex];
        _confidence = confidence;
      });
    } catch (e) {
      print("Error during classification: $e");
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
        _isLoading = true;
      });

      await _classifyImage(_image!);

      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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
          "CLASSIFIER",
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
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(screenSize.width * 0.05),
              child: Column(
                children: [
                  SizedBox(height: screenSize.height * 0.02),
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(screenSize.width * 0.05),
                      child: Column(
                        children: [
                          Text(
                            'Fruit Classification',
                            style: TextStyle(
                              fontSize: screenSize.width * 0.06,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          SizedBox(height: screenSize.height * 0.02),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Select Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade400,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenSize.width * 0.05,
                                vertical: screenSize.width * 0.03,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenSize.height * 0.02),
                  if (_isLoading)
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    )
                  else if (_image != null)
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(screenSize.width * 0.05),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(_image!, height: screenSize.height * 0.25),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Container(
                              padding: EdgeInsets.all(screenSize.width * 0.03),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                  width: 1,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
