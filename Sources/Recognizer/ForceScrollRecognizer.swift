//
//  ForceScrollRecognizer.swift
//  fanlife
//
//  Created by Andrej Rylov on 23/05/16.
//  Copyright © 2016 nosorog. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

public enum ForceScrollRecognizerState {
    case none
    case enter
    case scroll
    case exit
}

public class ForceScrollRecognizer: UIGestureRecognizer {

    private(set) public var scrollState: ForceScrollRecognizerState = .none
    public var enterFactor: CGFloat {
        get {
            return enterFactorAnimatable.currentValue
        }
    }
    private let enterFactorAnimatable = AnimatableValue()
    private(set) public var translation: CGSize = CGSize.zero
    
    private var startLongTouchDelay: TimeInterval = 0.3
    private var enterLongTouchTime: TimeInterval = 0.4
    private var forceStepAnimationTime: TimeInterval = 0.05
    private var exitTime: TimeInterval = 0.2
    private var touchForceForStart: CGFloat = 1.0
    private var touchForceForEnter: CGFloat = 3.0
    private var forceTouchEnabled: Bool = false
    
    public var useLongTapIfNoForceTouch: Bool = true
    
    public override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        enterFactorAnimatable.currentValueChanged = {
            self.notifyChanged()
        }
        self.cancelsTouchesInView = true
        self.delaysTouchesBegan = false
        if #available(iOS 9.0, *) {
            forceTouchEnabled = UIApplication.shared.windows[0].traitCollection.forceTouchCapability == .available
        }
    }
    
    public override func reset() {
        super.reset()
        cancelLongTouch()
        enterFactorAnimatable.value = 0
    }
    
    private var activeTouchCount = 0
    
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        
        if scrollState != .none {
            self.activeTouchCount += 1
            return
        }
        
        if touches.count != 1 {
            state = .failed
            return
        }
        
        self.state = .possible
        if !forceTouchEnabled && useLongTapIfNoForceTouch {
            scheduleLongTouchStart()
        }
        
        self.activeTouchCount = 1
        self.translation = CGSize.zero
    }
    
    override open func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if scrollState == .scroll {
            let touch = touches.first!
            let location = touch.location(in: self.view)
            let prevLocation = touch.previousLocation(in: self.view)
            let addTranslation = CGSize(width: location.x - prevLocation.x, height: location.y - prevLocation.y)
            self.translation = CGSize(
                width: self.translation.width + addTranslation.width,
                height: self.translation.height + addTranslation.height
            )
            self.state = .changed
            return
        }
        
        if #available(iOS 9.0, *) {
            let touch = touches.first!
            let force = touch.force
            if forceTouchEnabled && force > touchForceForStart {
                if force < touchForceForEnter {
                    cancelLongTouch()
                    self.state = .began
                    let enterFactor = (force - touchForceForStart) / (touchForceForEnter - touchForceForStart)
                    enterFactorAnimatable.value = enterFactor
                } else {
                    if self.scrollState != .enter {
                        self.scrollState = .enter
                        Feedback.pop()
                        enterFactorAnimatable.animate(to: 1.0, duration: forceStepAnimationTime, easing: CubicEaseIn, completion: {
                            self.startForceScroll()
                        })
                    }
                }
            }
        }
    }
    
    override open func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        self.activeTouchCount -= 1
        
        if self.activeTouchCount <= 0 {
            self.activeTouchCount = 0
            cancelLongTouch()
            if scrollState != .none {
                scrollState = .exit
                
                enterFactorAnimatable.animate(to: 0.0, duration: exitTime, easing: CubicEaseOut, completion: {
                    self.state = .ended
                    self.scrollState = .none
                })
            } else {
                scrollState = .exit
                enterFactorAnimatable.value = 0
                scrollState = .none
                state = .failed
            }
        }
    }
    
    override open func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        
        cancelLongTouch()
        scrollState = .exit
        enterFactorAnimatable.value = 0
        scrollState = .none
        state = .failed
        self.activeTouchCount = 0
    }
    
    private func scheduleLongTouchStart() {
        self.perform(#selector(startLongTouchEnter), with: nil, afterDelay: self.startLongTouchDelay)
    }
    
    private func cancelLongTouch() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(startLongTouchEnter), object: nil)
    }
    
    @objc private func startLongTouchEnter() {
        self.scrollState = .enter
        self.state = .began
        
        enterFactorAnimatable.animate(to: 1.0, duration: enterLongTouchTime, easing: CubicEaseOut, completion: {
            self.startForceScroll()
        })
    }
    
    private func startForceScroll() {
        self.scrollState = .scroll
        notifyChanged()
    }
    
    private func notifyChanged() {
        if self.scrollState != .none {
            self.state = .changed
        }
    }
}
