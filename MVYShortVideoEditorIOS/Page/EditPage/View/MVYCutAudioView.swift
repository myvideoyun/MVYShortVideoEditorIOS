//
//  MVYCutAudioView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYCutAudioViewDelegate : class {
    // 手指划动时的时间的回调
    func cutAudioOnTouching(_ currentTime:Double)
    
    // 手指抬起
    func cutAudioOnTouchEnd()
}

class MVYCutAudioView: UIControl {

    weak var delegate:MVYCutAudioViewDelegate? = nil
    
    private let sampleCount = 40
    private var audioAveragePowerData = [NSNumber]()
    private var audioDuration = Double(0)
    
    private var startTime = 0.0
    private var duration = 0.0
    
    private var point = CGPoint.zero
    
    // 音频路径, 裁切的开始时间, 裁切的时长
    func setData(audioURL: URL, startTime: Double, duration: Double) {
        
        audioAveragePowerData = MVYAudioAveragePower.averagePower(withAudioURL: audioURL, sampleCount: UInt(sampleCount)) as! [NSNumber]
        
        let asset = AVURLAsset.init(url: audioURL)
        audioDuration = asset.duration.seconds
        
        self.startTime = startTime
        self.duration = duration
        
        setNeedsDisplay()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        
        self.point = touch.location(in: self)
        
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        let lastPoint = touch.location(in: self)
        
        self.moveHandle(lastPoint)
        
        self.point = lastPoint
        
        self.sendActions(for: .valueChanged)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        
        self.delegate?.cutAudioOnTouchEnd()
    }
    
    private func moveHandle(_ point : CGPoint) {
        let offset = Double(point.x - self.point.x) / 2.0
        
        // 如果低于0
        if self.startTime / self.audioDuration * Double(self.bounds.size.width) + offset < 0 {
            return;
        }
        
        // 如果宽度超出了
        if ((self.startTime + self.duration) / self.audioDuration * Double(self.bounds.size.width) + offset > Double(self.bounds.size.width)) {
            return;
        }
        
        self.startTime = self.startTime + self.audioDuration / Double(self.bounds.size.width) * offset;
        
        setNeedsDisplay()
        
        self.delegate?.cutAudioOnTouching(self.startTime)
    }
    
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        let midY = rect.midY
        let count = self.audioAveragePowerData.count;
        
        // 绘制波形图
        for i in 0..<count {
            
            let sample = self.audioAveragePowerData[i].floatValue
            
            context?.move(to: CGPoint.init(x: Double(self.bounds.size.width) / Double(count + 1) * Double(i + 1), y: Double(midY) * Double(1 - sample)))
            context?.addLine(to: CGPoint.init(x: Double(self.bounds.size.width) / Double(count + 1) * Double(i + 1), y: Double(midY) * Double(1 + sample)))
        }
        
        // 波形图上色
        context?.setStrokeColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context?.setLineWidth(4)
        context?.setLineCap(.round)
        context?.strokePath()
        
        // 绘制四边形
        context?.addRect(CGRect.init(x: Double(self.bounds.size.width) / self.audioDuration * self.startTime, y: 0, width: Double(self.bounds.size.width) / self.audioDuration * self.duration, height: Double(self.bounds.size.height)))
        UIColor.init(red: 1, green: 0, blue: 0, alpha: 1).set()
        context?.setBlendMode(.sourceIn)
        context?.fillPath()
        
        super.draw(rect)
    }
}
