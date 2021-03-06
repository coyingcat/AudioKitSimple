// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/
// This file was auto-autogenerated by scripts and templates at http://github.com/AudioKit/AudioKitDevTools/

import AVFoundation


/// Casio-style phase distortion with "pivot point" on the X axis
/// This module is designed to emulate the classic phase distortion synthesis technique.
/// From the mid 90's. The technique reads the first and second halves of the ftbl
/// at different rates in order to warp the waveform. For example, pdhalf can
/// smoothly transition a sinewave into something approximating a sawtooth wave.
/// 
public class PhaseDistortionOscillator: Node, AudioUnitContainer, Tappable, Toggleable {

    /// Unique four-letter identifier "pdho"
    public static let ComponentDescription = AudioComponentDescription(generator: "pdho")

    /// Internal type of audio unit for this node
    public typealias AudioUnitType = InternalAU

    /// Internal audio unit 
    public private(set) var internalAU: AudioUnitType?

    // MARK: - Parameters

    fileprivate var waveform: Table?

    /// Specification details for frequency
    public static let frequencyDef = NodeParameterDef(
        identifier: "frequency",
        name: "Frequency (Hz)",
        address: akGetParameterAddress("PhaseDistortionOscillatorParameterFrequency"),
        range: 0 ... 20_000,
        unit: .hertz,
        flags: .default)

    /// Frequency in cycles per second
    @Parameter public var frequency: AUValue

    /// Specification details for amplitude
    public static let amplitudeDef = NodeParameterDef(
        identifier: "amplitude",
        name: "Amplitude",
        address: akGetParameterAddress("PhaseDistortionOscillatorParameterAmplitude"),
        range: 0 ... 10,
        unit: .generic,
        flags: .default)

    /// Output Amplitude.
    @Parameter public var amplitude: AUValue

    /// Specification details for phaseDistortion
    public static let phaseDistortionDef = NodeParameterDef(
        identifier: "phaseDistortion",
        name: "Amount of distortion, within the range [-1, 1]. 0 is no distortion.",
        address: akGetParameterAddress("PhaseDistortionOscillatorParameterPhaseDistortion"),
        range: -1 ... 1,
        unit: .generic,
        flags: .default)

    /// Amount of distortion, within the range [-1, 1]. 0 is no distortion.
    @Parameter public var phaseDistortion: AUValue

    /// Specification details for detuningOffset
    public static let detuningOffsetDef = NodeParameterDef(
        identifier: "detuningOffset",
        name: "Frequency offset (Hz)",
        address: akGetParameterAddress("PhaseDistortionOscillatorParameterDetuningOffset"),
        range: -1_000 ... 1_000,
        unit: .hertz,
        flags: .default)

    /// Frequency offset in Hz.
    @Parameter public var detuningOffset: AUValue

    /// Specification details for detuningMultiplier
    public static let detuningMultiplierDef = NodeParameterDef(
        identifier: "detuningMultiplier",
        name: "Frequency detuning multiplier",
        address: akGetParameterAddress("PhaseDistortionOscillatorParameterDetuningMultiplier"),
        range: 0.9 ... 1.11,
        unit: .generic,
        flags: .default)

    /// Frequency detuning multiplier
    @Parameter public var detuningMultiplier: AUValue

    // MARK: - Audio Unit

    /// Internal Audio Unit for PhaseDistortionOscillator
    public class InternalAU: AudioUnitBase {
        /// Get an array of the parameter definitions
        /// - Returns: Array of parameter definitions
        public override func getParameterDefs() -> [NodeParameterDef] {
            [PhaseDistortionOscillator.frequencyDef,
             PhaseDistortionOscillator.amplitudeDef,
             PhaseDistortionOscillator.phaseDistortionDef,
             PhaseDistortionOscillator.detuningOffsetDef,
             PhaseDistortionOscillator.detuningMultiplierDef]
        }

        /// Create the DSP Refence for this node
        /// - Returns: DSP Reference
        public override func createDSP() -> DSPRef {
            akCreateDSP("PhaseDistortionOscillatorDSP")
        }
    }

    // MARK: - Initialization

    /// Initialize this oscillator node
    ///
    /// - Parameters:
    ///   - waveform: The waveform of oscillation
    ///   - frequency: Frequency in cycles per second
    ///   - amplitude: Output Amplitude.
    ///   - phaseDistortion: Amount of distortion, within the range [-1, 1]. 0 is no distortion.
    ///   - detuningOffset: Frequency offset in Hz.
    ///   - detuningMultiplier: Frequency detuning multiplier
    ///
    public init(
        waveform: Table = Table(.sine),
        frequency: AUValue = 440,
        amplitude: AUValue = 1,
        phaseDistortion: AUValue = 0,
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

            audioUnit.setWavetable(waveform.content)

            self.waveform = waveform
            self.frequency = frequency
            self.amplitude = amplitude
            self.phaseDistortion = phaseDistortion
            self.detuningOffset = detuningOffset
            self.detuningMultiplier = detuningMultiplier
        }
    }
}
