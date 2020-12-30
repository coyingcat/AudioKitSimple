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

    var sequencer:Sequencer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        sequencer = Sequencer()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    @IBAction func playIt(_ sender: Any) {
        
        if let s = sequencer {
            print("playing")
            s.play()
        }
        
    }
    
    
    
  
    @IBAction func noteOn__touchDown(_ sender: Any) {
        print(#function)
        sequencer?.playNoteOn(channel: 0, noteNum: 60, velocity: 100)
    }
    
    
    
    
    @IBAction func noteOff__touchUpInside(_ sender: Any) {
        print(#function)
        sequencer?.playNoteOff(channel: 0, noteNum: 60)
        
    }
    
    
    
 
    
    

    
    
    
}

