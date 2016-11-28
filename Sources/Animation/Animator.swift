//
//  Animator.swift
//  ForceScroll
//
//  Created by Andrej Rylov on 17/11/16.
//  Copyright © 2016 Nosorog Studio. All rights reserved.
//

import Foundation
import QuartzCore

class Animator {
    private let source: CGFloat
    private let target: CGFloat
    private let duration: Double
    private let easing: EasingFunction
    private let tickCallback: (CGFloat)->Void
    private let completedCallback: ((Bool)->Void)?
    
    init(
        from source: CGFloat = 0,
        to target: CGFloat = 1,
        duration: Double = 0.3,
        easing: @escaping EasingFunction = CubicEaseInOut,
        onTick tickCallback: @escaping (CGFloat)->Void,
        onCompleted completedCallback: ((Bool)->Void)? = nil) {
        
        self.source = source
        self.target = target
        self.duration = duration
        self.easing = easing
        self.tickCallback = tickCallback
        self.completedCallback = completedCallback
    }
    
    private (set) var started: Bool = false
    private var elapsed: Double = 0.0
    private var completed: Bool = false
    
    func start() {
        if started {
            return
        }
        started = true
        
        self.displayLink.paused = false
    }
    
    func cancel() {
        self.displayLink.paused = true
        completedCallback?(false)
    }
    
    private lazy var displayLink: DisplayLink = {
        let link = DisplayLink()
        link.callback = { [unowned self] (frame) in
            self.tick(frame: frame)
        }
        return link
    }()
    
    private func tick(frame: DisplayLink.Frame) {
        if (completed) {
            return
        }
        
        elapsed += frame.duration
        var factor = Float(elapsed / duration)
        if factor >= 1.0 {
            completed = true
            factor = 1.0
        }
        factor = easing(factor)
        let current = source + (target - source) * CGFloat(factor)
        tickCallback(current)
        
        if completed {
            self.displayLink.paused = true
            completedCallback?(true)
        }
        
    }
}
