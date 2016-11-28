//
//  Feedback.swift
//  ForceScroll
//
//  Created by Andrej Rylov on 28/11/16.
//  Copyright © 2016 Nosorog Studio. All rights reserved.
//

import Foundation
import AudioToolbox

class Feedback {
    static func vibrate() {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    static func peek() {
        AudioServicesPlaySystemSound(1519)
    }
    
    static func pop() {
        AudioServicesPlaySystemSound(1520)
    }
    
    static func nope() {
        AudioServicesPlaySystemSound(1521)
    }
}
