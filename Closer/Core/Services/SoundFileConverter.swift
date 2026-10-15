import AVFoundation

/// Turns any audio file iOS can read (MP3, M4A, WAV, AIFF, …) into a notification sound: 16 bit
/// linear PCM in a CAF file, cut to under 30 seconds with a short fade-out at the cut.
nonisolated enum SoundFileConverter {
    /// iOS plays the default sound instead of one that is 30 seconds or longer.
    static let maxDuration: TimeInterval = 29.5
    static let fadeOutDuration: TimeInterval = 0.5

    enum ConversionError: Error {
        case empty
        case tooManyChannels
    }

    /// Converts `source` and writes it to `destination` (a `.caf` URL). Returns the length of the
    /// written sound in seconds. Leaves no file behind when it throws.
    @discardableResult
    static func convert(_ source: URL, to destination: URL, maxDuration: TimeInterval = maxDuration) throws -> TimeInterval {
        do {
            return try write(source, to: destination, maxDuration: maxDuration)
        } catch {
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    private static func write(_ source: URL, to destination: URL, maxDuration: TimeInterval) throws -> TimeInterval {
        let input = try AVAudioFile(forReading: source)
        let format = input.processingFormat
        let rate = format.sampleRate
        guard format.channelCount <= 2 else { throw ConversionError.tooManyChannels }

        let maxFrames = AVAudioFramePosition(maxDuration * rate)
        let total = min(input.length, maxFrames)
        guard total > 0 else { throw ConversionError.empty }
        let fadeFrames = input.length > maxFrames ? AVAudioFramePosition(fadeOutDuration * rate) : 0

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: rate,
            AVNumberOfChannelsKey: format.channelCount,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
        ]
        try? FileManager.default.removeItem(at: destination)
        let output = try AVAudioFile(
            forWriting: destination,
            settings: settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )

        let chunk: AVAudioFrameCount = 32_768
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: chunk) else { throw ConversionError.empty }
        var position: AVAudioFramePosition = 0
        while position < total {
            try input.read(into: buffer, frameCount: AVAudioFrameCount(min(AVAudioFramePosition(chunk), total - position)))
            guard buffer.frameLength > 0 else { break }
            if fadeFrames > 0 {
                fadeOut(buffer, startingAt: position, total: total, fadeFrames: fadeFrames)
            }
            try output.write(from: buffer)
            position += AVAudioFramePosition(buffer.frameLength)
        }
        guard position > 0 else { throw ConversionError.empty }
        return Double(position) / rate
    }

    /// Lowers the volume linearly to silence over the last `fadeFrames` frames before `total`.
    private static func fadeOut(_ buffer: AVAudioPCMBuffer, startingAt position: AVAudioFramePosition, total: AVAudioFramePosition, fadeFrames: AVAudioFramePosition) {
        guard let channels = buffer.floatChannelData else { return }
        for frame in 0..<Int(buffer.frameLength) {
            let remaining = total - position - AVAudioFramePosition(frame)
            guard remaining < fadeFrames else { continue }
            let gain = Float(max(0, remaining)) / Float(fadeFrames)
            for channel in 0..<Int(buffer.format.channelCount) {
                channels[channel][frame] *= gain
            }
        }
    }
}
