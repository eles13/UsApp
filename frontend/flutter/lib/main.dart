// ignore_for_file: avoid_print

import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Detection App',
        home: const Scaffold(
          body: UplWid(),
        ));
  }
}

class UplWid extends StatefulWidget {
  const UplWid({Key? key}) : super(key: key);

  @override
  _UplWidState createState() => _UplWidState();
}

class _UplWidState extends State<UplWid> {
  String _image = '';
  final Imagepicker = ImagePicker();
  String status = 'Ready to process';
  String errMessage = 'Error Uploading Image';
  String base64Image = '';
  String base64_result = '';
  bool ready_to_show = false;
  bool show_history = false;
  Image? image;
  dynamic raw_image;
  dynamic result_image;
  dynamic history;

  setStatus(String message) {
    setState(() {
      status = message;
    });
  }

  startUpload() {
    setStatus('Uploading Image...');
    if (_image == '') {
      setStatus(errMessage);
      return;
    }
    upload(_image);
  }

  reqForImages() async {
    http.Response response = http.Response("ok", 200);
    if (show_history == true) {
      setState(() {
        show_history = false;
      });
    } else {
      setStatus("Sending request...");
      try {
        response = await http.get(
          Uri.parse("http://127.0.0.1:8010/history"),
        );
        try {
          setStatus(response.statusCode == 200
              ? "Successfully processed"
              : errMessage);
          setState(() {
            history = json.decode(response.body.toString())["images"];
            show_history = true;
          });
        } catch (error) {
          setStatus(error.toString() + " after get " + response.body);
        }
      } catch (error) {
        setStatus(error.toString() + " get");
      }
    }
  }

  upload(String fileName) async {
    var request =
        http.MultipartRequest('POST', Uri.parse('http://127.0.0.1:8010/sendit'))
          ..fields['name'] = _image
          ..fields['image'] = base64Image
          ..headers['Content-Type'] = "application/x-www-form-urlencoded";
    http.Response response = http.Response("ok", 200);
    try {
      http.Response response =
          await http.Response.fromStream(await request.send());
      try {
        setStatus(
            response.statusCode == 200 ? "Successfully processed" : errMessage);
        setState(() {
          result_image =
              base64Decode(json.decode(response.body.toString())["result"]);
          show_history = false;
          ready_to_show = true;
        });
      } catch (error) {
        setStatus(error.toString() + " after upl");
      }
    } catch (error) {
      setStatus(error.toString() + " upl");
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      padding: const EdgeInsets.all(30.0),
      child: ListView(
        //crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          OutlinedButton(
              child: const Text('Choose File'),
              onPressed: () async {
                var picked = await FilePicker.platform.pickFiles();
                if (picked != null) {
                  raw_image = picked.files.first.bytes;
                  setState(() {
                    ready_to_show = false;
                    show_history = false;
                    _image = picked.files.first.name;
                    base64Image = base64Encode(raw_image);
                  });
                }
              }),
          const SizedBox(
            height: 20.0,
          ),
          if (_image == '' && !ready_to_show) const Text('No Image Selected'),
          if (_image != '' && !ready_to_show)
            Image.memory(
              raw_image,
              width: 3 * width / 4,
              height: 3 * height / 4,
            ),
          if (ready_to_show)
            Image.memory(
              result_image,
              width: 3 * width / 4,
              height: 3 * height / 4,
            ),
          const SizedBox(
            height: 20.0,
          ),
          OutlinedButton(
            onPressed: startUpload,
            child: const Text('Upload Image'),
          ),
          const SizedBox(
            height: 20.0,
          ),
          Text(
            status,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.w500,
              fontSize: 20.0,
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          OutlinedButton(
            onPressed: reqForImages,
            child: const Text('Show history'),
          ),
          if (show_history)
            for (var image in history)
              Container(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20.0,
                    ),
                    Image.memory(
                      base64Decode(image),
                      width: 3 * width / 4,
                      height: 3 * height / 4,
                    )
                  ],
                ),
              )
        ],
      ),
    );
  }
}
