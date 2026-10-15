import AVFoundation

/// Plays a notification sound once, so it can be heard while choosing it.
final class SoundPreviewPlayer {
    private var player: AVAudioPlayer?

    /// Plays the file at `url` from the start, stopping any preview still playing. Does nothing
    /// for `nil`, e.g. the system default, which apps cannot play.
    func play(_ url: URL?) {
        stop()
        guard let url else { return }
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
