import Foundation
import UIKit
import AVFoundation

struct AudioPlayerSoundInfo {
    let type: AudioPlayerSoundType
    let timeInterval: TimeInterval
}

enum AudioPlayerSoundType {
    case beep
}


class AudioViewController: UIViewController {
    
    // var id = 1000
    var id = 1150
    
    override func viewDidLoad() {
        let info = AudioPlayerSoundInfo(
            type: .beep,
            timeInterval: 2
        )
        self.view.backgroundColor = .white
        let soundTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true,
            block: { timer in
                switch info.type {
                case .beep:
                    let soundId = SystemSoundID(self.id)
                    print("playing sound ", String(describing: soundId))
                    AudioServicesPlaySystemSound(soundId)
                }
            })
        soundTimer.fire()
        
    }
    
    
}
