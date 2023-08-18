
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:icofont_flutter/icofont_flutter.dart';
import 'package:sound_generator/sound_generator.dart';
import 'package:sound_generator/waveTypes.dart';
import 'AppOpenAdManager.dart';
import 'MyTune.dart';




class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

final BannerAd _banner = BannerAd(
    adUnitId: 'ca-app-pub-4121141258139669/9812125115',
    size: AdSize.banner,
    request: AdRequest(),
    listener: BannerAdListener(
      // Called when an ad is successfully received.
      onAdLoaded: (Ad ad) => print('Ad loaded.'),
      // Called when an ad request failed.
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        // Dispose the ad here to free resources.
        ad.dispose();
        print('Ad failed to load: $error');
      },
      // Called when an ad opens an overlay that covers the screen.
      onAdOpened: (Ad ad) => print('Ad opened.'),
      // Called when an ad removes an overlay that covers the screen.
      onAdClosed: (Ad ad) => print('Ad closed.'),
      // Called when an impression occurs on the ad.
      onAdImpression: (Ad ad) => print('Ad impression.'),
    )
)..load();


class _HomeState extends State<Home> with WidgetsBindingObserver{

  AppOpenAdManager appOpenAdManager = AppOpenAdManager();
  bool isPaused = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    appOpenAdManager.loadAd();
    WidgetsBinding.instance.addObserver(this);
  }


  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      isPaused = true;
    }
    if (state == AppLifecycleState.resumed && isPaused) {
      print("Resumed==========================");
      appOpenAdManager.showAdIfAvailable();
      isPaused = false;
    }
  }

  void onError(Object e) {
    print(e);
  }

  @override
  Widget build(BuildContext context) {
    TargetPlatform os = Theme.of(context).platform;

    ScreenUtil.init(context, designSize: const Size(411.4, 683.4));
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
    var appbar = appbarWidget.preferredSize.height;
    var statusbarT = MediaQuery.of(context).padding.top;
    var statusbarB = MediaQuery.of(context).padding.bottom;
    double widthRatio = 0.6;
    bool showLabels = true;
    waveTypes waveType = waveTypes.SINUSOIDAL;
    var presscount = 0;

    return MaterialApp(
      title: tr("Singing&Ear Training"),
      debugShowCheckedModeBanner: false,

      home: WillPopScope(
        onWillPop: () async {
          presscount++;

          if (presscount == 1) {
            exit(0);
          } else {
            var snackBar =
            SnackBar(content: Text('press another time to exit from app'));
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            return false;
          }
        },
        child: Scaffold(
          body: MyTune(appbar: appbar,),
          bottomNavigationBar:Container(
            alignment: Alignment.center,
            child: AdWidget(ad: _banner,),
            width: _banner.size.width.toDouble(),
            height: _banner.size.height.toDouble(),
          ),
          // This trailing comma makes auto-formatting nicer for build methods.
        ),
      ),
    );
  }
}








