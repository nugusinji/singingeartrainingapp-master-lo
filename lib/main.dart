import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//import 'package:page_transition/page_transition.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'Home.dart';




final supportedLocales = [Locale('en', 'US'), Locale('ko', 'KR')];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // easylocalization 초기화!
  await EasyLocalization.ensureInitialized();
  runApp(
      EasyLocalization(
          supportedLocales: [Locale('en', 'US'), Locale('ko', 'KR')],
          path: 'assets/translations', // <-- change the path of the translation files
          fallbackLocale: Locale('ko', 'KR'),
          child: MyApp()
      ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);


  Future<bool> init() async {

    await MobileAds.instance.initialize();
    await ScreenUtil.ensureScreenSize();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return true;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.landscapeRight]);

    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      // You can use the library anywhere in the app even in theme
      home: Home(),
    );


  }
}


