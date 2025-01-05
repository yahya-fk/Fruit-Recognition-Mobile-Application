import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
        'apple',
        'banana',
        'dragon',
        'grapes',
        'lemon',
        'mango',
        'orange',
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
      if (_classNames.isEmpty) {
        throw Exception("Labels not loaded");
      }

      img.Image? imageInput = img.decodeImage(imageFile.readAsBytesSync());
      if (imageInput == null) {
        setState(() {
          _predictionResult = "Invalid image. Please try again.";
        });
        return;
      }

      img.Image resizedImage =
          img.copyResize(imageInput, width: 32, height: 32);

      List<double> input = [];
      for (int y = 0; y < resizedImage.height; y++) {
        for (int x = 0; x < resizedImage.width; x++) {
          final pixel = resizedImage.getPixel(x, y);
          input.add(img.getRed(pixel) / 255.0);
          input.add(img.getGreen(pixel) / 255.0);
          input.add(img.getBlue(pixel) / 255.0);
        }
      }

      var inputTensor = [input];
      var outputTensor =
          List.filled(_classNames.length, 0.0).reshape([1, _classNames.length]);

      _interpreter.run(inputTensor, outputTensor);

      var confidences = outputTensor[0];
      int classIndex = confidences.indexWhere(
          (value) => value == confidences.reduce((a, b) => a > b ? a : b));
      double confidence = confidences[classIndex];

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
    return Scaffold(
      appBar: AppBar(title: Text('CNN Model Classification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Upload an image to classify',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick an Image'),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator()
            else if (_image != null)
              Column(
                children: [
                  Image.file(_image!, height: 200),
                  SizedBox(height: 20),
                  Text(
                    'Prediction: $_predictionResult',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Confidence: ${(_confidence * 100).toStringAsFixed(2)}%',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
