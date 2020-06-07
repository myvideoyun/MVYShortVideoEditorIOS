//
//  MVYEffectProgressView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/23.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYEffectProgressViewDelegate: class {
    /// 跳转到时间
    func seekTo(time: Double)
}

class MVYEffectProgressView: UIControl {
    
    weak var delegate:MVYEffectProgressViewDelegate? = nil
    
    // 进度条底色
    private var bgColor = UIColor.gray
    
    // 视频时间的总长度
    private var duration:Double = 0
    
    // 特效时间数据
    private var effectTimeModels = [MVYEffectTimeModel]()
    
    // 播放器当前时间的位置
    private var currentTime:Double = 0
    
    // 上一次手指点击的位置
    private var point = CGPoint.zero
    
    private var isTouch = false
    
    convenience init(duration: Double) {
        self.init()
        
        self.duration = duration
        
        setNeedsDisplay()
    }
    
    // 更新特效时间数据
    func update(effectTimeModels: [MVYEffectTimeModel]) {
        self.effectTimeModels = effectTimeModels
        
        setNeedsDisplay()
    }
    
    // 更新当前时间进度
    func update(currentTime: Double) {
        if self.isTouch {
            return
        }
        
        self.currentTime = currentTime

        setNeedsDisplay()
    }
    
    // 更新进度条底色
    func update(decoderWorkType: MVYDecoderWorkTypeModel) {
        self.bgColor = decoderWorkType.color
        
        setNeedsDisplay()
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let point = touch.location(in: self)
        
        self.point = point
        
        isTouch = true
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        
        let point = touch.location(in: self)
        
        moveHandle(point: point)
        
        self.point = point
        
        self.sendActions(for: .valueChanged)
        
        // 跳转到相应的时间
        delegate?.seekTo(time: currentTime)
        
        return true
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        
        isTouch = false
    }
    
    // 手指滑动时的处理
    func moveHandle(point: CGPoint) {
        let offset = Double(point.x - self.point.x)
        
        // 如果低于0
        if currentTime / duration * Double(self.bounds.size.width) + offset < 0 {
            currentTime = 0
            setNeedsDisplay()
            return
        }
        
        // 如果超出了
        if currentTime / duration * Double(self.bounds.size.width) + offset > Double(self.bounds.size.width) {
            currentTime = duration
            setNeedsDisplay()
            return
        }
        
        // 在范围内
        currentTime = currentTime + duration / Double(self.bounds.size.width) * offset
        
        setNeedsDisplay()
    }
    
    // 绘制
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        UIColor.clear.set()
        
        // 绘制背景
        context?.addRect(CGRect.init(x: 0, y: 2, width: Double(self.bounds.size.width), height: Double(self.bounds.size.height) - 4))
        bgColor.set()
        context?.fillPath()
        
        // 绘制特效时间
        UIGraphicsPushContext(context!)
        
        UIGraphicsBeginImageContext(self.bounds.size)
        let newContext = UIGraphicsGetCurrentContext()
        
        for x in 0..<effectTimeModels.count {
            let timeModel = effectTimeModels[x]
            newContext?.addRect(CGRect.init(x: Double(timeModel.startTime) / self.duration * Double(rect.size.width), y: 0, width: Double(timeModel.duration) / self.duration * Double(rect.size.width), height: Double(rect.size.height)))
            timeModel.effectColor.set()
            newContext?.fillPath()
        }
        
        let effectTimeImg = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        UIGraphicsPopContext()
        
        effectTimeImg?.draw(in: CGRect.init(x: 0, y: 2, width: rect.size.width, height: rect.size.height - 4), blendMode: .normal, alpha: 1)
        
        // 绘制游标
        context?.setAlpha(1)
        context?.move(to: CGPoint.init(x: currentTime / duration * Double(rect.size.width), y: 0))
        context?.addLine(to: CGPoint.init(x: currentTime / duration * Double(rect.size.width), y: Double(rect.size.height)))
        
        context?.setStrokeColor(UIColor.init(red: 0xFE/0xFF, green: 0x70/0xFF, blue: 0x44/0xFF, alpha: 1).cgColor)
        context?.setLineWidth(4)
        context?.setLineCap(.butt)
        context?.strokePath()
        
        super.draw(rect)
    }
}
