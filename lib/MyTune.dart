import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_midi_pro/flutter_midi_pro.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:singingeartrainingapp/song_model.dart';


import 'package:sound_generator/sound_generator.dart';
import 'package:tonic/tonic.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
import 'package:pitchupdart/instrument_type.dart';
import 'package:pitchupdart/pitch_handler.dart';
import 'package:sound_generator/waveTypes.dart';
import 'package:wakelock/wakelock.dart';
import 'CustomDialogBox.dart';
import 'CustomPitchHandler.dart';
import 'PlayerButtons.dart';


import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:icofont_flutter/icofont_flutter.dart';


class MyTune extends StatefulWidget {
  double appbar;
  MyTune({Key? key, required this.appbar }) : super(key: key);

  @override
  _MyTuneState createState() => _MyTuneState();
}

class _MyTuneState extends State<MyTune> with AutomaticKeepAliveClientMixin{
  bool isPlaying = false;
  double frequency = 20;
  //bool isRecording = false;
  double balance = 0;
  double volume = 0.01;
  waveTypes waveType = waveTypes.SINUSOIDAL;
  int sampleRate = 96000;
  late List<int> oneCycleData;
  late AudioPlayer _audioPlayer;
  List<Song> songs =Song.songs;
  AudioPlayer audioPlayer =AudioPlayer();
  Song song =Song.songs[0];
  bool get wantKeepAlive => true;
  final _audioRecorder = FlutterAudioCapture();
  final pitchDetectorDart = PitchDetector(44100, 2000);
  final pitchupDart = CustomPitchHandler(InstrumentType.guitar);
  //final flutterMidi = FlutterMidi();
  var note = "";
  var status = tr("Click on start");
  double pitch = 0.0;
  double value = 0.0;
  String _buttonState = tr('Start');
  var _color = Color(0xffa22633 );
  double speed = 0.5;

  final _midi = MidiPro();

  Future<void> load() async {

    await _midi.loadSoundfont(sf2Path: "assets/sounds/Guitar Acoustic.sf2");
  }
  void play(int midi, {int velocity = 127}) {
    _midi.playMidiNote(midi: midi, velocity: velocity);
  }

  void stop(int midi) {
    _midi.stopMidiNote(midi: midi);
  }
  Future<void> setupMIDIPlugin() async {
    // flutterMidi.unmute();
    ByteData _byte = await rootBundle.load("assets/sounds/Guitar Acoustic.sf2");//grand_piano.sf2,Guitar Acoustic.sf2
    //  flutterMidi.prepare(sf2: _byte);
  }

  /// 초기화 함수
  _init() async {
    load();
    setState(() {
      // 화면 꺼짐 방지
      Wakelock.enable();
      //Permission.microphone;
    });
  }

  getPermission() async {
    var status = await Permission.microphone.status;
    if (status.isGranted) {
      print('허락됨');
    } else if (status.isDenied) {
      print('거절됨');
      Permission.microphone.request(); // 허락해달라고 팝업띄우는 코드
    }
  }

  Future<void> _startCapture() async {
    await _audioRecorder.start(listener, onError,
        sampleRate: 44100, bufferSize: 3000);
    setState(() {
      note = "";
      pitch = 0.0;
      value = 0.0;
    });
  }

  Future<void> _stopCapture() async {
    await _audioRecorder.stop();
    setState(() {
      note = "";
      pitch = 0.0;
      value = 0.0;
    });
  }

  void listener(dynamic obj) {
    //Gets the audio sample
    try {
      var buffer = Float64List.fromList(obj.cast<double>());
      final List<double> audioSample = buffer.toList();

      //Uses pitch_detector_dart library to detect a pitch from the audio sample
      final result = pitchDetectorDart.getPitch(audioSample);

      if (result.pitched) {
        //Uses the pitchupDart library to check a given pitch for a Guitar
        final handledPitchResult = pitchupDart.handlePitch(result.pitch);
        //result.pitched = event["pitch"] as double;

        String tuningStatus = handledPitchResult.tuningStatus.toString();
        String formattedStatus = displayStatusMessage(tuningStatus);
        //String formattedStatus = widget.sections[_identifySliceIndex()].showText.toUpperCase();

        //Updates the state with the result
        setState(() {
          note = handledPitchResult.note;
          status = formattedStatus; //handledPitchResult.tuningStatus.toString();
          value = calculateStatusValue(tuningStatus) as double;
          pitch = result.pitch;
          frequency = result.pitch;
          SoundGenerator.setFrequency(frequency);
        });
      }
    }
    catch(e)
    {
      print(e);
    }
  }
  void onError(Object e) {
    print(e);
  }

  String displayStatusMessage(String status) {
    switch (status) {
      case 'TuningStatus.waytoolow':
        return "Too Low".tr();
      case 'TuningStatus.toolow':
        return "Low".tr();
      case 'TuningStatus.tuned':
        return "Tune!!!".tr();
      case 'TuningStatus.toohigh':
        return "High".tr(); //6
      case 'TuningStatus.waytoohigh':
        return "Too High".tr();
      case 'TuningStatus.high2':return "+2".tr();
      case 'TuningStatus.high4':return "+4".tr();
      case 'TuningStatus.low2':return "-2".tr();
      case 'TuningStatus.low4':return "-4".tr();
      default:
        return "";
    }
  }

