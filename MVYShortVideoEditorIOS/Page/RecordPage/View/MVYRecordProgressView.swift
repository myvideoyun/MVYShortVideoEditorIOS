//
//  MVYRecordProgressView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYRecordProgressView: UIView {
    
    var longestVideoSeconds:Float64 = 60
    
    var recordingMedia:MVYMediaItemModel? = nil
    var medias = Array<MVYMediaItemModel>()

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
        self.backgroundColor = UIColor.clear
    }
    
    override func draw(_ rect: CGRect) {
        let bezierPath = UIBezierPath.init()
        bezierPath.lineCapStyle = .butt
        bezierPath.lineWidth = 10
        
        let orengeColor = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
    
        var percentCount:Float64 = 0
        for x in 0..<medias.count {
            let model = medias[x]
            
            let percent = (model.videoSeconds ?? 0) / longestVideoSeconds
            
            // 绘制已经录制和片段
            bezierPath.removeAllPoints()
            bezierPath.move(to: CGPoint.init(x: CGFloat(percentCount) * rect.size.width, y: rect.size.height / 2))
            bezierPath.addLine(to: CGPoint.init(x: CGFloat(percentCount + percent) * rect.size.width, y: rect.size.height / 2))
            orengeColor.setStroke()
            bezierPath.stroke()

            // 绘制结束的白色间隔
            bezierPath.removeAllPoints()
            bezierPath.move(to: CGPoint.init(x: CGFloat(percentCount + percent) * rect.size.width - 3, y: rect.size.height / 2))
            bezierPath.addLine(to: CGPoint.init(x: CGFloat(percentCount + percent) * rect.size.width, y: rect.size.height / 2))
        
            UIColor.white.setStroke()
            bezierPath.stroke()
            
            percentCount += percent
        }
        
        if let recordingMedia = self.recordingMedia {
            if (recordingMedia.videoSeconds ?? 0) > 0 {
                let percent = (self.recordingMedia?.videoSeconds ?? 0) / self.longestVideoSeconds
                
                // 绘制正在录制的片段
                bezierPath.removeAllPoints()
                bezierPath.move(to: CGPoint.init(x: CGFloat(percentCount) * rect.size.width, y: rect.size.height / 2))
                bezierPath.addLine(to: CGPoint.init(x: CGFloat(percentCount + percent) * rect.size.width, y: rect.size.height / 2))
                
                orengeColor.setStroke()
                bezierPath.stroke()
            }
        }
    }
}
