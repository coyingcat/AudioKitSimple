// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation


/// Casio-style phase distortion with "pivot point" on the X axis This module is
/// designed to emulate the classic phase distortion synthesis technique. From
/// the mid 90's. The technique reads the first and second halves of the ftbl at
/// different rates in order to warp the waveform. For example, pdhalf can
/// smoothly transition a sinewave into something approximating a sawtooth wave.
/// 
public class PWMOscillator: Node, AudioUnitContainer, Tappable, Toggleable {

    /// Unique four-letter identifier "pwmo"
    public static let ComponentDescription = AudioComponentDescription(generator: "pwmo")

    /// Internal type of audio unit for this node
    public typealias AudioUnitType = InternalAU

    /// Internal audio unit 
    public private(set) var internalAU: AudioUnitType?

    // MARK: - Parameters

    /// Specification details for frequency
    public static let frequencyDef = NodeParameterDef(
        identifier: "frequency",
        name: "Frequency (Hz)",
        address: akGetParameterAddress("PWMOscillatorParameterFrequency"),
        range: 0.0 ... 20_000.0,
        unit: .hertz,
        flags: .default)

    /// In cycles per second, or Hz.
    @Parameter public var frequency: AUValue

    /// Specification details for amplitude
    public static let amplitudeDef = NodeParameterDef(
        identifier: "amplitude",
        name: "Amplitude",
        address: akGetParameterAddress("PWMOscillatorParameterAmplitude"),
        range: 0.0 ... 10.0,
        unit: .hertz,
        flags: .default)

    /// Output amplitude
    @Parameter public var amplitude: AUValue

    /// Specification details for pulseWidth
    public static let pulseWidthDef = NodeParameterDef(
        identifier: "pulseWidth",
        name: "Pulse Width",
        address: akGetParameterAddress("PWMOscillatorParameterPulseWidth"),
        range: 0.0 ... 1.0,
        unit: .generic,
        flags: .default)

    /// Duty cycle width (range 0-1).
    @Parameter public var pulseWidth: AUValue

    /// Specification details for detuningOffset
    public static let detuningOffsetDef = NodeParameterDef(
        identifier: "detuningOffset",
        name: "Frequency offset (Hz)",
        address: akGetParameterAddress("PWMOscillatorParameterDetuningOffset"),
        range: -1_000.0 ... 1_000.0,
        unit: .hertz,
        flags: .default)

    /// Frequency offset in Hz.
    @Parameter public var detuningOffset: AUValue

    /// Specification details for detuningMultiplier
    public static let detuningMultiplierDef = NodeParameterDef(
        identifier: "detuningMultiplier",
        name: "Frequency detuning multiplier",
        address: akGetParameterAddress("PWMOscillatorParameterDetuningMultiplier"),
        range: 0.9 ... 1.11,
        unit: .generic,
        flags: .default)

    /// Frequency detuning multiplier
    @Parameter public var detuningMultiplier: AUValue

    // MARK: - Audio Unit

    /// Internal Audio Unit for PWMOscillator
    public class InternalAU: AudioUnitBase {
        /// Get an array of the parameter definitions
        /// - Returns: Array of parameter definitions
        public override func getParameterDefs() -> [NodeParameterDef] {
            [PWMOscillator.frequencyDef,
             PWMOscillator.amplitudeDef,
             PWMOscillator.pulseWidthDef,
             PWMOscillator.detuningOffsetDef,
             PWMOscillator.detuningMultiplierDef]
        }

        /// Create the DSP Refence for this node
        /// - Returns: DSP Reference
        public override func createDSP() -> DSPRef {
            akCreateDSP("PWMOscillatorDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this oscillator node
    ///
    /// - Parameters:
    ///   - frequency: In cycles per second, or Hz.
    ///   - amplitude: Output amplitude
    ///   - pulseWidth: Duty cycle width (range 0-1).
    ///   - detuningOffset: Frequency offset in Hz.
    ///   - detuningMultiplier: Frequency detuning multiplier
    ///
    public init(
        frequency: AUValue = 440,
        amplitude: AUValue = 1.0,
        pulseWidth: AUValue = 0.5,
        detuningOffset: AUValue = 0,
        detuningMultiplier: AUValue = 1
    ) {
        super.init(avAudioNode: AVAudioNode())

        instantiateAudioUnit { avAudioUnit in
            self.avAudioUnit = avAudioUnit
            self.avAudioNode = avAudioUnit

            guard let audioUnit = avAudioUnit.auAudioUnit as? AudioUnitType else {
                fatalError("Couldn't create audio unit")
            }
            self.internalAU = audioUnit
            self.stop()

            self.frequency = frequency
            self.amplitude = amplitude
            self.pulseWidth = pulseWidth
            self.detuningOffset = detuningOffset
            self.detuningMultiplier = detuningMultiplier
        }
    }
}
