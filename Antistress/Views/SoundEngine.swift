import AVFoundation
import Combine

// MARK: - SoundType
enum SoundType: String, CaseIterable, Identifiable {
    case white = "White"
    case brown = "Brown"
    case grey  = "Grey"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
}

// MARK: - SoundEngine
class SoundEngine: ObservableObject {
    @Published var isPlaying = false
    @Published var currentType: SoundType = .white
    @Published var volume: Float = 0.5
    @Published var tone: Float = 0.5
    
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var eqNode: AVAudioUnitEQ?
    private var buffer: AVAudioPCMBuffer?
    
    private let sampleRate: Double = 44100
    private let bufferSize: AVAudioFrameCount = 44100 * 5
    
    private var brownNoiseLastOutput: Float = 0
    
    init() {
        configureAudioSession()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Audio Session
    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    // MARK: - Play / Stop
    func play() {
        stop()
        
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let eq = AVAudioUnitEQ(numberOfBands: 1)
        
        let band = eq.bands[0]
        band.filterType = .lowPass
        band.frequency = mappedCutoff
        band.bandwidth = 1.0
        band.bypass = false
        
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1
        )!
        
        engine.attach(player)
        engine.attach(eq)
        engine.connect(player, to: eq, format: format)
        engine.connect(eq, to: engine.mainMixerNode, format: format)
        
        let buf = generateBuffer(type: currentType, format: format)
        
        do {
            try engine.start()
            player.play()
            player.scheduleBuffer(buf, at: nil, options: .loops)
            player.volume = volume
            
            self.audioEngine = engine
            self.playerNode = player
            self.eqNode = eq
            self.buffer = buf
            self.isPlaying = true
        } catch {
            print("Engine start error: \(error)")
        }
    }
    
    func stop() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        eqNode = nil
        buffer = nil
        isPlaying = false
        brownNoiseLastOutput = 0
    }
    
    // MARK: - Live Parameter Updates
    func updateVolume(_ v: Float) {
        volume = v
        playerNode?.volume = v
    }
    
    func updateTone(_ t: Float) {
        tone = t
        eqNode?.bands[0].frequency = mappedCutoff
    }
    
    func switchType(_ type: SoundType) {
        currentType = type
        if isPlaying {
            play()
        }
    }
    
    // MARK: - Cutoff Mapping
    private var mappedCutoff: Float {
        let minF: Float = 200
        let maxF: Float = 8000
        return minF * pow(maxF / minF, tone)
    }
    
    // MARK: - Buffer Generation
    private func generateBuffer(type: SoundType, format: AVAudioFormat) -> AVAudioPCMBuffer {
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize)!
        buf.frameLength = bufferSize
        
        guard let data = buf.floatChannelData?[0] else { return buf }
        
        brownNoiseLastOutput = 0
        
        switch type {
        case .white:
            for i in 0..<Int(bufferSize) {
                data[i] = Float.random(in: -0.3...0.3)
            }
            
        case .brown:
            for i in 0..<Int(bufferSize) {
                let white = Float.random(in: -1...1)
                brownNoiseLastOutput = (brownNoiseLastOutput + (0.02 * white))
                brownNoiseLastOutput = max(-1, min(1, brownNoiseLastOutput))
                data[i] = brownNoiseLastOutput * 0.8
            }
            
        case .grey:
            var phase1: Float = 0
            var phase2: Float = 0
            var phase3: Float = 0
            var phase4: Float = 0
            let freq1: Float = 0.17
            let freq2: Float = 0.073
            let freq3: Float = 0.031
            let freq4: Float = 0.0091
            
            var dropTimer: Float = 0
            var nextDrop: Float = Float.random(in: 0.005...0.03)
            
            for i in 0..<Int(bufferSize) {
                let white = Float.random(in: -0.2...0.2)
                
                let mod1 = 0.5 + 0.3 * sin(phase1)
                let mod2 = 0.7 + 0.2 * sin(phase2)
                let mod3 = 0.8 + 0.15 * sin(phase3)
                let mod4 = 0.85 + 0.1 * sin(phase4)
                let envelope = mod1 * mod2 * mod3 * mod4
                
                var drop: Float = 0
                dropTimer += 1.0 / Float(sampleRate)
                if dropTimer >= nextDrop {
                    drop = Float.random(in: -0.08...0.08)
                    dropTimer = 0
                    nextDrop = Float.random(in: 0.008...0.05)
                }
                
                data[i] = (white * envelope + drop) * 0.65
                
                phase1 += (2 * .pi * freq1) / Float(sampleRate)
                phase2 += (2 * .pi * freq2) / Float(sampleRate)
                phase3 += (2 * .pi * freq3) / Float(sampleRate)
                phase4 += (2 * .pi * freq4) / Float(sampleRate)
                if phase1 > 2 * .pi { phase1 -= 2 * .pi }
                if phase2 > 2 * .pi { phase2 -= 2 * .pi }
                if phase3 > 2 * .pi { phase3 -= 2 * .pi }
                if phase4 > 2 * .pi { phase4 -= 2 * .pi }
            }
        }
        
        return buf
    }
}
