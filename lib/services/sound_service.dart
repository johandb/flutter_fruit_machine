import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._();

  static SoundService get instance => _instance;

  factory SoundService() => _instance;

  SoundService._();

  void playSound(String name) async {
    final player = AudioPlayer();
    await player.setSource(AssetSource(name));
    await player.resume();
  }
}
