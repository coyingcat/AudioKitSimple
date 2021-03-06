//
//  Sequencer.swift
//  Swift2AVFoundFrobs
//
//  Created by Gene De Lisa on 6/10/15.
//  Copyright © 2015 Gene De Lisa. All rights reserved.
//

import Foundation
import AVFoundation

class Sequencer{
    // This is the MuseCore soundfont. Change it to the one you have.
    let soundFontMuseCoreName = "GeneralUser GS MuseScore v1.442"
    
    var engine = AVAudioEngine()
    var sampler = AVAudioUnitSampler()
    lazy var sequencer = AVAudioSequencer(audioEngine: engine)
    
    init(){
        setSessionPlayback()
        
        // set up the engine
        engine.attach(sampler)
        
        let outputHWFormat = engine.outputNode.outputFormat(forBus: 0)
        engine.connect(sampler, to: engine.mainMixerNode, format: outputHWFormat)

        loadSF2PresetIntoSampler(preset: 0)
        
        addObservers()
        
        engineStart()
        
        // finished setting up engine
        
        guard let fileURL = Bundle.main.url(forResource: "sibeliusGMajor", withExtension: "mid") else {
            fatalError("\"sibeliusGMajor.mid\" file not found.")
        }
        
        do {
            try sequencer.load(from: fileURL, options: .smfChannelsToTracks)
            print("loaded \(fileURL)")
        } catch {
            fatalError("something screwed up while loading midi file \n \(error)")
        }

        for track in sequencer.tracks {
            // the tempo track is not included in sequencer.tracks
            if track == sequencer.tempoTrack {
                print("tempo track")
            }
            
            // setting the destinations crashes if the sequence has already been started
            track.destinationAudioUnit = self.sampler

        }
        
        sequencer.prepareToPlay()
       
    }
    
    func play() {
        if sequencer.isPlaying {
            sequencer.stop()
        }
        
        sequencer.currentPositionInBeats = 0
        sequencer.prepareToPlay()

        do {
            try sequencer.start()
        } catch {
            print("cannot start sequencer")
            print("\(error)")
        }

    }
    
    
    func engineStart() {
        do {
            try engine.start()
        } catch {
            print("error couldn't start engine")
            print("\(error)")
        }
    }
    
    //MARK: - Notifications
    
    func addObservers() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(engineConfigurationChange),
            name:NSNotification.Name.AVAudioEngineConfigurationChange,
            object:engine)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(sessionInterrupted),
            name:AVAudioSession.interruptionNotification,
            object:engine)
        
        NotificationCenter.default.addObserver(self,
            selector: #selector(sessionRouteChange),
            name:AVAudioSession.routeChangeNotification,
            object:engine)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name.AVAudioEngineConfigurationChange,
            object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.interruptionNotification,
            object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    
    
    func playNoteOn(channel:UInt8, noteNum:UInt8, velocity:UInt8)    {
        let noteCommand = UInt8(0x90 | channel)
        self.sampler.sendMIDIEvent(noteCommand, data1: noteNum, data2: velocity)
    }
    
    func playNoteOff(channel:UInt8, noteNum:UInt8)    {
        let noteCommand = UInt8(0x80 | channel)
        self.sampler.sendMIDIEvent(noteCommand, data1: noteNum, data2: 0)
    }
   

    func loadSF2PresetIntoSampler(preset: UInt8){
        
        guard let bankURL = Bundle.main.url(forResource: soundFontMuseCoreName, withExtension: "sf2") else {
            fatalError("\(self.soundFontMuseCoreName).sf2 file not found.")
        }
        
        do {
            try
                self.sampler.loadSoundBankInstrument(at: bankURL,
                    program: preset,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: UInt8(kAUSampler_DefaultBankLSB))
            
            print("loaded soundfont \(bankURL)")

            // this uses an aupreset file. sampler.loadInstrumentAtURL()
            
        } catch {
            print("error loading sound bank instrument")
            print(error)
        }
    }
    
    
    
    //MARK: - Audio Session
    
    func setSessionPlayback() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(AVAudioSession.Category.playback)
        } catch {
            print("could not set session category")
            print(error)
        }
        do {
            try session.setActive(true)
        } catch {
            print("could not make session active")
            print(error)
        }
    }
    
    // MARK: - notification callbacks
    
    @objc func engineConfigurationChange(notification:NSNotification) {
        print("engine config change")
        engineStart()
        
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject?> {
            print("userInfo")
            print(userInfo)
        }
    }
    
    
    @objc
    func sessionInterrupted(notification:NSNotification) {
        print("audio session interrupted")
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
        
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject?> {
            let reason = userInfo[AVAudioSessionInterruptionTypeKey] as! AVAudioSession.InterruptionType
            switch reason {
            case .began:
                print("began")
            case .ended:
                print("ended")
            @unknown default:
                ()
            }
        }
        
    }
    
    
    @objc
    func sessionRouteChange(notification:NSNotification) {
        print("audio session route change \(notification)")
        
        if let userInfo = notification.userInfo as? Dictionary<String, AnyObject?> {
            
            if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSession.RouteChangeReason {
                
                print("audio session route change reason \(reason)")
                
                switch reason {
                case .unknown:
                    print("Unknown")
                case .newDeviceAvailable:
                    print("NewDeviceAvailable")
                case .oldDeviceUnavailable:
                    print("OldDeviceUnavailable")
                case .categoryChange:
                    print("CategoryChange")
                case .override:
                    print("Override")
                case .wakeFromSleep:
                    print("WakeFromSleep")
                case .noSuitableRouteForCategory:
                    print("NoSuitableRouteForCategory")
                case .routeConfigurationChange:
                    print("RouteConfigurationChange")
                @unknown default:
                    ()
                }
            }
            
            let previous = userInfo[AVAudioSessionRouteChangePreviousRouteKey]
            print("audio session route change previous \(String(describing: previous))")
        }
        
        
        if let engine = notification.object as? AVAudioEngine {
            engine.stop()
        }
    }
    
}
