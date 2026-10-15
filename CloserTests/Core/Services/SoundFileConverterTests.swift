import AVFoundation
import Testing
@testable import Closer

@MainActor
struct SoundFileConverterTests {
    private func destination() throws -> URL {
        let folder = TestAudio.temporaryFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "out.caf")
    }

    @Test func shortSoundKeepsItsLengthAndBecomes16BitPCM() throws {
        let output = try destination()
        let duration = try SoundFileConverter.convert(try TestAudio.tone(seconds: 2), to: output)

        #expect(abs(duration - 2) < 0.01)
        let file = try AVAudioFile(forReading: output)
        let description = file.fileFormat.streamDescription.pointee
        #expect(description.mFormatID == kAudioFormatLinearPCM)
        #expect(description.mBitsPerChannel == 16)
    }

    @Test func longSoundIsCutBelowThirtySecondsAndFadesOut() throws {
        let output = try destination()
        let duration = try SoundFileConverter.convert(try TestAudio.tone(seconds: 40), to: output)

        #expect(duration == SoundFileConverter.maxDuration)
        let file = try AVAudioFile(forReading: output)
        #expect(Double(file.length) / file.fileFormat.sampleRate < 30)

        let tailFrames: AVAudioFrameCount = 100
        file.framePosition = file.length - AVAudioFramePosition(tailFrames)
        let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: tailFrames)!
        try file.read(into: buffer)
        let tail = (0..<Int(buffer.frameLength)).map { abs(buffer.floatChannelData![0][$0]) }
        #expect(tail.max()! < 0.01)
    }

    @Test func stereoStaysStereo() throws {
        let output = try destination()
        try SoundFileConverter.convert(try TestAudio.tone(seconds: 1, channels: 2), to: output)
        #expect(try AVAudioFile(forReading: output).fileFormat.channelCount == 2)
    }

    @Test func fileThatIsNoAudioFailsAndLeavesNothingBehind() throws {
        let folder = TestAudio.temporaryFolder()
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let text = folder.appending(path: "notiz.mp3")
        try Data("keine Musik".utf8).write(to: text)
        let output = folder.appending(path: "out.caf")

        #expect(throws: (any Error).self) { try SoundFileConverter.convert(text, to: output) }
        #expect(!FileManager.default.fileExists(atPath: output.path()))
    }
}