  Object calculateStatusValue(String status) {
    switch (status) {
      case 'TuningStatus.waytoolow':
        return -4.0;
      case 'TuningStatus.low4':
        return -3.0;
      case 'TuningStatus.toolow':
        return -2.0;
      case 'TuningStatus.low2':
        return -1.0;
      case 'TuningStatus.tuned':
        return 0.0;
      case 'TuningStatus.high2':
        return 1.0;
      case 'TuningStatus.toohigh':
        return 2.0;
      case 'TuningStatus.high4':
        return 3.0;
      case 'TuningStatus.waytoohigh':
        return 4.0;
      default:
        return 0;
    }
  }

  Widget _emojify4() {
    switch (status) {
      case "너무 낮습니다.":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "낮습니다.":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case '-4':
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case '-2':
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "정답!!":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "시작버튼을 누르세요:)":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "노래하세요:)":
        return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
      case "Too Low":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "Low":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "Tune!!!":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "Click on start":
        return Image.asset('assets/A2.png', fit: BoxFit.fill);
      case "Singing:)":
        return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
      case "Singing":
        return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
    }
    return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
  }

  Widget _emojify5() {
    switch (status) {
      case "정답!!":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case '+4':
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case '+2':
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "높습니다":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "너무 높습니다":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "시작버튼을 누르세요:)":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "연주하세요:)":
        return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
      case "Tune!!!":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case  "High":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "Too High":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "Click on start":
        return Image.asset('assets/A1.png', fit: BoxFit.fill);
      case "Singing:)":
        return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
      case "Singing":
        return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
    }
    return Image.asset('assets/Tune8.png', fit: BoxFit.fill);
  }

  Widget? _emojify8() {
    switch (status) {
      case "시작버튼을 누르세요:)":
        return Image.asset('assets/r1.png', fit: BoxFit.fill);
      case "연주하세요:)":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
      case "Click on start":
        return Image.asset('assets/r1.png', fit: BoxFit.fill);
      case "Singing:)":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
      case "Singing":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
    }
  }

