//
//  ForceScrollController.swift
//  ForceScroll
//
//  Created by Andrej Rylov on 27/11/16.
//  Copyright © 2016 Nosorog Studio. All rights reserved.
//

import UIKit

public protocol ForceScrollViewControllerDelegate : class {
    func forceScrollViewController(_ viewController: ForceScrollViewController, didChangeState: ForceScrollRecognizerState)
}

public protocol ForceScrollMainViewControllerType : class {
    func forceScroll(didChangeState newState: ForceScrollRecognizerState)
}

public protocol ForceScrollMenuViewControllerType : class {
    func beginForceScroll()
    func didForceScroll(toY y: CGFloat)
    func didForceScrollSelect()
    func endForceScroll(canceled: Bool)
}

public struct ForceScrollConfig {
    public var menuScale: CGFloat = 0.90
    public var useLongTapIfNoForceTouch: Bool = true
    
    public init() {
    }
}

public class ForceScrollViewController : UIViewController {
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    public let recognizer = ForceScrollRecognizer()
    private let menuContainer = UIView()
    private var menuConstraints: Constraints.AllSides? = nil
    
    public weak var delegate: ForceScrollViewControllerDelegate? = nil
    
    public var isRecognizerEnabled: Bool {
        get {
            return recognizer.isEnabled
        }
        set {
            recognizer.isEnabled = newValue
        }
    }
    
    public var mainViewController: UIViewController? = nil {
        didSet {
            if let oldValue = oldValue {
                self.removeChildControllerAndView(oldValue)
                oldValue.view.removeGestureRecognizer(self.recognizer)
            }
            if let mainViewController = mainViewController {
                self.addChildControllerAndView(mainViewController)
                mainViewController.view.addGestureRecognizer(self.recognizer)
            }
            self.setup()
        }
    }
    
    public var menuViewController: UIViewController? = nil {
        didSet {
            if let oldValue = oldValue {
                self.removeChildControllerAndView(oldValue)
            }
            if let menuViewController = menuViewController {
                self.addChildControllerAndView(menuViewController, toView: self.menuContainer)
            }
            self.setup()
        }
    }
    
    public var config: ForceScrollConfig = ForceScrollConfig()
    
    private func setup() {
        guard let _ = mainViewController,
              let _ = menuViewController else {
            return
        }
        
        self.recognizer.useLongTapIfNoForceTouch = config.useLongTapIfNoForceTouch
        
        self.view.bringSubview(toFront: menuContainer)
        menuContainer.isHidden = true
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.black
        self.recognizer.addTarget(self, action: #selector(handleForceScroll))
        
        self.view.addSubview(self.menuContainer)
        self.menuConstraints = Constraints.matchSuperview(self.menuContainer)
        self.menuContainer.layer.cornerRadius = 2
        self.menuContainer.clipsToBounds = true
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let selfSize = self.view.bounds.size
        let horizontalPadding = selfSize.width * (1.0 - config.menuScale) * 0.5
        let verticalPadding = selfSize.height * (1.0 - config.menuScale) * 0.5
        
        menuConstraints?.leading.constant = horizontalPadding
        menuConstraints?.top.constant = verticalPadding
        menuConstraints?.trailing.constant = horizontalPadding
        menuConstraints?.bottom.constant = verticalPadding
    }
    
    @objc func handleForceScroll(_ sender: ForceScrollRecognizer) {
        guard let main = mainViewController,
              let menu = menuViewController else {
            return
        }
        
        let mainProtocol = main as? ForceScrollMainViewControllerType
        let menuProtocol = menu as? ForceScrollMenuViewControllerType
        
        let factor = sender.enterFactor
        let scale = config.menuScale + (1.0 - config.menuScale) * (1.0 - factor)
        main.view.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        let maxFastScale: CGFloat = 1.0 / config.menuScale
        let fastScale = maxFastScale + factor * (1.0 - maxFastScale)
        menuContainer.transform = CGAffineTransform(scaleX: fastScale, y: fastScale)
        
        if factor > 0.33 {
            menuContainer.isHidden = false
            menuContainer.alpha = (factor - 0.33) / 0.67
        } else {
            menuContainer.isHidden = true
        }
        
        if sender.state == .began {
            menuProtocol?.beginForceScroll()
        }
        
        menuProtocol?.didForceScroll(toY: sender.translation.height)
        
        if sender.state == .ended {
            menuProtocol?.endForceScroll(canceled: false)
        }
        
        if sender.state == .failed {
            menuProtocol?.endForceScroll(canceled: true)
        }
        
        if sender.state != .failed && sender.scrollState == .exit {
            menuProtocol?.didForceScrollSelect()
        }
        
        mainProtocol?.forceScroll(didChangeState: sender.scrollState)
        self.delegate?.forceScrollViewController(self, didChangeState: sender.scrollState)
    }
}
