
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'constants.dart';

class PlayerButtons extends StatelessWidget {
  const PlayerButtons(this._audioPlayer, {Key? key}) : super(key: key);

  final AudioPlayer _audioPlayer;





  @override
  Widget build(BuildContext context) {
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
    return
        Container(
          height: (MediaQuery.of(context).size.height -
              appbarWidget.preferredSize.height -
              MediaQuery.of(context).padding.top -
              MediaQuery.of(context).padding.bottom) *
              0.1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:CrossAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.volume_up),
                onPressed: () {
                  showSliderDialog(
                    context: context,
                    title: tr("Adjust Volume"),
                    divisions: 10,
                    min: 0.0,
                    max: 1.5,
                    value: _audioPlayer.volume,
                    stream: _audioPlayer.volumeStream,
                    onChanged: _audioPlayer.setVolume,
                  );
                },
              ),
              StreamBuilder<bool>(
                stream: _audioPlayer.shuffleModeEnabledStream,
                builder: (context, snapshot) {
                  return _shuffleButton(context, snapshot.data ?? false);
                },
              ),
              StreamBuilder<PlayerState>(
                stream: _audioPlayer.playerStateStream,
                builder: (_, snapshot) {
                  final playerState = snapshot.data;
                  return _playPauseButton(playerState);
                },
              ),
              StreamBuilder<LoopMode>(
                stream: _audioPlayer.loopModeStream,
                builder: (context, snapshot) {
                  return _repeatButton(context, snapshot.data ?? LoopMode.off);
                },
              ),
              StreamBuilder<double>(
                stream: _audioPlayer.speedStream,
                builder: (context, snapshot) => IconButton(
                  icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showSliderDialog(
                      context: context,
                      title: tr("Adjust speed"),
                      divisions: 10,
                      min: 0.0,
                      max: 1.5,
                      value: _audioPlayer.speed,
                      stream: _audioPlayer.speedStream,
                      onChanged: _audioPlayer.setSpeed,
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }

  Widget _playPauseButton(PlayerState? playerState) {
    if (playerState == null)
      {
        return IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(Icons.play_arrow,),
          iconSize: 45.0,
          onPressed: () => _audioPlayer.seek(Duration.zero,
              index: _audioPlayer.effectiveIndices!.first),
        );
      }
    final processingState = playerState!.processingState;
  if (_audioPlayer.playing != true) {
      return IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.play_arrow),
        iconSize: 45.0,
        onPressed: _audioPlayer.play,
      );
    } else if (processingState != ProcessingState.completed) {
      return IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.pause),
        iconSize: 45.0,
        onPressed: _audioPlayer.pause,
      );
    } else {
      return IconButton(
        padding: EdgeInsets.zero,
        icon: Icon(Icons.play_arrow,),
        iconSize: 45.0,
        onPressed: () => _audioPlayer.seek(Duration.zero,
            index: _audioPlayer.effectiveIndices!.first),
      );
    }
  }

  Widget _shuffleButton(BuildContext context, bool isEnabled) {
    return IconButton(
      icon: isEnabled
          ? Icon(Icons.shuffle, color: Theme.of(context).colorScheme.secondary)
          : Icon(Icons.shuffle),
      onPressed: () async {
        final enable = !isEnabled;
        if (enable) {
          await _audioPlayer.shuffle();
        }
        await _audioPlayer.setShuffleModeEnabled(enable);
      },
    );
  }

  Widget _previousButton() {
    return IconButton(
      icon: Icon(Icons.skip_previous),
      onPressed: _audioPlayer.hasPrevious ? _audioPlayer.seekToPrevious : null,
    );
  }

  Widget _nextButton() {
    return IconButton(
      icon: Icon(Icons.skip_next),
      onPressed: _audioPlayer.hasNext ? _audioPlayer.seekToNext : null,
    );
  }

  Widget _repeatButton(BuildContext context, LoopMode loopMode) {
    final icons = [
      Icon(Icons.repeat),
      Icon(Icons.repeat, color: Theme.of(context).colorScheme.secondary),
      Icon(Icons.repeat_one, color: Theme.of(context).colorScheme.secondary),
    ];
    const cycleModes = [
      LoopMode.off,
      LoopMode.all,
      LoopMode.one,
    ];
    final index = cycleModes.indexOf(loopMode);
    return IconButton(
      icon: icons[index],
      onPressed: () {
        _audioPlayer.setLoopMode(
            cycleModes[(cycleModes.indexOf(loopMode) + 1) % cycleModes.length]);
      },
    );
  }

  void showSliderDialog({
     required BuildContext context,
     required String title,
     required int divisions,
     required double min,
     required double max,
    String valueSuffix = '',
    // TODO: Replace these two by ValueStream.
     required double value,
     required Stream<double> stream,
     required ValueChanged<double> onChanged,
  }) {
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
    showDialog<void>(
      context: context,
      builder: (context) => Column(
        children: [
          SizedBox(height: (MediaQuery.of(context).size.height - appbarWidget.preferredSize.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom) * 0.19,),
          Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Constants.padding),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
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
              child: StreamBuilder<double>(
                stream: stream,
                builder: (context, snapshot) => Container(
                  height: 130,
                  width: 200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: TextStyle(fontSize: 24,fontWeight: FontWeight.w600),textAlign: TextAlign.center),
                      SizedBox(height: 8,),
                      Text('${snapshot.data?.toStringAsFixed(1)}$valueSuffix',
                          style: const TextStyle(
                              fontFamily: 'Fixed',
                              fontWeight: FontWeight.w500,color: Color(0xFF1E88E5),
                              fontSize: 20.0)),
                      Slider(
                        divisions: divisions,
                        min: min,
                        max: max,
                        value: snapshot.data ?? value,
                        onChanged: onChanged,
                        inactiveColor: Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ),

            ),
          ),
        ],
      )
    );
  }
}
