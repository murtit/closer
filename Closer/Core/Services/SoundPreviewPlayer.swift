import AVFoundation

/// Plays a notification sound once, so it can be heard while choosing it.
final class SoundPreviewPlayer {
    private let bundle: Bundle
    private var player: AVAudioPlayer?

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// URL of the sound's file in the bundle, `nil` for the system default or a missing file.
    func url(for sound: NotificationSound) -> URL? {
        guard let fileName = sound.fileName else { return nil }
        let name = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        return bundle.url(forResource: name, withExtension: ext)
    }

    /// Plays `sound` from the start, stopping any preview still playing. Does nothing for the
    /// system default, which apps cannot play.
    func play(_ sound: NotificationSound) {
        stop()
        guard let url = url(for: sound) else { return }
        // Playback, so the preview is audible with the ring/silent switch on silent; mixing, so
        // music from another app keeps playing.
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stop() {
        player?.stop()
        player = nil
    }
}
