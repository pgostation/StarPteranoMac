//
//  PgoTabView.swift
//  StarPteranoMac
//
//  Created by takayoshi on 2019/03/02.
//  Copyright © 2019 pgostation. All rights reserved.
//

// ドラック&ドロップに対応したタブビュー

import Cocoa

// タブバー全体の表示ビュー
final class PgoTabView: NSTabView {
    var items: [PgoTabItem] = [] // タブバーの持つアイテムのリスト
    fileprivate var itemViews: [PgoTabItemView] = [] // タブバーに表示するアイテムビューのリスト
    private var _showAddButton = true // 右端に「+」ボタンを表示するかどうか
    var showAddButton: Bool {
        get {
            return _showAddButton
        }
        set {
            _showAddButton = newValue
            
            // 画面にボタンを追加/削除
            if newValue && addButton.superview == nil {
                self.addSubview(addButton)
            } else {
                addButton.removeFromSuperview()
            }
            
            // ビューを更新
            refresh()
        }
    }
    private var addButton = NSButton() // 右端の「+」ボタン
    private var draggable = true // ドラッグ&ドロップでアイテムの順番入れ替え可能かどうか
    private var _bold = false // 選択中のタブの名前を太字で表示するかどうか
    var bold: Bool {
        get {
            return _bold
        }
        set {
            if _bold == newValue { return }
            
            _bold = newValue
            
            // ビューを更新
            refresh()
        }
    }
    private var selectedIndex = 0 // 選択中のタブアイテムのインデックス
    var addNewTabButtonAction: Selector? // 追加ボタンクリック時のSelector登録
    weak var addNewTabButtonTarget: AnyObject? // 追加ボタンクリック時のターゲット登録
    private let tabBar = NSView() // 本来のNSTabViewは隠すので、別のものを付ける
    
    override var tag: Int {
        return 5823
    }
    
    // 初期化
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        DispatchQueue.main.async {
            self.superview?.addSubview(self.tabBar)
        }
        
        tabBar.addSubview(addButton)
        addButton.target = self
        addButton.action = #selector(addAction)
        
        // プロパティ設定
        setProperties()
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // プロパティ設定
    private func setProperties() {
        // 本来のNSTabViewは隠す
        self.isHidden = true
        
        // タブバー全体の背景色
        if SettingsData.isTransparentWindow {
            tabBar.layer?.backgroundColor = NSColor.clear.cgColor
        } else {
            tabBar.wantsLayer = true
            tabBar.layer?.backgroundColor = ThemeColor.viewBgColor.cgColor
        }
        
        // 「+」ボタン
        let attributedTitle = NSMutableAttributedString(string: "+")
        attributedTitle.addAttributes( [NSAttributedString.Key.foregroundColor : ThemeColor.contrastColor],
                                       range: NSRange(location: 0, length: attributedTitle.length))
        addButton.attributedTitle = attributedTitle
        addButton.wantsLayer = true
        if SettingsData.isTransparentWindow {
            addButton.layer?.backgroundColor = ThemeColor.cellBgColor.withAlphaComponent(0.3).cgColor
        } else {
            addButton.layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
        }
        addButton.isBordered = false
    }
    
    // 「+」ボタンを押した時
    @objc func addAction() {
        _ = self.addNewTabButtonTarget?.perform(self.addNewTabButtonAction!)
    }
    
    // タブにアイテムを追加する
    override func addTabViewItem(_ tabViewItem: NSTabViewItem) {
        // 追加する
        items.append(tabViewItem as! PgoTabItem)
        
        // ビューを更新
        self.refresh()
        
        // デリゲートで変更通知
        delegate?.tabViewDidChangeNumberOfTabViewItems?(self)
        
        // 最初のアイテムは必ず選択
        if items.count == 1 {
            self.delegate?.tabView?(self, didSelect: items[0])
        }
    }
    
    // タブからアイテムを削除する
    func delete(item: PgoTabItem) {
        if let index = items.firstIndex(of: item) {
            // あれば削除する
            let item = items[index]
            item.willRemove()
            items.remove(at: index)
            
            // ビューを更新
            self.refresh()
            
            // 選択中だった場合、新しいものをdidSelect
            if index == selectedIndex {
                self.selectedIndex = min(items.count - 1, selectedIndex)
                DispatchQueue.main.async {
                    self.delegate?.tabView?(self, didSelect: self.items[self.selectedIndex])
                }
            }
        }
        
        // デリゲートで変更通知
        delegate?.tabViewDidChangeNumberOfTabViewItems?(self)
    }
    
