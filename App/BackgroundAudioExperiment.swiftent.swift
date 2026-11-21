import AVFoundation

/// Experimental execution aid only. It does not grant pasteboard access.
@MainActor
final class BackgroundAudioExperiment {
    private var player: AVAudioPlayer?
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        var data = Data()
        func ascii(_ value: String) { data.append(contentsOf: value.utf8) }
        func u16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func u32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        ascii("RIFF"); u32(16036); ascii("WAVEfmt "); u32(16)
        u16(1); u16(1); u32(8000); u32(16000); u16(2); u16(16)
        ascii("data"); u32(16000); data.append(Data(repeating: 0, count: 16000))
        player = try AVAudioPlayer(data: data)
        player?.numberOfLoops = -1
        guard player?.play() == true else { throw CocoaError(.featureUnsupported) }
    }
    func stop() {
        player?.stop(); player = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
