//
//  ExtensionUIButton.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

extension UIButton {

    func setVerticalButton(_ image:UIImage, _ title:String, _ font:UIFont, _ textColor:UIColor, _ state:UIControl.State, _ padding:CGFloat) {
        let size = (title as NSString).size(withAttributes: [NSAttributedString.Key.font: font])
        self.imageView?.contentMode = .center
        self.imageEdgeInsets = UIEdgeInsets.init(top: -size.height-padding, left: 0.0, bottom: 0.0, right: -size.width)
        self.setImage(image, for: state)
        
        self.titleLabel?.contentMode = .center
        self.titleLabel?.backgroundColor = UIColor.clear;
        self.titleLabel?.font = font
        self.titleEdgeInsets = UIEdgeInsets.init(top: image.size.height+padding, left: -image.size.width, bottom: 0.0, right: 0.0)
        self.setTitle(title, for: state)
        self.setTitleColor(textColor, for: state)
    }
    
    func setHorizontalButton(_ image:UIImage, _ title:String, _ font:UIFont, _ textColor:UIColor, _ state:UIControl.State, _ padding:CGFloat) {
        self.imageView?.contentMode = .center
        self.setImage(image, for: state)
        
        self.titleLabel?.contentMode = .center
        self.titleLabel?.backgroundColor = UIColor.clear
        self.titleLabel?.font = font
        self.titleEdgeInsets = UIEdgeInsets.init(top: 0.0, left: padding, bottom: 0.0, right: 0.0)
        self.setTitle(title, for: state)
        self.setTitleColor(textColor, for: state)
    }
}
