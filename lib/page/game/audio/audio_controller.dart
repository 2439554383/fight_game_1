import 'package:flame_audio/flame_audio.dart';

/// 使用 Flame 自带音频系统的音频控制器
class AudioController {
  bool _isPlaying = false;

  /// 播放背景音乐（循环播放）
  /// [musicPath] 音频文件路径，相对于 assets/audio/ 目录
  /// [volume] 音量，范围 0.0 - 1.0，默认 0.5
  Future<void> playBackgroundMusic(
    String musicPath, {
    double volume = 0.5,
  }) async {
    try {
      if (!_isPlaying) {
        // 使用 Flame 的 bgm（背景音乐）系统播放，自动循环
        await FlameAudio.bgm.play(musicPath, volume: volume);
        _isPlaying = true;
      }
    } catch (e) {
      print('播放背景音乐失败: $e');
      _isPlaying = false;
    }
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      await FlameAudio.bgm.stop();
      _isPlaying = false;
    } catch (e) {
      print('停止背景音乐失败: $e');
    }
  }

  /// 暂停背景音乐
  Future<void> pauseBackgroundMusic() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (e) {
      print('暂停背景音乐失败: $e');
    }
  }

  /// 恢复背景音乐
  Future<void> resumeBackgroundMusic() async {
    try {
      await FlameAudio.bgm.resume();
    } catch (e) {
      print('恢复背景音乐失败: $e');
    }
  }

  /// 播放音效（一次性播放）
  /// [soundPath] 音频文件路径，相对于 assets/audio/ 目录
  /// [volume] 音量，范围 0.0 - 1.0，默认 1.0
  Future<void> playSound(String soundPath, {double volume = 1.0}) async {
    try {
      await FlameAudio.play(soundPath, volume: volume);
    } catch (e) {
      print('播放音效失败: $e');
    }
  }

  /// 释放资源
  Future<void> dispose() async {
    try {
      await stopBackgroundMusic();
      await FlameAudio.bgm.dispose();
    } catch (e) {
      print('释放音频资源失败: $e');
    }
  }
}
