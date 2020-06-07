//
//  MVYRadioButton.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import SnapKit


/// 单选按钮
class MVYRadioButton: UIView {
    
    // 选中的按钮
    var selectedText:String? = nil
    
    // 全部按钮
    private var texts = Array<String>()
    private var buttons = Array<UIButton>()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    /// 设置视图
    ///
    /// - Parameter texts: 所有按钮的文本
    func setupView(texts:Array<String>) {
        self.texts = texts
        
        for button in self.buttons {
            button.removeFromSuperview()
        }
        
        for text in texts {
            let button = UIButton.init(type: .custom)
            button.setTitle(text, for: .normal)
            button.setTitleColor(UIColor.gray, for: .normal)
            button.setTitleColor(UIColor.blue, for: .selected)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
            button.addTarget(self, action: #selector(onButtonClick(_ :)), for: .touchUpInside)
            
            self.addSubview(button)
            self.buttons.append(button)
        }
        
        for x in 0..<self.buttons.count {
            let button = self.buttons[x]
            button.snp.makeConstraints { (make) in
                if button == self.buttons.first {
                    make.left.equalTo(self.snp.left)
                } else {
                    make.left.equalTo(self.buttons[x-1].snp.right)
                }
                make.top.equalTo(self.snp.top)
                make.width.equalTo(self.snp.width).dividedBy(texts.count)
                make.bottom.equalTo(self.snp.bottom)
            }
        }
    }
    
    @objc func onButtonClick(_ button:UIButton) {
        if let index = self.buttons.firstIndex(of: button) {
            let text = self.texts[index]
            self.selectedText = text;
            
            for button in self.buttons {
                button.isSelected = false
            }
            
            button.isSelected = true
        }
    }
    
    /// 设置选中的文件
    ///
    /// - Parameter selectedText: 选中的文本
    func setSelectedText(_ selectedText:String) {
        if let index = self.texts.firstIndex(of: selectedText) {
            let button = self.buttons[index];
            self.onButtonClick(button)
        }
    }
}
