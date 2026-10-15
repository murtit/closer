import AVFoundation

/// Writes test audio files.
nonisolated enum TestAudio {
    /// A sine tone of `seconds` length as a WAV file in a fresh temporary folder.
    static func tone(seconds: Double, rate: Double = 44_100, channels: AVAudioChannelCount = 1, name: String = "Ton") throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appending(path: "CloserTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let url = folder.appending(path: "\(name).wav")
        let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: channels)!
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        let frames = AVAudioFrameCount(seconds * rate)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames)!
        buffer.frameLength = frames
        for channel in 0..<Int(channels) {
            for frame in 0..<Int(frames) {
                buffer.floatChannelData![channel][frame] = 0.5 * sin(2 * .pi * 880 * Float(frame) / Float(rate))
            }
        }
        try file.write(from: buffer)
        return url
    }

    static func temporaryFolder() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "CloserTests-\(UUID().uuidString)")
    }
}
