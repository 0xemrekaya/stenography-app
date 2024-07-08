import 'dart:typed_data';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_package;
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Steganography App',
      theme: FlexThemeData.light(
        scheme: FlexScheme.materialHc,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 7,
        subThemesData: const FlexSubThemesData(
          blendOnLevel: 10,
          blendOnColors: false,
          useTextTheme: true,
          useM2StyleDividerInM3: true,
          alignedDropdown: true,
          useInputDecoratorThemeInDialogs: true,
        ),
        keyColors: const FlexKeyColors(
          useSecondary: true,
        ),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        useMaterial3: true,
        swapLegacyOnMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
          scheme: FlexScheme.materialHc,
          surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
          blendLevel: 13,
          subThemesData: const FlexSubThemesData(
            blendOnLevel: 20,
            useTextTheme: true,
            useM2StyleDividerInM3: true,
            alignedDropdown: true,
            useInputDecoratorThemeInDialogs: true,
          ),
          keyColors: const FlexKeyColors(
            useSecondary: true,
          )),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final picker = ImagePicker();
  File? _image;
  String _message = '';
  String _key = '';
  String _decodedMessage = '';
  bool _isKeyAvailable = false;

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Uint8List _encodeMessage(String message, img.Image image) {
    var messageBytes = Uint8List.fromList(utf8.encode(message));
    var lengthBytes = Uint8List(4)..buffer.asByteData().setUint32(0, messageBytes.length, Endian.big);
    var allBytes = Uint8List.fromList([...lengthBytes, ...messageBytes]);

    if (allBytes.length * 8 > image.length) {
      throw ArgumentError('Message is too long for image.');
    }

    for (var i = 0; i < allBytes.length; i++) {
      for (var bit = 0; bit < 8; bit++) {
        var mask = 1 << bit;
        var pixelIndex = i * 8 + bit;
        if ((allBytes[i] & mask) != 0) {
          image[pixelIndex] |= 1; // Set LSB to 1
        } else {
          image[pixelIndex] &= ~1; // Set LSB to 0
        }
      }
    }

    return Uint8List.fromList(img.encodePng(image));
  }

  String _decodeMessage(img.Image image) {
    var lengthBytes = Uint8List(4);
    for (var i = 0; i < 32; i++) {
      if ((image[i] & 1) != 0) {
        lengthBytes[i ~/ 8] |= 1 << (i % 8);
      }
    }

    var messageLength = lengthBytes.buffer.asByteData().getUint32(0, Endian.big);
    if (messageLength * 8 > image.length - 32) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Encoded message length is too large for image.')));
    }

    var messageBytes = Uint8List(messageLength);
    for (var i = 0; i < messageLength * 8; i++) {
      if ((image[i + 32] & 1) != 0) {
        messageBytes[i ~/ 8] |= 1 << (i % 8);
      }
    }

    return utf8.decode(messageBytes);
  }

  String _encryptMessage(String message, String key) {
    final keyBytes = utf8.encode(key);
    final hashedKey = sha256.convert(keyBytes).bytes.sublist(0, 16);
    final encrypter = encrypt_package.Encrypter(
        encrypt_package.AES(encrypt_package.Key(Uint8List.fromList(hashedKey)), mode: encrypt_package.AESMode.cbc));
    final iv = encrypt_package.IV.fromLength(16);
    final encrypted = encrypter.encrypt(message, iv: iv);
    return base64.encode(encrypted.bytes + iv.bytes);
  }

  Future<void> _saveImage(Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/steganography/steganography_image.png';
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(bytes);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image saved at $imagePath')));
  }

  Future<void> _encodeAndSave() async {
    if (_isKeyAvailable && _key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a key.')));
      return;
    }
    if (_image == null || _message.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select an image, enter a message')));
      return;
    }
    String encryptedMessage;
    if (_isKeyAvailable) {
      encryptedMessage = _encryptMessage(_message, _key);
    } else {
      encryptedMessage = _message;
    }

    final imageBytes = await _image!.readAsBytes();
    final image = img.decodeImage(imageBytes)!;
    final encodedImage = _encodeMessage(encryptedMessage, image);

    await _saveImage(encodedImage);
  }

  String _decryptMessage(String encryptedMessage, String key) {
    final keyBytes = utf8.encode(key);
    final hashedKey = sha256.convert(keyBytes).bytes.sublist(0, 16);
    final encrypter = encrypt_package.Encrypter(
        encrypt_package.AES(encrypt_package.Key(Uint8List.fromList(hashedKey)), mode: encrypt_package.AESMode.cbc));
    final decoded = base64.decode(encryptedMessage);
    final iv = encrypt_package.IV(decoded.sublist(decoded.length - 16));
    final encryptedBytes = decoded.sublist(0, decoded.length - 16);
    final encrypted = encrypt_package.Encrypted(encryptedBytes);
    final decrypted = encrypter.decrypt(encrypted, iv: iv);

    return decrypted;
  }

  Future<void> _decodeImage() async {
    if (_isKeyAvailable && _key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a key.')));
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    final imageBytes = await _image!.readAsBytes();
    final image = img.decodeImage(imageBytes)!;
    final encodedMessage = _decodeMessage(image);

    if (!_isKeyAvailable) {
      setState(() {
        _decodedMessage = encodedMessage;
        return;
      });
    } else {
      try {
        final decryptedMessage = _decryptMessage(encodedMessage, _key);
        setState(() {
          _decodedMessage = decryptedMessage;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to decrypt the message.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Steganography App'),
        ),
        body: body(height, context, width),
      ),
    );
  }

  Center body(double height, BuildContext context, double width) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const TabBar(tabs: [
              Tab(icon: Icon(Icons.image_outlined)),
              Tab(icon: Icon(Icons.text_snippet_outlined)),
            ]),
            Expanded(
              child: TabBarView(
                children: [
                  encodeTab(height, context, width),
                  decodeTab(height, context, width),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SingleChildScrollView decodeTab(double height, BuildContext context, double width) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: height * 0.02,
          ),
          Text(
            "Decode a message from an image.",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(
            height: height * 0.02,
          ),
          _image == null ? pickImageMethod() : Image.file(_image!, width: 200, height: 200),
          SizedBox(
            height: height * 0.02,
          ),
          keyCheckboxAndTextField(width),
          SizedBox(
            height: height * 0.05,
          ),
          decodeButton(),
          SizedBox(
            height: height * 0.02,
          ),
          _decodedMessage.isEmpty ? const Text('No message decoded.') : Text('Decoded Message: $_decodedMessage'),
        ],
      ),
    );
  }

  ElevatedButton decodeButton() {
    return ElevatedButton(
      onPressed: _decodeImage,
      child: const Text('Decode Image'),
    );
  }

  SingleChildScrollView encodeTab(double height, BuildContext context, double width) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            height: height * 0.02,
          ),
          Text(
            "Encode a message in an image and save it.",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(
            height: height * 0.02,
          ),
          _image == null ? pickImageMethod() : Image.file(_image!, width: 200, height: 200),
          SizedBox(
            height: height * 0.02,
          ),
          Text("Image's size: ${_image?.lengthSync() ?? 0} bytes"),
          SizedBox(
            height: height * 0.02,
          ),
          messageTextField(width),
          SizedBox(
            height: height * 0.02,
          ),
          keyCheckboxAndTextField(width),
          SizedBox(
            height: height * 0.05,
          ),
          encodeButton(),
          SizedBox(
            height: height * 0.02,
          ),
        ],
      ),
    );
  }

  ElevatedButton encodeButton() {
    return ElevatedButton(
      onPressed: () {
        _encodeAndSave();
        setState(() {
          _message = '';
          _isKeyAvailable = false;
          _image = null;
          _key = '';
        });
      },
      child: const Text('Encode and Save Image'),
    );
  }

  SizedBox keyCheckboxAndTextField(double width) {
    return SizedBox(
      width: width * 0.8,
      child: Row(
        children: [
          Checkbox(
              value: _isKeyAvailable,
              onChanged: (value) {
                setState(() {
                  _isKeyAvailable = value!;
                });
              }),
          Expanded(
            child: TextField(
              enabled: _isKeyAvailable,
              decoration: const InputDecoration(labelText: 'Key'),
              onChanged: (value) {
                setState(() {
                  _key = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  SizedBox messageTextField(double width) {
    return SizedBox(
      width: width * 0.8,
      child: TextField(
        decoration: const InputDecoration(labelText: 'Message'),
        onChanged: (value) {
          setState(() {
            _message = value;
          });
        },
      ),
    );
  }

  Column pickImageMethod() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: _pickImage,
          icon: const Icon(
            Icons.image,
            size: 200,
          ),
          label: const Text('Pick Image'),
        ),
        const Text('No image selected.'),
      ],
    );
  }
}
