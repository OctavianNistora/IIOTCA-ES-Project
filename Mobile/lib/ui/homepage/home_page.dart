import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../user/login.dart';
import 'service_audio.dart';
import 'home_page_background.dart';
import 'dart:async';

class CarData {
  final String accelerationX;
  final String accelerationY;
  final String accelerationZ;
  final String crashCount;
  final String frontalDistance;
  final bool remoteBreak;
  final List<int> signsDetected;

  CarData({
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
    required this.crashCount,
    required this.frontalDistance,
    required this.remoteBreak,
    required this.signsDetected,
  });

  factory CarData.fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>;
    return CarData(
      accelerationX: data['acceleration-x'].toString(),
      accelerationY: data['acceleration-y'].toString(),
      accelerationZ: data['acceleration-z'].toString(),
      crashCount: data['crash-count'].toString(),
      frontalDistance: data['frontal-distance'].toString(),
      remoteBreak: data['remote-break'] ?? false,
      signsDetected: List<int>.from(data['signs-detected'] ?? []),
    );
  }
}

class HomePage extends StatefulWidget {
  final String raspberryPiId;

  const HomePage({super.key, required this.raspberryPiId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DatabaseReference _databaseReference;
  late AudioService _audioService;
  late ValueNotifier<CarData?> _carDataNotifier;
  late List<ChartData> chartDataX;
  late List<ChartData> chartDataY;
  late List<ChartData> chartDataZ;
  late List<ChartData> chartData2;
  bool _isAudioServiceEnabled = false;
  Timer? dataTimer;
  Timer? uiUpdateTimer;
  int timeCounter = 0;

  @override
  void initState() {
    super.initState();
    chartDataX = [];
    chartDataY = [];
    chartDataZ = [];
    chartData2 = [];

    _carDataNotifier = ValueNotifier<CarData?>(null);
    _databaseReference = FirebaseDatabase(
      databaseURL: 'https://iot-project-48691-default-rtdb.europe-west1.firebasedatabase.app/',
    ).reference().child('${widget.raspberryPiId}/realtime-data');

    _audioService = AudioService(_databaseReference, context, widget.raspberryPiId);

    _databaseReference.onValue.listen((event) {
      if (event.snapshot.value != null) {
        final carData = CarData.fromSnapshot(event.snapshot);
        _carDataNotifier.value = carData;
      }
    });

    // Timer to collect values 10 times a second
    dataTimer = Timer.periodic(const Duration(milliseconds: 100), (Timer t) {
      if (_carDataNotifier.value != null) {
        chartDataX = updateChartData(chartDataX, double.parse(_carDataNotifier.value!.accelerationX));
        chartDataY = updateChartData(chartDataY, double.parse(_carDataNotifier.value!.accelerationY));
        chartDataZ = updateChartData(chartDataZ, double.parse(_carDataNotifier.value!.accelerationZ));
        chartData2 = updateChartData(chartData2, double.parse(_carDataNotifier.value!.frontalDistance));
      }
    });

    // Timer to update the UI once a second
    uiUpdateTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    dataTimer?.cancel();
    uiUpdateTimer?.cancel();
    _carDataNotifier.dispose();
    super.dispose();
  }

  List<ChartData> updateChartData(List<ChartData> chartData, double value) {
    timeCounter++;
    chartData.add(ChartData(timeCounter / 10, value)); // Increment by 0.1 seconds
    if (chartData.length > 100) {
      chartData.removeAt(0);
    }
    return chartData;
  }

  void _toggleAudioService() {
    setState(() {
      _isAudioServiceEnabled = !_isAudioServiceEnabled;
      _audioService.toggleService();
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Stack(
        children: [
          HomePageBackground(screenHeight: screenHeight),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ValueListenableBuilder<CarData?>(
                valueListenable: _carDataNotifier,
                builder: (context, carData, _) {
                  if (carData == null) {
                    return const Center(child: CircularProgressIndicator());
                  } else {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        DataTile(title: 'Acceleration X', value: carData.accelerationX),
                        SizedBox(
                          height: 200,
                          child: SfCartesianChart(
                            backgroundColor: Colors.white,
                            primaryXAxis: NumericAxis(title: AxisTitle(text: 'Time (seconds)')),
                            series: <ChartSeries<ChartData, double>>[
                              LineSeries<ChartData, double>(
                                dataSource: chartDataX,
                                xValueMapper: (ChartData data, _) => data.time,
                                yValueMapper: (ChartData data, _) => data.value,
                              ),
                            ],
                          ),
                        ),
                        DataTile(title: 'Acceleration Y', value: carData.accelerationY),
                        SizedBox(
                          height: 200,
                          child: SfCartesianChart(
                            backgroundColor: Colors.white,
                            primaryXAxis: NumericAxis(title: AxisTitle(text: 'Time (seconds)')),
                            series: <ChartSeries<ChartData, double>>[
                              LineSeries<ChartData, double>(
                                dataSource: chartDataY,
                                xValueMapper: (ChartData data, _) => data.time,
                                yValueMapper: (ChartData data, _) => data.value,
                              ),
                            ],
                          ),
                        ),
                        DataTile(title: 'Acceleration Z', value: carData.accelerationZ),
                        SizedBox(
                          height: 200,
                          child: SfCartesianChart(
                            backgroundColor: Colors.white,
                            primaryXAxis: NumericAxis(title: AxisTitle(text: 'Time (seconds)')),
                            series: <ChartSeries<ChartData, double>>[
                              LineSeries<ChartData, double>(
                                dataSource: chartDataZ,
                                xValueMapper: (ChartData data, _) => data.time,
                                yValueMapper: (ChartData data, _) => data.value,
                              ),
                            ],
                          ),
                        ),
                        DataTile(title: 'Crash Count', value: carData.crashCount),
                        DataTile(title: 'Frontal Distance', value: carData.frontalDistance),
                        SizedBox(
                          height: 200,
                          child: SfCartesianChart(
                            backgroundColor: Colors.white,
                            primaryXAxis: NumericAxis(title: AxisTitle(text: 'Time (seconds)')),
                            series: <ChartSeries<ChartData, double>>[
                              LineSeries<ChartData, double>(
                                dataSource: chartData2,
                                xValueMapper: (ChartData data, _) => data.time,
                                yValueMapper: (ChartData data, _) => data.value,
                              ),
                            ],
                          ),
                        ),
                        DataTile(title: 'Remote Break', value: carData.remoteBreak.toString()),
                        DataTile(title: 'Signs Detected', value: carData.signsDetected.join(', ')),
                        const SizedBox(height: 20),
                        const Text(
                          'WARNING: USE ONLY IF THERE IS AN EMERGENCY',
                          style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _databaseReference.child('remote-break').set(!carData.remoteBreak);
                          },
                          child: Text(carData.remoteBreak ? 'Engine OFF' : 'Engine ON'),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _toggleAudioService,
                          child: Text(_isAudioServiceEnabled ? 'Disable Voice Assistant' : 'Enable Voice Assistant'),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataTile extends StatelessWidget {
  final String title;
  final String value;

  const DataTile({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green[900]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                value,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChartData {
  double time;
  final double value;

  ChartData(this.time, this.value);
}
