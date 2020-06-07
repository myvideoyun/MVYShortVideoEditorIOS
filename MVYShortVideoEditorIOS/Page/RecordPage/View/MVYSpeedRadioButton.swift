//
//  MVYSpeedRadioButton.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYSpeedRadioButton: UIView {

    private let texts = ["极慢","慢","标准","快","极快"];
    private var buttons = Array<UIButton>()
    
    var selectedText:String? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    private func setupView() {
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.cornerRadius = 3
        self.clipsToBounds = true
        
        for x in 0..<texts.count {
            let text = texts[x]
            let button = UIButton()
            button.setTitle(text, for: .normal)
            button.setTitleColor(UIColor.white, for: .normal)
            button.setTitleColor(UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1), for: .selected)
            button.setBackgroundImage(imageFromColor(UIColor.white), for: .selected)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 11)
            
            button.addTarget(self, action: #selector(onButtonClick(_:)), for: .touchUpInside)
            
            self.addSubview(button)
            self.buttons.append(button)
        }
        
        for x in 0..<self.buttons.count {
            let button  = self.buttons[x]
            
            button.snp.makeConstraints { (make) in
                if x == 0 {
                    make.left.equalTo(self.snp.left)
                } else {
                    make.left.equalTo(self.buttons[x-1].snp.right)
                }
                make.top.equalTo(self.snp.top)
                make.width.equalTo(self.snp.width).dividedBy(self.texts.count)
                make.bottom.equalTo(self.snp.bottom)
            }
        }
        
    }
    
    @objc func onButtonClick(_ button:UIButton) {
        for button in self.buttons {
            button.isSelected = false
        }
        
        button.isSelected = true
        self.selectedText = button.titleLabel?.text
    }
    
    func setSelectedText(_ text:String) {
        if let index = self.texts.firstIndex(of:text) {
            let button = self.buttons[index]
            self.onButtonClick(button)
        }
    }
    
    func imageFromColor(_ color:UIColor)->UIImage {
        let size = CGSize.init(width: 1, height: 1)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(CGRect.init(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
