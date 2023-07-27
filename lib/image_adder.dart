import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'Image_Model.dart';

class ImageAdder extends StatefulWidget {
  const ImageAdder({
    Key? key,
    this.callback,
    this.imageCallback,
  }) : super(key: key);

  final Function? callback;
  final Function? imageCallback;

  @override
  _ImageAdderState createState() => _ImageAdderState();
}

List<ImageModel> pickedImageList = [];

class _ImageAdderState extends State<ImageAdder> {
  bool showImage = false;
  bool uploading = false;
  bool isLoading = false;

  @override
  initState() {
    super.initState();
    loadModel();
  }



  @override
  dispose() {
    pickedImageList = [];
    super.dispose();
  }


  loadModel() async {
    Tflite.close();
    try {
      await Tflite.loadModel(
        model: "assets/model_unquant.tflite",
        labels: "assets/labels.txt",
      );
    } on Exception catch (e) {
      return e;
    }
  }

  Future selectFromCamera() async {
    var image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image == null) return;
    File img = File(image.path);
    var bytes = await image.readAsBytes();
    var size = bytes.lengthInBytes;

    ImageModel imageModel = ImageModel();
    imageModel.name = '${image.name.split('.')[0]}_${DateTime.now()}${image.name.split('.').last}';
    imageModel.bytes = bytes;
    imageModel.size = size;
    imageModel.file = img;
    pickedImageList.add(imageModel);
    setState(() {});
  }

  Future selectFromGallery() async {
    var image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image == null) return;
    File img = File(image.path);
    var bytes = await image.readAsBytes();
    var size = bytes.lengthInBytes;

    ImageModel imageModel = ImageModel();
    imageModel.name = '${image.name.split('.')[0]}_${DateTime.now()}${image.name.split('.').last}';
    imageModel.bytes = bytes;
    imageModel.size = size;
    imageModel.file = img;
    pickedImageList.add(imageModel);
    setState(() {});
  }

  Future predict(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path, // required
      imageMean: 0.0, // defaults to 117.0
      imageStd: 255.0, // defaults to 1.0
      numResults: 2, // defaults to 5
      threshold: 0.2, // defaults to 0.1
      asynch: true, // defaults to true
    );
    var predictedName = recognitions![0]['label'].toString().replaceRange(
        0, recognitions[0]['label'].toString().indexOf(' ') + 1, '');
    return predictedName;
  }

  processImage() async {
    String disease = await predict(pickedImageList[0].file!);
    return disease;
  }

  String? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Disease predictor"),
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'Upload the disease affected part of leaf',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                ),
              ),
            ),
            const SizedBox(),
            if (pickedImageList.isEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(children: [
                        Icon(Icons.image_outlined),
                        Text('Select from gallery'),
                      ]),
                    ),
                    onPressed: () async {
                      await selectFromGallery();
                    },
                  ),
                  ElevatedButton(
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(children: [
                        Icon(Icons.camera_alt_outlined),
                        Text('    Take a photo    '),
                      ]),
                    ),
                    onPressed: () async {
                      await selectFromCamera();
                    },
                  ),
                ],
              ),
            const SizedBox(
              height: 20,
            ),
            const SizedBox(
              height: 15,
            ),
            Visibility(
              visible: pickedImageList.isNotEmpty,
              child: Column(
                children: [
                  GridView.count(
                      padding: const EdgeInsets.all(20),
                      crossAxisCount: 1,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      shrinkWrap: true,
                      children: [
                        for (int i = 0; i < pickedImageList.length; i++)
                          Stack(
                              clipBehavior: Clip.none, fit: StackFit.expand,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    widget.imageCallback!(pickedImageList[i]);
                                  },
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.memory(
                                        pickedImageList[i].bytes,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                    right: -10,
                                    top: -10,
                                    child: GestureDetector(
                                      onTap: () {
                                        pickedImageList
                                            .remove(pickedImageList[i]);
                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Colors.white70,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close),
                                      ),
                                    ))
                              ]),
                      ]),
                  const SizedBox(
                    height: 15,
                  ),
                 result != null? Text(result!, style: const TextStyle(fontSize: 20),): Center(
                    child: ElevatedButton(
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 15),
                        child: Text('Process image',style: TextStyle(fontSize: 18),),
                      ),
                      onPressed: () async {
                        setState(() {
                          uploading = true;
                        });
                        result = await processImage();
                        setState(() {

                        });

                      },

                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  /*Center(
                    child: ElevatedButton(
                      child: const Text('Remove image'),
                      onPressed: () {
                        setState(() {
                          pickedImageList = [];
                          showImage = false;
                          uploading = false;
                        });
                      },
                    ),
                  ),*/
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