    // ビューをクリックしたら選択する
    fileprivate func select(itemView: PgoTabItemView) {
        guard let index = itemViews.firstIndex(of: itemView) else { return }
        
        self.delegate?.tabView?(self, didSelect: items[index])
        
        self.selectedIndex = index
    }
    
    // ビューを更新する
    func refresh() {
        // アイテムのビューが少なければ作る
        if items.count > itemViews.count {
            let itemView = PgoTabItemView(tabView: self)
            tabBar.addSubview(itemView)
            itemViews.append(itemView)
        }
        // アイテムのビューが多ければ削る
        if items.count < itemViews.count {
            itemViews[0].removeFromSuperview()
            itemViews.remove(at: 0)
        }
        
        // アイテムのビューのプロパティ設定
        for (index, item) in items.enumerated() {
            let isSelected = (index == selectedIndex)
            
            itemViews[index].wantsLayer = true
            if SettingsData.isTransparentWindow {
                itemViews[index].layer?.backgroundColor = NSColor.clear.cgColor
            } else {
                itemViews[index].layer?.backgroundColor = ThemeColor.cellBgColor.cgColor
            }
            
            if isSelected {
                itemViews[index].layer?.borderWidth = 1
                if _bold {
                    itemViews[index].layer?.borderColor = ThemeColor.buttonBorderColor.cgColor
                } else {
                    itemViews[index].layer?.borderColor = ThemeColor.buttonBorderColor.withAlphaComponent(0.3).cgColor
                }
            } else {
                itemViews[index].layer?.borderWidth = 0
            }
                
            itemViews[index].nameLabel.stringValue = item.label
            itemViews[index].nameLabel.font = (isSelected && _bold) ? NSFont.boldSystemFont(ofSize: 12) : NSFont.systemFont(ofSize: 12)
            itemViews[index].nameLabel.textColor = isSelected ? ThemeColor.contrastColor : ThemeColor.dateColor
            itemViews[index].nameLabel.sizeToFit()
        }
        
        self.needsLayout = true
    }
    
    // レイアウト
    override func layout() {
        let tabItemsWidth = self.frame.width - (showAddButton ? 20 : 0) // 追加ボタンを除いた幅
        let itemWidth = tabItemsWidth / CGFloat(itemViews.count) // アイテムビューの幅
        
        tabBar.frame = self.frame
        
        // アイテムビューをレイアウト
        for (index, itemView) in itemViews.enumerated() {
            itemView.frame = NSRect(x: itemWidth * CGFloat(index),
                                    y: 0,
                                    width: itemWidth,
                                    height: 20)
            
            // アイテムビュー内部をレイアウト
            itemView.layout()
        }
        
        // 追加ボタン
        addButton.frame = NSRect(x: tabItemsWidth,
                                 y: 0,
                                 width: 20,
                                 height: 20)
    }
    
    // テーマ変更
    override func updateLayer() {
        setProperties()
        
        refresh()
    }
}

// タブアイテムの内部オブジェクト
final class PgoTabItem: NSTabViewItem {
    private var _name: String = ""
    override var label: String {
        get {
            return _name
        }
        set {
            _name = newValue
            
            (tabView as? PgoTabView)?.refresh()
        }
    }
    
    // 削除前に呼ばれる
    func willRemove() {
        viewController?.parent?.removeFromParent()
        viewController?.view.removeFromSuperview()
    }
}

// タブアイテムの表示ビュー
private class PgoTabItemView: NSView {
    let closeButton = NSButton() // 閉じるボタン
    let nameLabel = MyTextField() // 名前表示
    let infoLabel = MyTextField() // 未読数表示
    weak var tabView: PgoTabView?
    
