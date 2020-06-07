//
//  MVYSubtitlePanel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYSubtitlePanel: MVYStickerPanel {

    override func setupView() {
        super.setupView()
        
        let label1 = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        label1.text = "1️⃣"
        sticker1IconIv.image = UIImage.imageWithLabel(label: label1)
        
        let label2 = UILabel(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        label2.text = "2️⃣"
        sticker2IconIv.image = UIImage.imageWithLabel(label: label2)

        let stickerLabel1 = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 50))
        stickerLabel1.text = "这是第一条字幕"
        stickerLabel1.textAlignment = .center
        stickerLabel1.font = UIFont.systemFont(ofSize: 16)
        stickerLabel1.textColor = UIColor.white
        stickerView1.image = UIImage.imageWithLabel(label: stickerLabel1)
        
        let stickerLabel2 = UILabel(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 50))
        stickerLabel2.text = "这是第二条字幕"
        stickerLabel2.textAlignment = .center
        stickerLabel2.font = UIFont.systemFont(ofSize: 16)
        stickerLabel2.textColor = UIColor.white
        stickerView2.image = UIImage.imageWithLabel(label: stickerLabel2)
        
        
        stickerView1.snp.remakeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(50)
            make.center.equalToSuperview()
        }
        
        stickerView2.snp.remakeConstraints { (make) in
            make.width.equalToSuperview()
            make.height.equalTo(50)
            make.center.equalToSuperview()
        }

    }
}


extension UIImage {
    class func imageWithLabel(label: UILabel) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(label.bounds.size, false, 0.0)
        label.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
