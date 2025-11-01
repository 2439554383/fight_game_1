import 'package:audioplayers/audioplayers.dart';

/// 简化的音频控制器，用于播放背景音乐
class AudioController {
  AudioPlayer? _musicPlayer;
  bool _isPlaying = false;
  bool _isInitialized = false;

  /// 初始化音频播放器
  Future<void> _initialize() async {
    if (_isInitialized) return;
    
    try {
      _musicPlayer = AudioPlayer(playerId: 'musicPlayer');
      _isInitialized = true;
    } catch (e) {
      print('初始化音频播放器失败: $e');
      _isInitialized = false;
    }
  }

  /// 播放背景音乐
  Future<void> playBackgroundMusic(String musicPath) async {
    try {
      // 确保已初始化
      await _initialize();
      
      if (!_isInitialized || _musicPlayer == null) {
        print('音频播放器未初始化，跳过播放');
        return;
      }
      
      if (!_isPlaying) {
        // 先设置循环模式，再播放
        await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer!.play(AssetSource(musicPath));
        _isPlaying = true;
      }
    } catch (e) {
      print('播放背景音乐失败: $e');
      // 如果播放失败，重置状态
      _isPlaying = false;
    }
  }

  /// 停止背景音乐
  Future<void> stopBackgroundMusic() async {
    try {
      if (_musicPlayer != null) {
        await _musicPlayer!.stop();
        _isPlaying = false;
      }
    } catch (e) {
      print('停止背景音乐失败: $e');
    }
  }

  /// 暂停背景音乐
  Future<void> pauseBackgroundMusic() async {
    try {
      if (_musicPlayer != null) {
        await _musicPlayer!.pause();
      }
    } catch (e) {
      print('暂停背景音乐失败: $e');
    }
  }

  /// 恢复背景音乐
  Future<void> resumeBackgroundMusic() async {
    try {
      if (_musicPlayer != null) {
        await _musicPlayer!.resume();
      }
    } catch (e) {
      print('恢复背景音乐失败: $e');
    }
  }

  /// 释放资源
  void dispose() {
    _musicPlayer?.dispose();
    _musicPlayer = null;
    _isInitialized = false;
  }
}

