
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sound_generator/sound_generator.dart';

import 'constants.dart';

class CustomDialogBox extends StatefulWidget {
  final String title;
  final String? text;
  final Image? img;

  const CustomDialogBox({Key? key, required this.title,  this.text = "", this.img = null}) : super(key: key);

  @override
  _CustomDialogBoxState createState() => _CustomDialogBoxState();
}

class _CustomDialogBoxState extends State<CustomDialogBox> {
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
  double volume =0.2;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: (MediaQuery.of(context).size.height - appbarWidget.preferredSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom) * 0.08,),
        Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Constants.padding),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: contentBox(context),
        ),
      ],
    );
  }
  contentBox(context){
    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.only(left: Constants.padding,top: Constants.avatarRadius
              + Constants.padding, right: Constants.padding,bottom: Constants.padding
          ),
          margin: EdgeInsets.only(top: Constants.avatarRadius),
          decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(Constants.padding),
              boxShadow: [
                BoxShadow(color: Colors.black,offset: Offset(0,10),
                    blurRadius: 10
                ),
              ]
          ),
          child: Container(
            height: 130,
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(widget.title,style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600),),
                SizedBox(height: 8,),
                Text(volume.toStringAsFixed(2),
                    style: TextStyle(color: Colors.blue[600],fontWeight: FontWeight.w500,fontSize: 20.0)),
                 Slider(
                    activeColor: Colors.redAccent,
                    inactiveColor: Colors.white,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    value: volume,
                    onChanged: (value) {
                      setState(() {
                        volume = value.toDouble();
                        SoundGenerator.setVolume(volume);});
                    }),
              ],
            ),
          ),
        ),

      ],
    );
  }
}