  Widget? _emojify9() {
    switch (status) {
      case "시작버튼을 누르세요:)":
        return Image.asset('assets/r2.png', fit: BoxFit.fill);
      case "연주하세요:)":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
      case "Click on start":
        return Image.asset('assets/r2.png', fit: BoxFit.fill);
      case "Singing:)":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);

      case "Singing":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
    }
  }

  Widget? _emojify10() {
    switch (status) {
      case "시작버튼을 누르세요:)":
        return Image.asset('assets/r3.png', fit: BoxFit.fill);
      case "연주하세요:)":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
      case "Click on start":
        return Image.asset('assets/r3.png', fit: BoxFit.fill);
      case "Singing:)":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
      case "Singing":
        return Image.asset('assets/r5.png',fit: BoxFit.fill);
    }
  }

  Widget? _emojify11() {
    switch (status) {
      case "시작버튼을 누르세요:)":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
          child: Image.asset('assets/r4.png', fit: BoxFit.fill),);
      case "연주하세요:)":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
          child: Image.asset('assets/r5.png', fit: BoxFit.fill),);
      case "Click on start":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
          child: Image.asset('assets/r4.png', fit: BoxFit.fill),);
      case "Singing:)":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
          child: Image.asset('assets/r5.png', fit: BoxFit.fill),);
      case "Singing":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
          child: Image.asset('assets/r5.png', fit: BoxFit.fill),);

    }
  }

  Widget? _emojify12() {
    switch (status) {
      case "시작버튼을 누르세요:)":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
          child: Image.asset('assets/r4.png', fit: BoxFit.fill),);
      case "연주하세요:)":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
          child: Image.asset('assets/r5.png', fit: BoxFit.fill),);
      case "Click on start":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
          child: Image.asset('assets/r4.png', fit: BoxFit.fill),);
      case "Singing:)":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
          child: Image.asset('assets/r5.png', fit: BoxFit.fill),);
      case "Singing":
        return ClipRRect(
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
          child: Image.asset('assets/r5.png', fit: BoxFit.fill),);
    }
  }

  Widget _emojify() {
    switch (status) {
      case "Too Low":
        return Image.asset('assets/3-4.png');
      case "Low":
        return Image.asset('assets/7-4.png');
      case "Tune!!!":
        return Image.asset('assets/4-4.png');
      case "High":
        return Image.asset('assets/6-4.png');
      case "Too High":
        return Image.asset('assets/2-4.png');
      case "Click on start":
        return Image.asset('assets/5-4.png');
      case "너무 낮습니다.":
        return Image.asset('assets/3-4.png');
      case "-4":
        return Image.asset('assets/3-4.png');
      case "낮습니다.":
        return Image.asset('assets/2-4.png');
      case "-2":
        return Image.asset('assets/2-4.png');
      case "정답!!":
        return Image.asset('assets/4-4.png');
      case "+2":
        return Image.asset('assets/7-4.png');
      case "높습니다":
        return Image.asset('assets/7-4.png');
      case "+4":
        return Image.asset('assets/6-4.png');
      case "너무 높습니다":
        return Image.asset('assets/6-4.png');
      case "시작버튼을 누르세요:)":
        return Image.asset('assets/5-4.png');
    }
    return Image.asset('assets/1-4.png');
  }

  Widget _emojify2() {
    switch (note) {
      case "C4":
        return Image.asset('assets/images/note1.png');
      case "C#4":
        return Image.asset('assets/images/note2.png');
      case "D4":
        return Image.asset('assets/images/note3.png');
      case "D#4":
        return Image.asset('assets/images/note4.png');
      case "E4":
        return Image.asset('assets/images/note5.png');
      case "F4":
        return Image.asset('assets/images/note6.png');
      case "F#4":
        return Image.asset('assets/images/note7.png');
      case "G4":
        return Image.asset('assets/images/note8.png');
      case "G#4":
        return Image.asset('assets/images/note9.png');
      case "A4":
        return Image.asset('assets/images/note10.png');
      case "A#4":
        return Image.asset('assets/images/note11.png');
      case "B4":
        return Image.asset('assets/images/note12.png');
      case "C5":
        return Image.asset('assets/images/note13.png');
      case "C#5":
        return Image.asset('assets/images/note35.png');
      case "D5":
        return Image.asset('assets/images/note36.png');
      case "D#5":
        return Image.asset('assets/images/note37.png');
      case "E5":
        return Image.asset('assets/images/note38.png');
      case "F5":
        return Image.asset('assets/images/note39.png');
      case "F#5":
        return Image.asset('assets/images/note40.png');
      case "G5":
        return Image.asset('assets/images/note41.png');
      case "G#5":
        return Image.asset('assets/images/note42.png');
      case "A5":
        return Image.asset('assets/images/note43.png');
      case "A#5":
        return Image.asset('assets/images/note44.png');
      case "B5":
        return Image.asset('assets/images/note45.png');
      case "C6":
        return Image.asset('assets/images/note46.png');
      case "C3":
        return Image.asset('assets/images/note23.png');
      case "C#3":
        return Image.asset('assets/images/note24.png');
      case "D3":
        return Image.asset('assets/images/note25.png');
      case "D#3":
        return Image.asset('assets/images/note26.png');
      case "E3":
        return Image.asset('assets/images/note27.png');
      case "F3":
        return Image.asset('assets/images/note28.png');
      case "F#3":
        return Image.asset('assets/images/note29.png');
      case "G3":
        return Image.asset('assets/images/note30.png');
      case "G#3":
        return Image.asset('assets/images/note31.png');
      case "A3":
        return Image.asset('assets/images/note32.png');
      case "A#3":
        return Image.asset('assets/images/note33.png');
      case "B3":
        return Image.asset('assets/images/note34.png');
    }
    return Image.asset('assets/images/note.png', fit: BoxFit.fill);
  }

  double get keyWidth => 30 + (30 * _widthRatio); //50 + (50 * _widthRatio);
  double _widthRatio = 0.6;
  bool _showLabels = true;
  bool _flag = true;

  @override
  Widget build(BuildContext context) {
    //List<Song> songs =Song.songs;
    var appbarWidget = AppBar(
      backgroundColor: const Color(0xff1f212a),
      title: Text(
        tr("Singing&Ear Training"),
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w700,
        ),
        textScaleFactor: 1.0,
      ),

      centerTitle: true,
    );
    var appbar = widget.appbar;
    var statusbarT = MediaQuery.of(context).padding.top;
    var statusbarB = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: appbarWidget,
      drawer: ClipRRect(
        borderRadius: BorderRadius.only(
            topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
        child: Container(
          width: (MediaQuery.of(context).size.width) * 0.6,
          height:
          (MediaQuery.of(context).size.height - statusbarT - statusbarB) *
              0.605,
          child: Drawer(
            child: ListView(
              primary: false,
              padding: EdgeInsets.all(0.0),
              children: <Widget>[
                SizedBox(
                  height: (MediaQuery.of(context).size.height -
                      statusbarT -
                      statusbarB) * 0.12,
                  width: (MediaQuery.of(context).size.width) * 0.6,
                  child: DrawerHeader(
                      decoration: BoxDecoration(color: Color(0xff1f212a)),
                      margin: EdgeInsets.all(0.0),
                      padding: EdgeInsets.only(
                        left: (MediaQuery.of(context).size.width) * 0.04,
                        bottom: (MediaQuery.of(context).size.height -
                            statusbarT -
                            statusbarB) * 0.01,),
                      child: Row(
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: (MediaQuery.of(context).size.width) * 0.02,),
                            child: Icon(Icons.settings,color: Colors.white,),
                          ),
                          Text(
                            "Settings",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24.sp,
                            ),
                          ),
                        ],
                      )
                  ),
                ),
                SizedBox(height: (MediaQuery.of(context).size.height -
                    statusbarT -
                    statusbarB) *
                    0.01,),
                Container(
                    padding: EdgeInsets.only(
                      left: (MediaQuery.of(context).size.width) * 0.04,
                    ),
                    height: (MediaQuery.of(context).size.height -
                        statusbarT -
                        statusbarB) *
                        0.04,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: (MediaQuery.of(context).size.width) * 0.02,
                          ),
                          child: Icon(Icons.language_outlined),
                        ),
                        Text("Language Settings").tr()
                      ],
                    )),
                const Divider(),
                Center(
                  child: SizedBox(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // 한국어로 언어 변경
                        // 이후 앱을 재시작하면 한국어로 동작
                        EasyLocalization.of(context)
                            ?.setLocale(Locale('ko', 'KR'));
                      },
                      icon: Icon(Icons.language_outlined),
                      label: Text(
                        'korean',
                      ),
                    ),
                  ),
                ),
                //const Divider(),
                Center(
                  child: SizedBox(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // 영어로 언어 변경
                        // 이후 앱을 재시작하면 영어로 동작
                        EasyLocalization.of(context)
                            ?.setLocale(Locale('en', 'US'));
                      },
                      icon: Icon(Icons.language_outlined),
                      label: Text(
                        'english',
                      ),
                    ),
                  ),
                ),
                const Divider(),
                Container(
                    padding: EdgeInsets.only(
                      left: (MediaQuery.of(context).size.width) * 0.04,
                    ),
                    height: (MediaQuery.of(context).size.height -
                        statusbarT -
                        statusbarB) *
                        0.04,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(
                            right: (MediaQuery.of(context).size.width) * 0.02,
                          ),
                          child: Icon(Icons.piano),
                        ),
                        Text("Keybord Settings").tr()
                      ],
                    )),
                Container(
                    padding: EdgeInsets.only(
                      left: (MediaQuery.of(context).size.width) * 0.04,
                    ),
                    height: (MediaQuery.of(context).size.height -
                        statusbarT -
                        statusbarB) *
                        0.04,
                    alignment: Alignment.centerLeft,
                    child: Text(("Key Width").tr(),
                        style: TextStyle(
                            color: Colors.blue[500])) //Colors.black87,),)
                ),
                Container(
                  height: (MediaQuery.of(context).size.height -statusbarT - statusbarB) * 0.04,
                  child: Slider(
                      activeColor: Colors.red[400],
                      inactiveColor: Colors.grey[300],
                      min: 0.0,
                      max: 1.0,
                      value: _widthRatio,
                      onChanged: (double value) =>
                          setState(() => _widthRatio = value)),
                ),
                   Container(
                    padding: EdgeInsets.only(
                      left: (MediaQuery.of(context).size.width) * 0.04,
                      right: (MediaQuery.of(context).size.width) * 0.04,
                    ),
                    height: (MediaQuery.of(context).size.height -
                        statusbarT -
                        statusbarB) *
                        0.04,
                    width: (MediaQuery.of(context).size.width) * 0.6,
                    alignment: Alignment.centerLeft,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(("Show Labels").tr(),
                              style: TextStyle(color: Colors.blue[500])),
                          Switch(
                              value: _showLabels,
                              onChanged: (bool value) =>
                                  setState(() => _showLabels = value)),]),),
                const Divider(),
                Container(
                    padding: EdgeInsets.only(
                      left: (MediaQuery.of(context).size.width) * 0.04,
                    ),
                    height: (MediaQuery.of(context).size.height -
                        statusbarT -
                        statusbarB) *
                        0.04,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.black,
                              width: 1.7,
                            ),
                            borderRadius: BorderRadius.circular(3),),
                          child: Icon(
                            Icons.tune_outlined,
                            size: 17,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(
                            right: (MediaQuery.of(context).size.width) * 0.018,
                          ),
                        ),
                        Text("ToneGenerater Settings"),
                      ],
                    )),
                const Divider(),

                  Container(
                    padding: EdgeInsets.only(
                      left: (MediaQuery.of(context).size.width) * 0.04,
                      right: (MediaQuery.of(context).size.width) * 0.04,
                    ),
                    height: (MediaQuery.of(context).size.height -
                        statusbarT -
                        statusbarB) *
                        0.04,
                    width: (MediaQuery.of(context).size.width) * 0.6,
                    alignment: Alignment.centerLeft,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              right: (MediaQuery.of(context).size.width) * 0.02,
                            ),
                            child: Icon(IcoFontIcons.soundWave,color: Colors.blue[500],size: 18,),
                          ),
                          Text("Wave Form",
                              style: TextStyle(color: Colors.blue[500])),
                          Expanded(flex: 65, child: Center(child:
                          Text(''),))
                        ]),),
                Center(
                    child: DropdownButton<waveTypes>(
                        value: waveType,
                        onChanged: (newValue) {
                          setState(() {
                            waveType = newValue!;
                            SoundGenerator.setWaveType(waveType);
                          });
                        },
                        items:
                        waveTypes.values.map((waveTypes classType) {
                          return DropdownMenuItem<waveTypes>(
                              value: classType,
                              child: Text(
                                  classType.toString().split('.').last,
                                  style: TextStyle(color: Colors.redAccent)));
                        }).toList())),
              ],
            ),
              ),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(height: 7),
              Row(
                children: [
                  Container(
                      height: (MediaQuery.of(context).size.height -
                          appbar -
                          statusbarT -
                          statusbarB) *
                          0.1,
                      width: (MediaQuery.of(context).size.width) * 0.116,
                      padding: EdgeInsets.only(
                        left: (MediaQuery.of(context).size.width) * 0.02,
                      ),
                      //alignment: Alignment.center,
                      decoration: BoxDecoration(
                      ),
                      child: Column(
                        children: [
                          Center(
                            child: Container(//color: Colors.lightBlueAccent,
                              height:(MediaQuery.of(context).size.width) * 0.0945,
                              width: (MediaQuery.of(context).size.width) * 0.0945,
                              alignment: Alignment.center,
                              margin: REdgeInsets.only(left: 0, right: 0.00),
                              decoration: BoxDecoration(color: Colors.white,
                                border: Border.all(
                                  color: Color(0xff822831),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(9),),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top:  (MediaQuery.of(context).size.height -
                                      appbar -
                                      statusbarT -
                                      statusbarB) *
                                      0.002,
                                ),
                                child: Icon(Icons.mic,color: Colors.black,size: 28,),),
                            ),
                          ),
                          Container(//color: Colors.yellow,
                          ),
                        ],
                      )),
                  Container(//color: Colors.green,
                    width: (MediaQuery.of(context).size.width) * 0.768,
                    alignment: Alignment.center,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: value < -2
                              ? Colors.red[900]
                              : value < 0
                              ? Colors.orangeAccent
                              : value < 1
                              ? Color(0xff144a4a)
                              : value < 3
                              ? Colors.orangeAccent
                              : Colors.red[900],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Container(//color: Color(0xff144a4a),
                          width: (MediaQuery.of(context).size.height -
                              appbar -
                              statusbarT -
                              statusbarB) *
                              0.1,
                          height: (MediaQuery.of(context).size.height -
                              appbar -
                              statusbarT -
                              statusbarB) *
                              0.1,
                          child: _emojify(),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: (MediaQuery.of(context).size.height - appbar - statusbarT - statusbarB) * 0.1,
                    width: (MediaQuery.of(context).size.width) * 0.116,
                    padding: EdgeInsets.only(right: (MediaQuery.of(context).size.width) * 0.02,),
                    //alignment: Alignment.center,color: Colors.lightBlueAccent[100],
                  ),
                ],
              ),
              Container(//color: Colors.green,
                height: (MediaQuery.of(context).size.height -
                    appbar -
                    statusbarT -
                    statusbarB) *
                    0.11,
                width: (MediaQuery.of(context).size.width) * 0.9,
                child: Row(crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(5),
                                bottomLeft: Radius.circular(5)),
                            color: value < -3 ? Color(0xff898282c) : Colors.white,
                          ),
                          child: _emojify11(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          color: value < -2 ? Color(0xFFBF360C) : Colors.white,
                          child: _emojify10(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          color: value < -1 ? Color(0xfff3a539) : Colors.white,
                          child: _emojify9(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          color: value < 0 ? Color(0xFFFBC02D) : Colors.white,
                          child: _emojify8(),
                        )),
                    Expanded(
                        flex: 2,
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          decoration: BoxDecoration(border: Border(right: BorderSide(color: Colors.white, width: 3.w,),)),
                          //color: Colors.white,
                          child: _emojify4(),
                        )),
                    Expanded(
                      flex: 5,
                      child: Center(
                        child: Container(//color: Colors.green,
                          height: (MediaQuery.of(context).size.height -
                              appbar -
                              statusbarT -
                              statusbarB) *
                              0.11,
                          alignment: Alignment.center,
                          child: Text(
                            note,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 50.sp,
                              fontWeight: FontWeight.w600,height: 1.2,),
                            //textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white, width: 3.w,),)),
                          //color: Colors.white,
                          child: _emojify5(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          color: value < 1 ? Colors.white : Color(0xFFFBC02D),
                          child: _emojify8(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          color: value < 2 ? Colors.white : Color(0xfff3a539),
                          child: _emojify9(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          color: value < 3 ? Colors.white : Color(0xFFBF360C),
                          child: _emojify10(),
                        )),
                    Expanded(
                        child: Container(
                          height: (MediaQuery.of(context).size.height - appbar - statusbarT -
                              statusbarB) * 0.085,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(5),
                                bottomRight: Radius.circular(5)),
                            color: value < 4 ? Colors.white : Color(0xff898282c),
                          ),
                          child: _emojify12(),
                        )),
                  ],
                ),
              ),
              //SizedBox(height: 0),
              Container(//color: Colors.green,
                height: (MediaQuery.of(context).size.height -
                    appbar -
                    statusbarT -
                    statusbarB) *
                    0.05,
                alignment: Alignment.center,
                child: Center(
                    child: Text(
                      status,
                      textScaleFactor: 1.0,
                      style: TextStyle(
                        //color: Color(0xff009bd9), //Colors.black87,
                          color: value < -3
                              ? Colors.red[900]//-5
                              : value < -2
                              ? Colors.white//-4
                              : value < -1
                              ? Color(0xfff3a539)//-3
                              : value < 0
                              ? Colors.white//-1,-2
                              : value < 1
                              ? Color(0xff144a4a)//0
                              : value < 2
                              ? Colors.white//1,2
                              : value < 3
                              ?  Color(0xfff3a539)//3
                              : value < 4
                              ? Colors.white
                              : Colors.red[900],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,height: 1.15),
                    )),
              ),
              Container(
                height: (MediaQuery.of(context).size.height -
                    appbar -
                    statusbarT -
                    statusbarB) *
                    0.22,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(//color: Colors.yellow,
                              height: (MediaQuery.of(context).size.height -
                                  appbar -
                                  statusbarT -
                                  statusbarB) *
                                  0.16,
                              alignment: Alignment.center,
                              padding: EdgeInsets.only(bottom: 9),
                              child: Container(//color: Colors.green,
                                width: 61,
                                height: 61,
                                child: ElevatedButton(
                                  child: Text(
                                    '$_buttonState',
                                    textScaleFactor: 1.0,
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_buttonState == tr('Start')) {
                                        _buttonState = tr('Stop');
                                        _color = Color(0xFF003128);
                                        _startCapture();
                                        status = tr("Singing");
                                        _flag=false;
                                      } else {
                                        _buttonState = tr('Start');
                                        _color = Color(0xffa22633 );
                                        _stopCapture();
                                        status = tr("Click on start");
                                        _flag=true;
                                      }
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 20,
                                    padding: REdgeInsets.all(5),
                                    backgroundColor: _flag ? Color(0xffa22633 ): Colors.grey//Color(0xFF004D40),
                                  ),
                                  // color: _color,
                                  //   elevation: 10,
                                  //    padding: REdgeInsets.all(5),
                                  //   shape: const RoundedRectangleBorder(
                                  //         borderRadius:
                                  //              BorderRadius.all(Radius.circular(50.0))),
                                ),
                              ),
                            ),
                            Container(
                                height: (MediaQuery.of(context).size.height -
                                    appbar -
                                    statusbarT -
                                    statusbarB) *
                                    0.05,
                                padding: EdgeInsets.only(
                                  left: (MediaQuery.of(context).size.width) * 0.02,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  //color: Colors.lightBlueAccent[100],
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.black12,
                                        width: 0.5.w,
                                      ),
                                    )),
                                child: Row(
                                  children: [
                                    Container(
                                      color: Colors.lightBlueAccent,
                                      margin: REdgeInsets.only(top: 5),
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                            top:  (MediaQuery.of(context).size.height -
                                                appbar -
                                                statusbarT -
                                                statusbarB) *
                                                0.00,
                                          ),
                                          child: Icon(
                                            Icons.tune_outlined,
                                            color: Colors.black,
                                          )),
                                    ),
                                    Container(
                                      margin: REdgeInsets.only(top: 5),
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                            left:
                                            (MediaQuery.of(context).size.width) *
                                                0.02,
                                          ),
                                          child: Text(tr("Generator"), textScaleFactor: 1.0,style: TextStyle(height: 1.4,fontSize: 14),)),
                                    ),
                                  ],
                                )),
                          ],
                        )),
                    Container(
                      width: (MediaQuery.of(context).size.width) * 0.33,
                      height: (MediaQuery.of(context).size.height -
                          appbar -
                          statusbarT -
                          statusbarB) *
                          0.22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: Color(0xff822831),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            height: (MediaQuery.of(context).size.height -
                                appbar -
                                statusbarT -
                                statusbarB) *
                                0.17,
                            child: _emojify2(),
                          ),
                          Expanded(
                            child: Container(//color: Colors.yellow,
                              alignment: Alignment.center,
                              height: (MediaQuery.of(context).size.height -
                                  appbar -
                                  statusbarT -
                                  statusbarB) *
                                  0.05, //color: Colors.grey,
                              child: Text(
                                "${frequency.toStringAsFixed(2)} Hz",
                                textScaleFactor: 1.0,
                                style: TextStyle(
                                    color: Colors.black87, height:1,fontSize: 20,fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(//color: Colors.red,
                              height: (MediaQuery.of(context).size.height -
                                  appbar -
                                  statusbarT -
                                  statusbarB) *
                                  0.16,
                              alignment: Alignment.center,
                              padding: EdgeInsets.only(bottom: 9),
                              child: Container(
                                width: 60,
                                height: 60,
                                child: Material(
                                  color: Colors.transparent,
                                  elevation: 9,
                                  shape: const RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.all(Radius.circular(50.0))),
                                  child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.lightBlueAccent,
                                      child: IconButton(
                                        color: Colors.black, //blue[900],
                                        iconSize: 34,
                                        icon: Icon((isPlaying)
                                            ? Icons.stop
                                            : Icons.tune_outlined),
                                        onPressed: () async {
                                          var result = await SoundGenerator.isPlaying;
                                          setState(()  {
                                            isPlaying = !result;
                                          });
                                          await SoundGenerator.isPlaying? SoundGenerator.stop()
                                              : SoundGenerator.play();

                                        },
                                      )),
                                ),
                              ),
                            ),
                            Container(
                                height: (MediaQuery.of(context).size.height -
                                    appbar -
                                    statusbarT -
                                    statusbarB) *
                                    0.05,
                                padding: EdgeInsets.only(
                                  left: (MediaQuery.of(context).size.width) * 0.0,
                                ),
                                //alignment: Alignment.center,
                                decoration: BoxDecoration(//color: Colors.lightBlueAccent[100],
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.black12,
                                        width: 0.5.w,
                                      ),
                                    )),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top:  (MediaQuery.of(context).size.height -
                                            appbar -
                                            statusbarT -
                                            statusbarB) *
                                            0.01,
                                        left: (MediaQuery.of(context).size.width) * 0.04,),
                                      child: Container(//color: Colors.lightBlueAccent,
                                          height: (MediaQuery.of(context).size.height -
                                              appbar -
                                              statusbarT -
                                              statusbarB) *
                                              0.05,
                                          width: (MediaQuery.of(context).size.height -
                                              appbar -
                                              statusbarT -
                                              statusbarB) *
                                              0.05,
                                          alignment: Alignment.center,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            //splashRadius: 30,
                                            //iconSize: 20,
                                            icon: const Icon(Icons.volume_up,color: Color(0xFF757575),),
                                            onPressed: (){
                                              showDialog(context: context,
                                                  builder: (BuildContext context){
                                                    return CustomDialogBox(
                                                      title: tr("Adjust Volume")
                                                      //descriptions: "Hii all this is a custom dialog in flutter and  you will be use in your flutter applications",
                                                      //text: "Yes",
                                                    );
                                                  }
                                              );
                                            },
                                          )
                                      ),
                                    ),
                                  ],
                                )),
                          ],
                        )),
                  ],
                ),
              ),
              //const Divider(color: Colors.red,),
              Container(
                  width: double.infinity,
                  height: (MediaQuery.of(context).size.height -
                      appbar -
                      statusbarT -
                      statusbarB) *
                      0.06,
                  //color: Colors.lightBlueAccent[100],
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          //flex: 8, // 60%
                          child: Container(
                            //color: Color(0xFFFBC02D),
                            alignment: Alignment.center,
                            child: SliderTheme(
                                data: SliderThemeData(
                                  thumbColor: Colors.lightBlueAccent[500],
                                  inactiveTrackColor: Colors.black,
                                  activeTrackColor: Colors.blue[300],
                                ),
                                child: Slider(
                                    min: 20,
                                    max: 1500,
                                    value: frequency,
                                    onChanged: (value) {
                                      setState(() {
                                        frequency = value.toDouble();
                                        SoundGenerator.setFrequency(frequency);
                                      });
                                    })),
                          ),
                        ),
                      ])),
              Container(
                height: (MediaQuery.of(context).size.height - appbar - statusbarT - statusbarB) * 0.005,
                decoration: BoxDecoration(//color: Colors.lightBlueAccent[100],
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black12,
                        width: 0.5.w,
                      ),
                    )),
              ),
              Container(
                child: Row(
                  children: [
                    Container(
                        height: (MediaQuery.of(context).size.height - appbar - statusbarT - statusbarB) * 0.1,
                        width: (MediaQuery.of(context).size.width) * 0.116,
                        padding: EdgeInsets.only(
                          left: (MediaQuery.of(context).size.width) * 0.02,
                          top: (MediaQuery.of(context).size.width) * 0.01,
                          bottom: (MediaQuery.of(context).size.width) * 0.0001,
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                height:(MediaQuery.of(context).size.width) * 0.0945,
                                width: (MediaQuery.of(context).size.width) * 0.0945,
                                alignment: Alignment.center,
                                margin: REdgeInsets.only(left: 0, right: 0.00),
                                decoration: BoxDecoration(color: Colors.white,
                                  border: Border.all(
                                    color: Color(0xff822831),
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(9),),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right:  (MediaQuery.of(context).size.height -
                                        appbar -
                                        statusbarT -
                                        statusbarB) *
                                        0.0,
                                  ),
                                  child: Icon(IcoFontIcons.listening,color: Colors.black,size: 25.5,),),
                              ),
                            ),//
                            Container(//color: Colors.yellow,
                            ),
                          ],
                        )),
                    Container(width: (MediaQuery.of(context).size.width) * 0.768,
                        alignment: Alignment.center,child: Container(
                            child: Center(child: PlayerButtons(_audioPlayer)))),
                    Container(
                      height: (MediaQuery.of(context).size.height - appbar - statusbarT - statusbarB) * 0.1,
                      width: (MediaQuery.of(context).size.width) * 0.116, //alignment: Alignment.center,color: Colors.lightBlueAccent[100],
                    ),
                  ],
                ),
              ),
              // piano area
              Container(height: (MediaQuery.of(context).size.height - appbar - statusbarT - statusbarB) * 0.004,
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12,
                  width: 0.5.w,),)),),
              const SizedBox(height: 2),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white, width: 0.9.w,),)),
                  height: (MediaQuery.of(context).size.height - appbar - statusbarT - statusbarB) * 0.29, //color: Colors.blue,
                  child: ListView.builder(
                    itemCount: 6,
                    scrollDirection: Axis.horizontal,
                    controller: ScrollController(initialScrollOffset: 1030.0),
                    itemBuilder: (BuildContext context, int index) {
                      final int i = index * 12;
                      return Stack(
                          children: <Widget>[
                            Row(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _buildKey(24 + i, false),
                                  _buildKey(26 + i, false),
                                  _buildKey(28 + i, false),
                                  _buildKey(29 + i, false),
                                  _buildKey(31 + i, false),
                                  _buildKey(33 + i, false),
                                  _buildKey(35 + i, false),
                                ]),
                            Positioned(
                                left: 0.0,
                                right: 0.0,
                                bottom: (MediaQuery.of(context).size.height - appbar - statusbarT -
                                    statusbarB) * 0.125,
                                top: 0.0,
                                child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Container(width: keyWidth * .5),
                                      _buildKey(25 + i, true),
                                      _buildKey(27 + i, true),
                                      Container(width: keyWidth),
                                      _buildKey(30 + i, true),
                                      _buildKey(32 + i, true),
                                      _buildKey(34 + i, true),
                                      Container(width: keyWidth * .5),
                                    ])),
                          ]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  void dispose() {
    super.dispose();
    SoundGenerator.release();
    _audioPlayer.dispose();
  }

  @override
  void initState() {
    super.initState();
    isPlaying = false;
    //final flutterMidi = FlutterMidi();
    _init();
    SoundGenerator.init(sampleRate);

    SoundGenerator.onIsPlayingChanged.listen((value) {
      setState(() {
        isPlaying = value;
      });
    });

    SoundGenerator.onOneCycleDataHandler.listen((value) {
      setState(() {
        oneCycleData = value;
      });
    });

    SoundGenerator.setAutoUpdateOneCycleSample(true);
    //Force update for one time
    SoundGenerator.refreshOneCycleData();
    //SoundGenerator.play();
    //SoundGenerator.stop();

    setupMIDIPlugin();
    getPermission();

    _audioPlayer = AudioPlayer();
    _audioPlayer
        .setAudioSource(ConcatenatingAudioSource(children: [
      //AudioSource.uri(Uri.parse('asset:///${song.url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[0].url}'),),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[2].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[4].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[5].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[7].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[9].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[11].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[12].url}')),

      AudioSource.uri(Uri.parse('asset:///${Song.songs[0].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[1].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[2].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[3].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[4].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[5].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[6].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[7].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[8].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[9].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[10].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[11].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[12].url}')),

      AudioSource.uri(Uri.parse('asset:///${Song.songs[12].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[25].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[26].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[27].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[28].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[29].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[30].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[31].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[32].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[33].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[34].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[35].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[36].url}')),

      AudioSource.uri(Uri.parse('asset:///${Song.songs[13].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[14].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[15].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[16].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[17].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[18].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[19].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[20].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[21].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[22].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[23].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[24].url}')),
      AudioSource.uri(Uri.parse('asset:///${Song.songs[0].url}')),

    ]))
        .catchError((error) {
      // catch load errors: 404, invalid url ...
      print("An error occured $error");
    });
  }

  Widget _buildKey(int midi, bool accidental) {
    final pitchName = Pitch.fromMidiNumber(midi).toString();
    final pianoKey = Stack(
      children: <Widget>[
        Semantics(
            button: true,
            hint: pitchName,
            child: Material(
                borderRadius: borderRadius,
                color: accidental
                    ? const Color(0xfffef6eb)
                    : const Color(0xff1f212a), //Color(0xff1f212a),
                child: InkWell(
                  borderRadius: borderRadius as BorderRadius,
                  highlightColor: Colors.grey,
                  onTap: (){
                    {

                      //flutterMidi.playMidiNote(midi: midi);
                      play(midi);
                      Timer(Duration(milliseconds: 500), () {
                        //flutterMidi.stopMidiNote(midi: midi);
                        stop(midi);
                      });}},
                ))),
        Positioned(
            left: 0.0,
            right: 0.0,
            bottom: 20.0,
            child: _showLabels
                ? Text(pitchName,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: !accidental
                        ? Colors.white
                        : const Color(0xff1f222a)))
                : Container()),
      ],
    );
    if (accidental) {
      return Container(
          width: keyWidth,
          //color: Colors.black,
          margin: REdgeInsets.symmetric(horizontal: 2.0),
          padding: REdgeInsets.symmetric(horizontal: keyWidth * .02),
          child: Material(
              elevation: 6.0,
              borderRadius: borderRadius,
              shadowColor: const Color(0x802196F3),
              child: pianoKey));
    }

    return Container(
        width: keyWidth,
        margin: REdgeInsets.symmetric(horizontal: 1.8),
        child: pianoKey);
  }

  BorderRadiusGeometry borderRadius = const BorderRadius.only(
      bottomLeft: Radius.circular(10.0), bottomRight: Radius.circular(10.0));

}


