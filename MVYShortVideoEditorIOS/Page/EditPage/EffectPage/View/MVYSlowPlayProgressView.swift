//
//  MVYSlowPlayProgressView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/8/11.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYSlowPlayProgressViewDelegate: class {
    /// 跳转到时间
    func slowPlay(startTime: Double, duration: Double)
}

class MVYSlowPlayProgressView: UIControl {
    
    weak var delegate:MVYSlowPlayProgressViewDelegate? = nil
    
    // 进度条底色
    private var bgColor = UIColor.gray
    
    // 视频时间的总长度
    private var duration:Double = 0
    
    // 慢速部分时长
    private var slowPlayDuration:Double = 0
    
    // 慢速播放开始时间
    private var slowPlayStartTime:Double = 0
    
    // 上一次手指点击的位置
    private var point = CGPoint.zero
    
    private var isTouch = false
    
    convenience init(duration: Double, slowPlayDuration: Double) {
        self.init()
        
        self.duration = duration
        self.slowPlayDuration = slowPlayDuration
        
        setNeedsDisplay()
    }
    
    // 更新游标底色
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
        delegate?.slowPlay(startTime: slowPlayStartTime, duration: slowPlayDuration)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        
        isTouch = false
    }
    
    // 手指滑动时的处理
    func moveHandle(point: CGPoint) {
        let offset = Double(point.x - self.point.x)
        
        // 如果低于0
        if slowPlayStartTime / duration * Double(self.bounds.size.width) + offset < 0 {
            slowPlayStartTime = 0
            setNeedsDisplay()
            return
        }
        
        // 如果超出了
        if slowPlayStartTime / (duration - slowPlayDuration) * Double(self.bounds.size.width) + offset > Double(self.bounds.size.width) {
            slowPlayStartTime = duration - slowPlayDuration
            setNeedsDisplay()
            return
        }
        
        // 在范围内
        slowPlayStartTime = slowPlayStartTime + duration / Double(self.bounds.size.width) * offset
        
        setNeedsDisplay()
    }
    
    // 绘制
    override func draw(_ rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        UIColor.clear.set()
        
        // 绘制背景
        context?.addRect(CGRect.init(x: 0, y: 2, width: Double(self.bounds.size.width), height: Double(self.bounds.size.height) - 4))
        UIColor.gray.set()
        context?.fillPath()
        
        // 绘制游标
        context?.addRect(CGRect.init(x: slowPlayStartTime / duration * Double(rect.size.width), y: 0, width: slowPlayDuration / duration * Double(rect.size.width), height: Double(rect.size.height)))
        bgColor.set()

        context?.fillPath()

        super.draw(rect)
    }
}
