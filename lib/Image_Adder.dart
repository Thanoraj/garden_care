// import 'dart:convert';
// import 'dart:io';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'dart:async';
// import 'package:image_picker/image_picker.dart';
// import 'package:http/http.dart' as http;
// import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
// import 'Image_Model.dart';
//
// class ImageAdder extends StatefulWidget {
//   const ImageAdder({
//     Key? key,
//     this.callback,
//     this.imageCallback,
//   }) : super(key: key);
//
//   final Function? callback;
//   final Function? imageCallback;
//
//   @override
//   _ImageAdderState createState() => _ImageAdderState();
// }
//
// List<ImageModel> pickedImageList = [];
//
// class _ImageAdderState extends State<ImageAdder> {
//   bool showImage = false;
//   bool uploading = false;
//   bool showCompleted = false;
//   Timer? timer;
//   bool isLoading = false;
//
//   @override
//   initState() {
//     super.initState();
//     loadModel();
//   }
//
//   completedTimer() {
//     timer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       showCompleted = false;
//       setState(() {});
//     });
//   }
//
//   @override
//   dispose() {
//     if (timer != null) if (timer!.isActive) timer!.cancel();
//     pickedImageList = [];
//     super.dispose();
//   }
//
//   uploadImage(ImageModel image) async {
//     List urlList = [];
//     for (ImageModel image in pickedImageList) {
//       final Reference _storageRef = await FirebaseStorage.instance
//           .ref()
//           .child('Disease Images/${image.name}');
//       await _storageRef.putData(image.bytes).whenComplete(() async {
//         await _storageRef.getDownloadURL().then((value) {
//           image.url = value;
//         });
//       });
//     }
//   }
//
//   loadModel() async {
//     final interpreter = await tfl.Interpreter.fromAsset('model_unquant.tflite');
//     Tflite.close();
//     try {
//       String res;
//       res = (await Tflite.loadModel(
//         model: "assets/models/model_unquant.tflite",
//         labels: "assets/models/labels.txt",
//       ));
//     } on Exception catch (e) {
//       print(e);
//     }
//     // } exception (e) {
//     //   print();
//     //   print("Failed to load the model");
//     // }
//   }
//
//   Future selectFromCamera() async {
//     var image = await ImagePicker().pickImage(source: ImageSource.camera);
//     if (image == null) return;
//     File img = File(image.path);
//     var bytes = await image.readAsBytes();
//     var size = bytes.lengthInBytes;
//
//     ImageModel _imageModel = ImageModel();
//     _imageModel.name = image.name.split('.')[0] +
//         '_' +
//         DateTime.now().toString() +
//         image.name.split('.').last;
//     _imageModel.bytes = bytes;
//     _imageModel.size = size;
//     _imageModel.file = img;
//     pickedImageList.add(_imageModel);
//     setState(() {});
//   }
//
//   Future selectFromGallery() async {
//     var image = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (image == null) return;
//     File img = File(image.path);
//     var bytes = await image.readAsBytes();
//     var size = bytes.lengthInBytes;
//
//     ImageModel _imageModel = ImageModel();
//     _imageModel.name = image.name.split('.')[0] +
//         '_' +
//         DateTime.now().toString() +
//         image.name.split('.').last;
//     _imageModel.bytes = bytes;
//     _imageModel.size = size;
//     _imageModel.file = img;
//     pickedImageList.add(_imageModel);
//     setState(() {});
//   }
//
//   Future predict(File image) async {
//     var recognitions = await Tflite.runModelOnImage(
//       path: image.path, // required
//       imageMean: 0.0, // defaults to 117.0
//       imageStd: 255.0, // defaults to 1.0
//       numResults: 2, // defaults to 5
//       threshold: 0.2, // defaults to 0.1
//       asynch: true, // defaults to true
//     );
//     var predictedName = recognitions[0]['label'].toString().replaceRange(
//         0, recognitions[0]['label'].toString().indexOf(' ') + 1, '');
//     print(predictedName);
//     return predictedName;
//   }
//
//   processImage() async {
//     //await uploadImage(pickedImageList[0]);
//     //String disease = await postRequest(pickedImageList[0]);
//     String disease = await predict(pickedImageList[0].file);
//     //String disease = 'Corona';
//     Map result = {};
//     print(disease.length);
//     await FirebaseFirestore.instance
//         .collection('Diseases')
//         .doc(disease)
//         .get()
//         .then((value) {
//       result['name'] = disease;
//       result['treatment'] = value['treatment'];
//     });
//     return result;
//   }
//
//   postRequest(ImageModel image) async {
//     try {
//       http.Response response = await http.post(Uri.parse(diseasePredictionUrl),
//           headers: <String, String>{
//             'Content-Type': 'application/json; charset=UTF-8',
//           },
//           body: jsonEncode(
//             {
//               "image": image.url,
//             },
//           ));
//
//       if (response.statusCode == 200) {
//         String data = response.body;
//         var decodedData = jsonDecode(data);
//         print(decodedData);
//       } else {
//         print(response.statusCode);
//         return 'Connection error';
//       }
//     } on Exception catch (e) {
//       print(e.toString());
//
//       return e.toString();
//     }
//     setState(() {
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 20.0),
//             child: Text(
//               'Upload the disease affected part of leaf',
//               style: TextStyle(
//                 color: Colors.black,
//                 fontSize: 17,
//               ),
//             ),
//           ),
//           SizedBox(),
//           if (pickedImageList.length == 0)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 MyButton(
//                   child: Column(children: [
//                     Icon(Icons.image_outlined),
//                     Text('Select from gallery'),
//                   ]),
//                   onTap: () async {
//                     await selectFromGallery();
//                   },
//                   activeColor: Colors.white,
//                   hoverColor: Colors.grey[100],
//                 ),
//                 MyButton(
//                   child: Column(children: [
//                     Icon(Icons.camera_alt_outlined),
//                     Text('    Take a photo    '),
//                   ]),
//                   onTap: () async {
//                     await selectFromCamera();
//                   },
//                   activeColor: Colors.white,
//                   hoverColor: Colors.grey[100],
//                 ),
//               ],
//             ),
//           SizedBox(
//             height: 20,
//           ),
//           SizedBox(
//             height: 15,
//           ),
//           Visibility(
//             visible: pickedImageList.length != 0,
//             child: Column(
//               children: [
//                 GridView.count(
//                     padding: EdgeInsets.all(20),
//                     crossAxisCount: 1,
//                     mainAxisSpacing: 15,
//                     crossAxisSpacing: 15,
//                     shrinkWrap: true,
//                     children: [
//                       for (int i = 0; i < pickedImageList.length; i++)
//                         Stack(
//                             fit: StackFit.expand,
//                             overflow: Overflow.visible,
//                             children: [
//                               GestureDetector(
//                                 onTap: () {
//                                   widget.imageCallback(pickedImageList[i]);
//                                 },
//                                 child: Container(
//                                   width: 50,
//                                   height: 50,
//                                   child: ClipRRect(
//                                     borderRadius: BorderRadius.circular(10),
//                                     child: Image.memory(
//                                       pickedImageList[i].bytes,
//                                       fit: BoxFit.fill,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               Positioned(
//                                   right: -10,
//                                   top: -10,
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       pickedImageList
//                                           .remove(pickedImageList[i]);
//                                       setState(() {});
//                                     },
//                                     child: Container(
//                                       padding: EdgeInsets.all(5),
//                                       decoration: BoxDecoration(
//                                         color: Colors.white70,
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Icon(Icons.close),
//                                     ),
//                                   ))
//                             ]),
//                     ]),
//                 SizedBox(
//                   height: 15,
//                 ),
//                 Center(
//                   child: MyButton(
//                     child: Text('Process image'),
//                     onTap: () async {
//                       setState(() {
//                         uploading = true;
//                       });
//                       Map result = await processImage();
//                       Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                               builder: (context) =>
//                                   DiagnosisResultScreen(result: result)));
//                     },
//                     activeColor: Colors.green,
//                     hoverColor: Colors.green[600],
//                   ),
//                 ),
//                 SizedBox(
//                   height: 15,
//                 ),
//                 Center(
//                   child: MyButton(
//                     child: Text('Remove image'),
//                     onTap: () {
//                       setState(() {
//                         pickedImageList = [];
//                         showImage = false;
//                         uploading = false;
//                       });
//                     },
//                     activeColor: Colors.red,
//                     hoverColor: Colors.red[600],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
