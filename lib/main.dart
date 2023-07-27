import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:garden_care/image_adder.dart';

import 'firebase_options.dart';

class SensorData {
  final String temperature;
  final String humidity;
  final String phLevel;
  final String soilMoisture;
  final String light;

  SensorData( {
    required this.temperature,
    required this.humidity,
    required this.phLevel,
    required this.soilMoisture,
    required this.light,

  });
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensor Data App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late DatabaseReference _databaseRef;
  SensorData? _sensorData;

  @override
  void initState() {
    super.initState();
    // Replace the URL with your Firebase Realtime Database URL
    _databaseRef = FirebaseDatabase.instance.ref();
    _startListening();
  }

  void _startListening() {
    print("in");
    _databaseRef.onValue.listen((event) async {
      var dataSnapshot = event.snapshot;
      print(dataSnapshot.value);
      if (dataSnapshot.value != null) {
        Map data = dataSnapshot.value as Map;
        List value = data['sensor-data'].split(":");
        print(value);
        try {
          _sensorData = SensorData(temperature: value[0]??"0", humidity: value[1]??"0", phLevel: value[3]??'0', soilMoisture: value[2]??'0', light: value[4]??'0');
          print(int.parse(_sensorData!.soilMoisture));
          if (double.parse(_sensorData!.phLevel)< 6 && int.parse(_sensorData!.soilMoisture) < 10 && data['passed'] == false) {
            await addFertilizer(data);
          } else if (double.parse(_sensorData!.phLevel) >= 6 && int.parse(_sensorData!.soilMoisture) < 10 && data['passed'] == false) {
            await passWater(data);
          } else if (data['passed'] == true && int.parse(_sensorData!.soilMoisture) >= 10) {
            print("motor state changed");
            await FirebaseDatabase.instance.ref().update({"passed":false});
          }
          } on Exception catch (e) {
          print(e);
        }
        setState(() {
        });
      }
    }).onError((e){print(e);});
    print("object");

  }

  passWater (data) async {
      print("motor started");
      await FirebaseDatabase.instance.ref().update({"passed":true});
      await FirebaseDatabase.instance.ref().update({"speed1":1});
      await FirebaseDatabase.instance.ref().update({"speed2":1});
      int i = 0;
      Timer timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        print("motor stopped");
        await FirebaseDatabase.instance.ref().update({"speed1":0});
        await FirebaseDatabase.instance.ref().update({"speed2":0});
        if (i == 1) {
          print(i);
          timer.cancel();
        }
        i++;
      });
  }

  addFertilizer (data) async {
      print("motor started");
      await FirebaseDatabase.instance.ref().update({"passed":true});
      await FirebaseDatabase.instance.ref().update({"speed3":1});
      int i = 0;
      Timer timer = Timer.periodic(const Duration(minutes: 1), (timer) async {
        print("fertilizer added");
        print("motor started");
        await FirebaseDatabase.instance.ref().update({"speed1":1});
        await FirebaseDatabase.instance.ref().update({"speed2":1});
        await FirebaseDatabase.instance.ref().update({"speed3":0});
        int j = 0;
        Timer timer2 = Timer.periodic(const Duration(minutes: 1), (timer2) async {
          print("motor stopped");
          await FirebaseDatabase.instance.ref().update({"speed1":0});
          await FirebaseDatabase.instance.ref().update({"speed2":0});
          if (j == 1) {
            print(i);
            timer2.cancel();
          }
          j++;
        });
        if (i == 1) {
          print(i);
          timer.cancel();
        }
        i++;
      });
  }


  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double cardWidth = (width - 70)/2;
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                height: 350,
                width: MediaQuery.of(context).size.width,
                color: Colors.green,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0,right: 10.0, top: 80),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      const Text("Garden Care", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w500, color: Colors.white),),
                      Image.asset("assets/plant.png", height: 75,), const SizedBox(width: 10,),

                    ],
                  ),
                ),
                const SizedBox(height: 50,),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),

                  child:SizedBox(
                    height: 300,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: _sensorData != null? Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SizedBox(
                                width:cardWidth,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Color(0xff2bcc83),
                                      child:
                                      Icon(Icons.thermostat,color: Colors.white,size: 30,),
                                    ),
                                    const SizedBox(width: 10,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${(double.tryParse(_sensorData!.temperature)??0).toInt()}°C',style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                        const Text('Temperature',style: TextStyle(fontSize: 14, color: Colors.black54),),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Color(0xffE7B91E),
                                      child:
                                      Icon(Icons.air,color: Colors.white,size: 30,),
                                    ),
                                    const SizedBox(width: 10,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,

                                      children: [
                                        Text('${(double.tryParse(_sensorData!.humidity)??0).toInt()}%',style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                        const Text('Humidity',style: TextStyle(fontSize: 14, color: Colors.black54),),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            indent: 30,
                            endIndent: 30,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Color(0xff9a72c9),
                                      child:
                                      Icon(Icons.cloudy_snowing,color: Colors.white,size: 30,),
                                    ),
                                    const SizedBox(width: 10,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,

                                      children: [
                                        Text('${(double.tryParse(_sensorData!.phLevel)??0)> 14? 14:(double.tryParse(_sensorData!.phLevel)??0) < 0 ? 0: (double.tryParse(_sensorData!.phLevel)??0)}',style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                        const Text('pH',style: TextStyle(fontSize: 14, color: Colors.black54),),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Color(0xff2ca5ce),
                                      child:
                                      Icon(Icons.water_drop_outlined,color: Colors.white,size: 30,),
                                    ),
                                    const SizedBox(width: 10,),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,

                                      children: [
                                        Text('${(double.tryParse(_sensorData!.soilMoisture)??0).toInt()}',style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                        const Text('Soil Moisture',style: TextStyle(fontSize: 14, color: Colors.black54),),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(
                            indent: 100,
                            endIndent: 100,
                          ),
                          Center(
                            child:  SizedBox(
                              width: cardWidth,
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xffe7aa5c),
                                    radius: 30,
                                    child:
                                    Icon(Icons.sunny,color: Colors.white,size: 30,),
                                  ),
                                  const SizedBox(width: 10,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [
                                      Text('${(double.tryParse(_sensorData!.light)??0).toInt()}%',style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),),
                                      const Text('Sun light',style: TextStyle(fontSize: 14, color: Colors.black54),),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ):const Center(
                        child: Text("Loading..."),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30,),
                 Center(
                  child: GestureDetector(
                    onTap: () {
Navigator.push(context, MaterialPageRoute(builder: (context)=> const ImageAdder()));
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 20,),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.energy_savings_leaf_sharp),
                            SizedBox(width: 10,),
                            Text("Analyse leaf disease"),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


