//
//  Constraints.swift
//  ForceScroll
//
//  Created by Andrej Rylov on 27/11/16.
//  Copyright © 2016 Nosorog Studio. All rights reserved.
//

import UIKit

class Constraints {
    typealias AllSides = (leading: NSLayoutConstraint, top: NSLayoutConstraint, trailing: NSLayoutConstraint, bottom: NSLayoutConstraint)
    
    @discardableResult
    class func matchSuperview(_ view: UIView) -> AllSides {
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let leading = alignSuperviewLeading(view)
        let top = alignSuperviewTop(view)
        let trailing = alignSuperviewTrailing(view)
        let bottom = alignSuperviewBottom(view)
        
        return (leading, top, trailing, bottom)
    }
    
    @discardableResult
    class func alignSuperviewLeading(_ view: UIView) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let superview = view.superview!
        let leading = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: superview, attribute: .leading, multiplier: 1, constant: 0)
        superview.addConstraint(leading)
        return leading
    }
    
    @discardableResult
    class func alignSuperviewTop(_ view: UIView) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let superview = view.superview!
        let top = NSLayoutConstraint(item: view, attribute: .top, relatedBy: .equal, toItem: superview, attribute: .top, multiplier: 1, constant: 0)
        superview.addConstraint(top)
        return top
    }
    
    @discardableResult
    class func alignSuperviewTrailing(_ view: UIView) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let superview = view.superview!
        let trailing = NSLayoutConstraint(item: superview, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        superview.addConstraint(trailing)
        return trailing
    }
    
    @discardableResult
    class func alignSuperviewBottom(_ view: UIView) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let superview = view.superview!
        let bottom = NSLayoutConstraint(item: superview, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        superview.addConstraint(bottom)
        return bottom
    }
    
    @discardableResult
    class func alignSuperviewCenterY(_ view: UIView) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let superview = view.superview!
        let center = NSLayoutConstraint(item: superview, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
        superview.addConstraint(center)
        return center
    }
    
    @discardableResult
    class func height(_ view: UIView, height: CGFloat) -> NSLayoutConstraint {
        view.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: view, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: height)
        view.addConstraint(height)
        return height
    }
}
