/*

Copyright (c) 2016, Storehouse Media Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

import Foundation

import QuartzCore

extension DisplayLink {
    /// Info about a particular frame.
    struct Frame : Equatable {
        /// The timestamp that the frame.
        var timestamp: Double
        
        /// The current duration between frames.
        var duration: Double
    }
}

func ==(lhs: DisplayLink.Frame, rhs: DisplayLink.Frame) -> Bool {
    return lhs.timestamp == rhs.timestamp && lhs.duration == rhs.duration
}


/// DisplayLink is used to hook into screen refreshes.
internal final class DisplayLink {
    
    /// The callback to call for each frame.
    var callback: ((_ frame: Frame) -> Void)? = nil
    
    /// If the display link is paused or not.
    var paused: Bool {
        get {
            return displayLink.isPaused
        }
        set {
            displayLink.isPaused = newValue
        }
    }
    
    /// The CADisplayLink that powers this DisplayLink instance.
    let displayLink: CADisplayLink
    
    /// The target for the CADisplayLink (because CADisplayLink retains its target).
    let target = DisplayLinkTarget()
    
    /// Creates a new paused DisplayLink instance.
    init() {
        displayLink = CADisplayLink(target: target, selector: #selector(DisplayLinkTarget.frame(displayLink:)))
        displayLink.isPaused = true
        displayLink.add(to: RunLoop.main, forMode: .common)
        
        target.callback = { [unowned self] (frame) in
            self.callback?(frame)
        }
    }
    
    deinit {
        displayLink.invalidate()
    }
    
    /// The target for the CADisplayLink (because CADisplayLink retains its target).
    internal final class DisplayLinkTarget {
        
        /// The callback to call for each frame.
        var callback: ((_ frame: DisplayLink.Frame) -> Void)? = nil
        
        /// Called for each frame from the CADisplayLink.
        @objc dynamic func frame(displayLink: CADisplayLink) {
            callback?(Frame(timestamp: displayLink.timestamp, duration: displayLink.duration))
        }
    }
}
