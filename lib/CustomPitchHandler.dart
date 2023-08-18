
import 'package:pitchupdart/instrument_type.dart';
import 'dart:math';

enum TuningStatus { tuned, toolow, toohigh, waytoolow, waytoohigh, undefined, high2, high4, low2, low4}

class PitchResult {
  final String note;
  final TuningStatus tuningStatus;
  final double expectedFrequency;
  final double diffFrequency;
  final double diffCents;

  PitchResult(this.note, this.tuningStatus, this.expectedFrequency,
      this.diffFrequency, this.diffCents);
}

class CustomPitchHandler {
  final InstrumentType _instrumentType;
  dynamic _minimumPitch;
  dynamic _maximumPitch;
  dynamic _noteStrings;

  CustomPitchHandler(this._instrumentType) {
    switch (_instrumentType) {
      case InstrumentType.guitar:
        _minimumPitch = 80.0;
        _maximumPitch = 1050.0;
        _noteStrings = [
          "C",
          "C#",
          "D",
          "D#",
          "E",
          "F",
          "F#",
          "G",
          "G#",
          "A",
          "A#",
          "B"
        ];
        break;
    }
  }

  PitchResult handlePitch(double pitch) {
    if (_isPitchInRange(pitch)) {
      final noteLiteral = _noteFromPitch(pitch);
      final expectedFrequency = _frequencyFromNoteNumber(_midiFromPitch(pitch));
      final diff = _diffFromTargetedNote(pitch);
      final tuningStatus = _getTuningStatus(diff);
      final diffCents =
      _diffInCents(expectedFrequency, expectedFrequency - diff);

      return PitchResult(
          noteLiteral, tuningStatus, expectedFrequency, diff, diffCents);
    }

    return PitchResult("", TuningStatus.undefined, 0.00, 0.00, 0.00);
  }

  bool _isPitchInRange(double pitch) {
    return pitch > _minimumPitch && pitch < _maximumPitch;
  }

  String _noteFromPitch(double frequency) {
    final noteNum = 12.0 * (log((frequency / 440.0)) / log(2.0));
    return _noteStrings[
    (((noteNum.roundToDouble() + 69.0).toInt() % 12.0).toInt())]+((noteNum.roundToDouble() + 69.0).toInt() ~/ 12 - 1).toString();
  }

  double _diffFromTargetedNote(double pitch) {
    final targetPitch = _frequencyFromNoteNumber(_midiFromPitch(pitch));
    return targetPitch - pitch;
  }

  double _diffInCents(double expectedFrequency, double frequency) {
    return 1200.0 * log(expectedFrequency / frequency);
  }

  TuningStatus _getTuningStatus(double diff) {
    if (diff >= -6.2 && diff <= 4.0) {
      return TuningStatus.tuned;
      //} else if (diff > -1.4 && diff/+1
    } else if (diff >= -6.3 && diff < -6.2) {
      return TuningStatus.high2; //+2
    } else if (diff >= -7.9 && diff < -6.3) {
      return TuningStatus.toohigh; //+3
    } else if (diff >= -8.0 && diff < -7.9) {
      return TuningStatus.high4; //+4
      //} else if (diff > 1.3 && diff < 1.4) {
      //   return TuningStatus.low1; //-1
    } else if (diff > 4.0 && diff <= 4.1) {
      return TuningStatus.low2; //-2
    } else if (diff > 4.1 && diff <= 5.9) {
      return TuningStatus.toolow; //-3
    } else if (diff > 5.9 && diff <= 6.0) {
      return TuningStatus.low4; //-4
    } else if (diff >= double.negativeInfinity && diff < -8.0) {
      //+5-5
      return TuningStatus.waytoohigh;
    } else {
      return TuningStatus.waytoolow;
    }
  }



  int _midiFromPitch(double frequency) {
    final noteNum = 12.0 * (log((frequency / 440.0)) / log(2.0));
    return (noteNum.roundToDouble() + 69.0).toInt();
  }

  double _frequencyFromNoteNumber(int note) {
    final exp = (note - 69.0).toDouble() / 12.0;
    return (440.0 * pow(2.0, exp)).toDouble();
  }
}