    // 初期化
    init(tabView: PgoTabView) {
        self.tabView = tabView
        
        super.init(frame: NSRect(x: 0, y: 0, width: 0, height: 0))
        
        self.addSubview(nameLabel)
        self.addSubview(infoLabel)
        self.addSubview(closeButton)
        
        let attributedTitle = NSMutableAttributedString(string: "×")
        attributedTitle.addAttributes( [NSAttributedString.Key.foregroundColor : ThemeColor.contrastColor],
                                       range: NSRange(location: 0, length: attributedTitle.length))
        closeButton.attributedTitle = attributedTitle
        closeButton.isBordered = false
        closeButton.alphaValue = 0
        closeButton.target = self
        closeButton.action = #selector(closeAction)
        
        nameLabel.drawsBackground = false
        nameLabel.isBordered = false
        nameLabel.isSelectable = false
        nameLabel.isEditable = false
        nameLabel.alignment = .center
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout() {
        if self.frame.width < 18 + nameLabel.frame.width + infoLabel.frame.width {
            // タブの幅が狭い場合
            closeButton.frame = NSRect(x: 0, y: 2, width: 16, height: 16)
            
            nameLabel.frame = NSRect(x: 0,
                                     y: 0,
                                     width: self.frame.width,
                                     height: 20)
            
            infoLabel.frame = NSRect(x: min(nameLabel.frame.maxY, self.frame.width - infoLabel.frame.width),
                                     y: 2,
                                     width: infoLabel.frame.width,
                                     height: 16)
        } else {
            closeButton.frame = NSRect(x: 2, y: 2, width: 16, height: 16)
            
            nameLabel.frame = NSRect(x: 18,
                                     y: 0,
                                     width: self.frame.width - 18 - infoLabel.frame.width,
                                     height: 18)
            
            infoLabel.frame = NSRect(x: min(nameLabel.frame.maxY, self.frame.width - infoLabel.frame.width),
                                     y: 2,
                                     width: infoLabel.frame.width,
                                     height: 16)
        }
    }
    
    // 閉じるボタンクリック時
    @objc func closeAction() {
        guard let index = tabView?.itemViews.firstIndex(of: self) else { return }
        let item = tabView!.items[index]
        tabView?.delete(item: item)
    }
    
    // マウスクリック時
    override func mouseDown(with event: NSEvent) {
        tabView?.select(itemView: self)
    }
    
    // マウスがビューに入った時
    override func mouseEntered(with event: NSEvent) {
        if tabView?.items.count == 1 { return } // アイテムが1つだけの場合は閉じない
        
        closeButton.alphaValue = 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.closeButton.alphaValue = 1
        }
        
        // ドラッグ時に手前に表示されるようにする
        if self != self.superview?.subviews.last {
            let superview = self.superview
            self.removeFromSuperview()
            superview?.addSubview(self)
        }
    }
    
    // マウスがビューから出た時
    override func mouseExited(with event: NSEvent) {
        if self.closeButton.alphaValue == 1 {
            closeButton.alphaValue = 0.5
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.closeButton.alphaValue = 0
        }
        
        
        if dragFlag {
            tabView?.needsLayout = true
            dragFlag = false
        }
    }
    
    // mouseEnteredとmouseExitedを動作させる
    override func updateTrackingAreas() {
        for trackingArea in self.trackingAreas.reversed() {
            self.removeTrackingArea(trackingArea)
        }
        
        let options: NSTrackingArea.Options = [
            .mouseEnteredAndExited,
            .activeAlways
        ]
        let trackingArea = NSTrackingArea(rect: bounds,
                                          options: options,
                                          owner: self,
                                          userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    // ドラッグ&ドロップでのタブ入れ替え
    private var dragFlag = false
    override func mouseDragged(with event: NSEvent) {
        self.frame.origin.x += event.deltaX
        
        dragFlag = true
    }
    
    override func mouseUp(with event: NSEvent) {
        if !dragFlag { return }
        
        tabView?.needsLayout = true
        
        guard let tabView = self.tabView else { return }
        guard let myIndex = tabView.itemViews.firstIndex(of: self) else { return }
        let myItem = tabView.items[myIndex]
        
        // 0から順方向
        for (index, itemView) in tabView.itemViews.enumerated() {
            if index == myIndex { break }
            if self.frame.origin.x < itemView.frame.origin.x {
                // タブ移動
                tabView.items.remove(at: myIndex)
                tabView.items.insert(myItem, at: index)
            }
        }
        // 最大から逆方向
        for (index, itemView) in tabView.itemViews.enumerated().reversed() {
            if index == myIndex { break }
            if self.frame.origin.x > itemView.frame.origin.x {
                // タブ移動
                tabView.items.insert(myItem, at: index + 1)
                tabView.items.remove(at: myIndex)
            }
        }
        
        // 画面更新
        tabView.refresh()
        
        // 元のタブを選択
        if let newIndex = tabView.items.firstIndex(of: myItem) {
            let newItemView = tabView.itemViews[newIndex]
            tabView.select(itemView: newItemView)
            tabView.refresh()
        }
        
        dragFlag = false
    }
}
