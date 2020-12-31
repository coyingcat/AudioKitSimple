//
//  ViewController.swift
//  Swift2AVFoundFrobs
//
//  Created by Gene De Lisa on 6/9/15.
//  Copyright © 2015 Gene De Lisa. All rights reserved.
//

import UIKit
import AVFoundation


class ViewController: UIViewController {

    lazy var sequencer = Sequencer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    
    @IBAction func playIt(_ sender: Any) {

        // print("playing")
        sequencer.play()
    }
    
    
    
  
    @IBAction func noteOn__touchDown(_ sender: Any) {
        // print(#function)
        sequencer.playNoteOn(channel: 0, noteNum: 60, velocity: 100)
    }
    
    
    
    
    @IBAction func noteOff__touchUpInside(_ sender: Any) {
        // print(#function)
        sequencer.playNoteOff(channel: 0, noteNum: 60)
        
    }
    
    
    
 
    
    

    
    
    
}

