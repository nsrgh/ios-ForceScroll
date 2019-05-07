//
//  ForceScrollMenuViewController.swift
//  ForceScroll
//
//  Created by Andrej Rylov on 27/11/16.
//  Copyright © 2016 Nosorog Studio. All rights reserved.
//

import UIKit

fileprivate enum Cell<DataType> {
    case space
    case item(data: DataType)
}

public typealias ForceScrollMenuItemFormatter<ItemType> = ((ItemType) -> String)

fileprivate func defaultItemFormatter<ItemType>() -> ForceScrollMenuItemFormatter<ItemType> {
    return { item in
        if let s = item as? CustomStringConvertible {
            return s.description
        }
        return ""
    }
}

public class ForceScrollMenuViewController<ItemType: AnyObject> : UIViewController, UITableViewDataSource, UITableViewDelegate, ForceScrollMenuViewControllerType {
    
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.tableView)
        Constraints.matchSuperview(self.tableView)
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.registerCells()
        
        let topFader = FaderView()
        self.view.addSubview(topFader)
        Constraints.alignSuperviewLeading(topFader)
        Constraints.alignSuperviewTop(topFader)
        Constraints.alignSuperviewTrailing(topFader)
        Constraints.height(topFader, height: 80)
        
        let bottomFader = FaderView()
        bottomFader.topDirection = false
        self.view.addSubview(bottomFader)
        Constraints.alignSuperviewLeading(bottomFader)
        Constraints.alignSuperviewTrailing(bottomFader)
        Constraints.alignSuperviewBottom(bottomFader)
        Constraints.height(bottomFader, height: 80)
    }
    
    private func registerCells() {
        tableView.register(SpaceCell.self, forCellReuseIdentifier: "space")
        registerItemCell(forId: "item", inTableView: self.tableView)
    }
    
    open func registerItemCell(forId id: String, inTableView tableView: UITableView) {
        tableView.register(ForceScrollMenuTextCell<ItemType>.self, forCellReuseIdentifier: id)
    }
    
    public var itemFormatter: ForceScrollMenuItemFormatter<ItemType> = defaultItemFormatter() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    private let tableView = UITableView()
    
    private var items: [ItemType] = []
    private var cells: [Cell<ItemType>] = []
    
    public func update(data: [ItemType]) {
        self.items = data
        var newCells: [Cell<ItemType>] = []
        
        newCells.append(.space)
        newCells.append(contentsOf: data.map { .item(data: $0) })
        newCells.append(.space)
        
        self.cells = newCells
        self.tableView.reloadData()
    }
    
    public func change(selectedData newData: ItemType?, animated: Bool) {
        if self.selectedData === newData {
            return
        }
        
        self.selectedData = newData
        self.updateSelection(animated: animated)
    }
    
    private(set) public var selectedData: ItemType? = nil
    private var prevSelectedData: ItemType? = nil
    private var nextSelectedData: ItemType? = nil
    
    fileprivate(set) public var forceScrolling: Bool = false
    
    public func beginForceScroll() {
        if forceScrolling {
            return
        }
        forceScrolling = true
        
        self.nextSelectedData = self.selectedData
        self.prevSelectedData = self.selectedData
        self.updateSelection(animated: false)
    }
    
    public func endForceScroll(canceled: Bool) {
        if !forceScrolling {
            return
        }
        forceScrolling = false
        
        if !canceled {
            self.selectedData = self.nextSelectedData
        }
        self.nextSelectedData = nil
        self.prevSelectedData = nil
        self.scrollY = 0
        updateSelection(animated: true)
    }
    
    public func didForceScrollSelect() {
        self.selectedData = self.nextSelectedData
    }
    
    public func didForceScroll(toY y: CGFloat) {
        self.scrollY = y
    }
    
    private func updateSelection(animated: Bool) {
        self.selectedIndex = nil
        
        if let item = self.prevSelectedData ?? self.selectedData {
            var row: Int? = nil
            for (index, cell) in self.cells.enumerated() {
                if case let .item(data) = cell {
                    if data === item {
                        row = index
                        break
                    }
                }
            }
            if row != nil {
                self.tableView.selectRow(at: IndexPath(row: row!, section: 0), animated: false, scrollPosition: .none)
                self.selectedIndex = row! - 1
            }
        } else {
            self.tableView.selectRow(at: nil, animated: false, scrollPosition: .none)
        }
        
        if let item = self.nextSelectedData {
            var row: Int? = nil
            for (index, cell) in self.cells.enumerated() {
                if case let .item(data) = cell {
                    if data === item {
                        row = index
                        break
                    }
                }
            }
            if row != nil {
                self.tableView.selectRow(at: IndexPath(row: row!, section: 0), animated: false, scrollPosition: .none)
            }
        }
        
        _ = self.updateContentOffset(animated: animated)
    }
    
    private var selectedIndex: Int? = nil
    
    fileprivate func updateContentOffset(animated: Bool) -> Int? {
        if let index = self.selectedIndex {
            var y = CGFloat(index) * itemHeight() * 0.666 - self.scrollY * 1.5
            let minY = CGFloat(0)
            let maxY = CGFloat(self.items.count - 1) * itemHeight() * 0.666
            var yFactor: CGFloat = 0
            if maxY > minY {
                yFactor = (y - minY) / (maxY - minY)
                if yFactor > 1 {
                    yFactor = pow(yFactor, 0.33)
                }
                if yFactor < 0 {
                    yFactor = -(pow(1.0 + abs(yFactor), 0.33) - 1.0)
                }
                y = minY + maxY * yFactor
            }
            
            var contentOffset = self.tableView.contentOffset
            contentOffset.y = y
            self.tableView.setContentOffset(contentOffset, animated: animated)
            
            if yFactor < 0 {
                yFactor = 0
            }
            if yFactor > 0.99 {
                yFactor = 0.99
            }
            let nextIndex = Int(CGFloat(items.count) * yFactor)
            return nextIndex
        } else {
            return nil
        }
    }
    
    private var scrollY: CGFloat = 0 {
        didSet {
            let newNextIndex = self.updateContentOffset(animated: false)
            if let index = newNextIndex {
                let newNextData = items[index]
                if self.nextSelectedData !== newNextData {
                    self.nextSelectedData = newNextData
                    updateSelection(animated: false)
                }
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let index = indexPath.row
        let cell = cells[index]
        switch cell {
        case .space:
            return tableView.dequeueReusableCell(withIdentifier: "space")!
        case let .item(data):
            let view = tableView.dequeueReusableCell(withIdentifier: "item")!
            update(itemView: view, forItem: data, atIndex: index)
            return view
        }
    }
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let index = indexPath.row
        let cell = cells[index]
        switch cell {
        case .space:
            if index == 0 {
                return 76
            } else {
                return tableView.frame.size.height - 76 - itemHeight()
            }
        case .item(_):
            return itemHeight()
        }
    }
    
    open func update(itemView view: UITableViewCell, forItem item: ItemType, atIndex index: Int) {
        if let menuCell = view as? ForceScrollMenuCell<ItemType> {
            let formatted = self.itemFormatter(item)
            menuCell.update(
                item: item,
                formattedItem: formatted,
                index: index,
                isLast: index == cells.count - 1
            )
        }
    }
    
    open func itemHeight() -> CGFloat {
        return 47
    }
}

