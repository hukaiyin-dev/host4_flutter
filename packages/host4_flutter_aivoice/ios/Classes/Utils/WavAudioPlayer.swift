import UIKit
import AVFoundation

/// WAV 音频播放器
class WavAudioPlayer: NSObject {

  static var player: AVAudioPlayer?

  static func play(audioName: String) {
    let bundle = Bundle.main
    guard let url = bundle.url(forResource: audioName, withExtension: "WAV") ?? 
                    Bundle.main.url(forResource: audioName, withExtension: "WAV") else {
      print("[WavAudio] ❌ 找不到音频文件: \(audioName)")
      return
    }

    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.prepareToPlay()
      player?.play()
      print("[WavAudio] ✅ 播放: \(audioName)")
    } catch {
      print("[WavAudio] ❌ 播放失败: \(error.localizedDescription)")
    }
  }
}
