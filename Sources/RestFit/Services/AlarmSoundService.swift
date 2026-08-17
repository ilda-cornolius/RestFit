import Foundation
import SwiftUI

enum AlarmSoundService {
    #if SKIP
    private static var player: android.media.MediaPlayer? = nil
    #endif

    static func startLoopingAlarm() {
        #if SKIP
        stop()
        guard let context = UIApplication.shared.androidActivity else { return }
        let uri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
            ?? android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_RINGTONE)
            ?? android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
        guard let uri else { return }

        let mediaPlayer = android.media.MediaPlayer()
        mediaPlayer.setDataSource(context, uri)
        mediaPlayer.isLooping = true
        mediaPlayer.setAudioAttributes(
            android.media.AudioAttributes.Builder()
                .setUsage(android.media.AudioAttributes.USAGE_ALARM)
                .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()
        )
        mediaPlayer.prepare()
        mediaPlayer.start()
        player = mediaPlayer
        #endif
    }

    static func previewAlarm() {
        #if SKIP
        stop()
        guard let context = UIApplication.shared.androidActivity else { return }
        let uri = android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_ALARM)
            ?? android.media.RingtoneManager.getDefaultUri(android.media.RingtoneManager.TYPE_NOTIFICATION)
        guard let uri else { return }
        let ringtone = android.media.RingtoneManager.getRingtone(context, uri)
        ringtone?.play()
        #endif
    }

    static func stop() {
        #if SKIP
        player?.stop()
        player?.release()
        player = nil
        #endif
    }
}

@MainActor
@Observable final class AlarmRingController {
    static let shared = AlarmRingController()
    var isRinging: Bool = false
    var alarm: AlarmItem?

    func present(_ alarm: AlarmItem) {
        guard !isRinging else { return }
        self.alarm = alarm
        AlarmSoundService.startLoopingAlarm()
        withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
            isRinging = true
        }
    }

    func dismiss() {
        AlarmSoundService.stop()
        withAnimation(.spring(response: 0.42, dampingFraction: 0.9)) {
            isRinging = false
        }
        alarm = nil
    }
}