fileprivate class SpaceCell : UITableViewCell {
}

open class ForceScrollMenuCell<ItemType> : UITableViewCell {
    
    func update(item: ItemType, formattedItem: String, index: Int, isLast: Bool) {
    }
    
}

open class ForceScrollMenuTextCell<ItemType> : ForceScrollMenuCell<ItemType> {
    private let colorBackgroundNormal = UIColor.white
    private let colorBackgroundSelected = UIColor(rgba: "#e0e0e0")
    private let colorTextNormal = UIColor(rgba: "#7c7c7c")
    private let colorTextSelected = UIColor(rgba: "#1D1D1D")
    
    private let container = UIView()
    private let label = UILabel()
    private let delimiter = UIView()
    
    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    open func initialize() {
        self.contentView.addSubview(container)
        Constraints.matchSuperview(container)
        
        self.container.addSubview(label)
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.medium)
        Constraints.alignSuperviewLeading(label).constant = 14
        Constraints.alignSuperviewTrailing(label).constant = 14
        Constraints.alignSuperviewCenterY(label)
        
        self.container.addSubview(delimiter)
        delimiter.backgroundColor = UIColor(rgba: "#9E9E9E")
        Constraints.alignSuperviewLeading(delimiter)
        Constraints.alignSuperviewTrailing(delimiter)
        Constraints.alignSuperviewBottom(delimiter)
        Constraints.height(delimiter, height: 1.0 / UIScreen.main.scale)
        
        self.setSelected(false, animated: false)
    }

    override open func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        container.backgroundColor = selected ? self.colorBackgroundSelected : self.colorBackgroundNormal
        label.textColor = selected ? colorTextSelected : colorTextNormal
    }
    
    override func update(item: ItemType, formattedItem: String, index: Int, isLast: Bool) {
        self.label.text = formattedItem
        self.delimiter.isHidden = isLast
    }
}

fileprivate class FaderView: UIView {
    override class var layerClass : AnyClass {
        return CAGradientLayer.self
    }
    
    init() {
        super.init(frame: CGRect.zero)
        self.initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    fileprivate func initialize() {
        updateGradient()
    }
    
    var topDirection: Bool = true {
        didSet {
            updateGradient()
        }
    }
    
    fileprivate func updateGradient() {
        let gradientLayer = self.layer as! CAGradientLayer
        gradientLayer.colors = [
            UIColor.white.withAlphaComponent(1.0).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]
        gradientLayer.isOpaque = false
        if topDirection {
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.333)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        } else {
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.333)
        }
    }
}

