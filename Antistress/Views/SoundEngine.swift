import AVFoundation
import Combine

// MARK: - SoundType
enum SoundType: String, CaseIterable, Identifiable {
    case white   = "White"
    case brown   = "Brown"
    case pink    = "Pink"
    case rain    = "Rain"
    case ocean   = "Ocean"
    case storm   = "Storm"
    case wind    = "Wind"
    case stream  = "Stream"
    case fire    = "Fire"
    case forest  = "Forest"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var isFree: Bool {
        switch self {
        case .white, .brown: return true
        default: return false
        }
    }
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
            generateWhite(data)
        case .brown:
            generateBrown(data)
        case .pink:
            generatePink(data)
        case .rain:
            generateRain(data)
        case .ocean:
            generateOcean(data)
        case .storm:
            generateStorm(data)
        case .wind:
            generateWind(data)
        case .stream:
            generateStream(data)
        case .fire:
            generateFire(data)
        case .forest:
            generateForest(data)
        }

        return buf
    }

    // MARK: - White Noise
    private func generateWhite(_ data: UnsafeMutablePointer<Float>) {
        for i in 0..<Int(bufferSize) {
            data[i] = Float.random(in: -0.3...0.3)
        }
    }

    // MARK: - Brown Noise (deep, rumbling)
    private func generateBrown(_ data: UnsafeMutablePointer<Float>) {
        var last: Float = 0
        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -1...1)
            last = (last + (0.02 * white))
            last = max(-1, min(1, last))
            data[i] = last * 0.8
        }
    }

    // MARK: - Pink Noise (balanced, like light rainfall)
    private func generatePink(_ data: UnsafeMutablePointer<Float>) {
        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        var b3: Float = 0, b4: Float = 0, b5: Float = 0, b6: Float = 0
        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -1...1)
            b0 = 0.99886 * b0 + white * 0.0555179
            b1 = 0.99332 * b1 + white * 0.0750759
            b2 = 0.96900 * b2 + white * 0.1538520
            b3 = 0.86650 * b3 + white * 0.3104856
            b4 = 0.55000 * b4 + white * 0.5329522
            b5 = -0.7616 * b5 - white * 0.0168980
            let pink = b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362
            b6 = white * 0.115926
            data[i] = pink * 0.11
        }
    }

    // MARK: - Rain (pink noise + random droplets)
    private func generateRain(_ data: UnsafeMutablePointer<Float>) {
        var b0: Float = 0, b1: Float = 0, b2: Float = 0
        var dropTimer: Float = 0
        var nextDrop: Float = Float.random(in: 0.002...0.015)

        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -0.2...0.2)
            b0 = 0.997 * b0 + white * 0.15
            b1 = 0.965 * b1 + white * 0.25
            b2 = 0.850 * b2 + white * 0.35
            var sample = (b0 + b1 + b2) * 0.4

            // Random drops
            dropTimer += 1.0 / Float(sampleRate)
            if dropTimer >= nextDrop {
                sample += Float.random(in: -0.15...0.15)
                dropTimer = 0
                nextDrop = Float.random(in: 0.003...0.02)
            }

            data[i] = sample * 0.6
        }
    }

    // MARK: - Ocean (slow waves with brown noise base)
    private func generateOcean(_ data: UnsafeMutablePointer<Float>) {
        var last: Float = 0
        var wavePhase: Float = 0
        let waveFreq: Float = 0.08

        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -1...1)
            last = (last + (0.02 * white))
            last = max(-1, min(1, last))

            // Slow wave envelope
            let wave = 0.4 + 0.6 * (0.5 + 0.5 * sin(wavePhase))
            wavePhase += (2 * .pi * waveFreq) / Float(sampleRate)
            if wavePhase > 2 * .pi { wavePhase -= 2 * .pi }

            // Surf texture
            let surf = Float.random(in: -0.05...0.05) * wave
            data[i] = (last * 0.6 * wave + surf) * 0.7
        }
    }

    // MARK: - Storm (deep brown + rain drops + low rumble)
    private func generateStorm(_ data: UnsafeMutablePointer<Float>) {
        var last: Float = 0
        var rumblePhase: Float = 0
        let rumbleFreq: Float = 0.03
        var dropTimer: Float = 0
        var nextDrop: Float = Float.random(in: 0.001...0.01)

        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -1...1)
            last = (last + (0.015 * white))
            last = max(-1, min(1, last))

            // Deep rumble
            let rumble = sin(rumblePhase) * 0.15
            rumblePhase += (2 * .pi * rumbleFreq) / Float(sampleRate)
            if rumblePhase > 2 * .pi { rumblePhase -= 2 * .pi }

            // Heavy rain drops
            var drop: Float = 0
            dropTimer += 1.0 / Float(sampleRate)
            if dropTimer >= nextDrop {
                drop = Float.random(in: -0.2...0.2)
                dropTimer = 0
                nextDrop = Float.random(in: 0.001...0.012)
            }

            data[i] = (last * 0.7 + rumble + drop * 0.4) * 0.65
        }
    }

    // MARK: - Wind (slowly modulated filtered noise)
    private func generateWind(_ data: UnsafeMutablePointer<Float>) {
        var last: Float = 0
        var gustPhase1: Float = 0
        var gustPhase2: Float = 0
        let gustFreq1: Float = 0.12
        let gustFreq2: Float = 0.047

        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -0.3...0.3)
            last = 0.98 * last + white * 0.02

            let gust1 = 0.5 + 0.5 * sin(gustPhase1)
            let gust2 = 0.7 + 0.3 * sin(gustPhase2)
            let envelope = gust1 * gust2

            gustPhase1 += (2 * .pi * gustFreq1) / Float(sampleRate)
            gustPhase2 += (2 * .pi * gustFreq2) / Float(sampleRate)
            if gustPhase1 > 2 * .pi { gustPhase1 -= 2 * .pi }
            if gustPhase2 > 2 * .pi { gustPhase2 -= 2 * .pi }

            let hiss = Float.random(in: -0.1...0.1) * envelope
            data[i] = (last * envelope + hiss) * 0.7
        }
    }

    // MARK: - Stream (bright bubbling with high-freq texture)
    private func generateStream(_ data: UnsafeMutablePointer<Float>) {
        var bubbleTimer: Float = 0
        var nextBubble: Float = Float.random(in: 0.005...0.03)
        var bubbleDecay: Float = 0

        for i in 0..<Int(bufferSize) {
            let white = Float.random(in: -0.15...0.15)

            // Bubbling
            bubbleTimer += 1.0 / Float(sampleRate)
            if bubbleTimer >= nextBubble {
                bubbleDecay = Float.random(in: 0.3...0.6)
                bubbleTimer = 0
                nextBubble = Float.random(in: 0.008...0.04)
            }
            bubbleDecay *= 0.9995

            let trickle = Float.random(in: -0.08...0.08) * (0.3 + bubbleDecay)
            data[i] = (white * 0.5 + trickle) * 0.55
        }
    }

    // MARK: - Fire (crackling pops with warm base)
    private func generateFire(_ data: UnsafeMutablePointer<Float>) {
        var last: Float = 0
        var crackleTimer: Float = 0
        var nextCrackle: Float = Float.random(in: 0.02...0.08)
        var crackleDecay: Float = 0

        for i in 0..<Int(bufferSize) {
            // Warm base (brown-ish)
            let white = Float.random(in: -1...1)
            last = (last + (0.01 * white))
            last = max(-1, min(1, last))

            // Crackles
            crackleTimer += 1.0 / Float(sampleRate)
            if crackleTimer >= nextCrackle {
                crackleDecay = Float.random(in: 0.4...0.9)
                crackleTimer = 0
                nextCrackle = Float.random(in: 0.015...0.1)
            }
            crackleDecay *= 0.999

            let crackle = Float.random(in: -0.3...0.3) * crackleDecay
            let pop = crackleDecay > 0.3 ? Float.random(in: -0.1...0.1) : 0

            data[i] = (last * 0.4 + crackle * 0.3 + pop * 0.2) * 0.6
        }
    }

    // MARK: - Forest (layered: wind + birds chirps + rustling)
    private func generateForest(_ data: UnsafeMutablePointer<Float>) {
        var windLast: Float = 0
        var gustPhase: Float = 0
        let gustFreq: Float = 0.06
        var birdTimer: Float = 0
        var nextBird: Float = Float.random(in: 0.3...1.5)
        var birdChirp: Float = 0
        var chirpPhase: Float = 0

        for i in 0..<Int(bufferSize) {
            // Wind layer
            let white = Float.random(in: -0.15...0.15)
            windLast = 0.985 * windLast + white * 0.015
            let gust = 0.6 + 0.4 * sin(gustPhase)
            gustPhase += (2 * .pi * gustFreq) / Float(sampleRate)
            if gustPhase > 2 * .pi { gustPhase -= 2 * .pi }
            let wind = windLast * gust

            // Rustling leaves
            let rustle = Float.random(in: -0.06...0.06) * gust

            // Bird chirps
            birdTimer += 1.0 / Float(sampleRate)
            if birdTimer >= nextBird {
                birdChirp = 1.0
                chirpPhase = 0
                birdTimer = 0
                nextBird = Float.random(in: 0.5...2.0)
            }
            var bird: Float = 0
            if birdChirp > 0.01 {
                let chirpFreq: Float = 2500 + 1500 * sin(chirpPhase * 0.3)
                bird = sin(chirpPhase) * birdChirp * 0.08
                chirpPhase += (2 * .pi * chirpFreq) / Float(sampleRate)
                birdChirp *= 0.9997
            }

            data[i] = (wind * 0.5 + rustle + bird) * 0.6
        }
    }
}
