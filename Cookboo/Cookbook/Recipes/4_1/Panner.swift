import AudioKit
import AVFoundation
import SwiftUI

struct PannerData {
    var pan: AUValue = 0
    var rampDuration: AUValue = 0.02
    var balance: AUValue = 0.5
}

class PannerConductor: ObservableObject, ProcessesPlayerInput {

    let engine = AudioEngine()
    let player = AudioPlayer()
    let panner: Panner
    let dryWetMixer: DryWetMixer
    let playerPlot: NodeOutputPlot
    let pannerPlot: NodeOutputPlot
    let mixPlot: NodeOutputPlot
    let buffer: AVAudioPCMBuffer

    init() {
        buffer = Cookbook.sourceBuffer

        panner = Panner(player)
        dryWetMixer = DryWetMixer(player, panner)
        playerPlot = NodeOutputPlot(player)
        pannerPlot = NodeOutputPlot(panner)
        mixPlot = NodeOutputPlot(dryWetMixer)
        engine.output = dryWetMixer

        Cookbook.setupDryWetMixPlots(playerPlot, pannerPlot, mixPlot)
    }

    @Published var data = PannerData() {
        didSet {
            panner.$pan.ramp(to: data.pan, duration: data.rampDuration)
            dryWetMixer.balance = data.balance
        }
    }

    func start() {
        playerPlot.start()
        pannerPlot.start()
        mixPlot.start()

        do { try engine.start() } catch let err { Log(err) }
        player.scheduleBuffer(buffer, at: nil, options: .loops)
    }

    func stop() {
        engine.stop()
    }
}

struct PannerView: View {
    @ObservedObject var conductor = PannerConductor()

    var body: some View {
        ScrollView {
            PlayerControls(conductor: conductor)
            ParameterSlider(text: "Pan",
                            parameter: self.$conductor.data.pan,
                            range: -1...1,
                            units: "Generic")
            ParameterSlider(text: "Mix",
                            parameter: self.$conductor.data.balance,
                            range: 0...1,
                            units: "%")
            DryWetMixPlotsView(dry: conductor.playerPlot, wet: conductor.pannerPlot, mix: conductor.mixPlot)
        }
        .padding()
        .navigationBarTitle(Text("Panner"))
        .onAppear {
            self.conductor.start()
        }
        .onDisappear {
            self.conductor.stop()
        }
    }
}

struct Panner_Previews: PreviewProvider {
    static var previews: some View {
        PannerView()
    }
}
