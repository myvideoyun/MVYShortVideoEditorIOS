//
//  MVYBeautyPanel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/10.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import pop

protocol MVYBeautyPanelDelegate : class{
    
    func beautyValueChange(_ value: Float)
    
    func brightnessValueChange(_ value: Float)
    
    func saturationValueChange(_ value: Float)
    
}

class MVYBeautyPanel: UIView {

    let contentView = UIView()
    let hideViewTrigger = UIButton()
    let beautyLb = UILabel()
    let beautySlider = UISlider()
    let brightnessLb = UILabel()
    let brightnessSlider = UISlider()
    let saturationLb = UILabel()
    let saturationSlider = UISlider()
    
    weak var delegate:MVYBeautyPanelDelegate? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        isHidden = true
    }
    
    private func setupView() {
        
        hideViewTrigger.backgroundColor = UIColor.clear
        hideViewTrigger.addTarget(self, action: #selector(onHideViewTiggerClick(_:)), for: .touchUpInside)

        beautyLb.text = "美颜强度"
        beautyLb.font = UIFont.systemFont(ofSize: 14)
        beautyLb.textColor = UIColor.white
        beautyLb.textAlignment = .right
        
        beautySlider.minimumValue = 0
        beautySlider.maximumValue = 3
        beautySlider.isContinuous = true
        beautySlider.minimumTrackTintColor = UIColor.blue
        beautySlider.addTarget(self, action: #selector(onSliderValueChange(_ :)), for: .valueChanged)

        brightnessLb.text = "亮度"
        brightnessLb.font = UIFont.systemFont(ofSize: 14)
        brightnessLb.textColor = UIColor.white
        brightnessLb.textAlignment = .right
        
        brightnessSlider.minimumValue = 0
        brightnessSlider.maximumValue = 1
        brightnessSlider.isContinuous = true
        brightnessSlider.minimumTrackTintColor = UIColor.blue
        brightnessSlider.addTarget(self, action: #selector(onSliderValueChange(_ :)), for: .valueChanged)

        saturationLb.text = "饱合度"
        saturationLb.font = UIFont.systemFont(ofSize: 14)
        saturationLb.textColor = UIColor.white
        saturationLb.textAlignment = .right
        
        saturationSlider.minimumValue = 1
        saturationSlider.maximumValue = 2
        saturationSlider.isContinuous = true
        saturationSlider.minimumTrackTintColor = UIColor.blue
        saturationSlider.addTarget(self, action: #selector(onSliderValueChange(_ :)), for: .valueChanged)

        self.addSubview(contentView)
        contentView.addSubview(hideViewTrigger)
        contentView.addSubview(beautyLb)
        contentView.addSubview(beautySlider)
        contentView.addSubview(brightnessLb)
        contentView.addSubview(brightnessSlider)
        contentView.addSubview(saturationLb)
        contentView.addSubview(saturationSlider)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        hideViewTrigger.snp.makeConstraints { (make) in
            make.left.equalToSuperview();
            make.top.equalToSuperview();
            make.right.equalToSuperview();
            make.height.equalToSuperview().multipliedBy(0.7)
        }
        
        beautyLb.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(hideViewTrigger.snp.bottom)
            make.height.equalToSuperview().multipliedBy(0.1)
            make.width.equalToSuperview().dividedBy(5)
        }
        
        beautySlider.snp.makeConstraints { (make) in
            make.left.equalTo(beautyLb.snp.right).offset(10)
            make.top.equalTo(beautyLb.snp.top)
            make.bottom.equalTo(beautyLb.snp.bottom)
            make.right.equalToSuperview().offset(-10)
        }
        
        brightnessLb.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(beautyLb.snp.bottom)
            make.height.equalToSuperview().multipliedBy(0.1)
            make.width.equalToSuperview().dividedBy(5)
        }
        
        brightnessSlider.snp.makeConstraints { (make) in
            make.left.equalTo(brightnessLb.snp.right).offset(10)
            make.top.equalTo(brightnessLb.snp.top)
            make.bottom.equalTo(brightnessLb.snp.bottom)
            make.right.equalToSuperview().offset(-10)
        }
        
        saturationLb.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(brightnessLb.snp.bottom)
            make.height.equalToSuperview().multipliedBy(0.1)
            make.width.equalToSuperview().dividedBy(5)
        }
        
        saturationSlider.snp.makeConstraints { (make) in
            make.left.equalTo(saturationLb.snp.right).offset(10)
            make.top.equalTo(saturationLb.snp.top)
            make.bottom.equalTo(saturationLb.snp.bottom)
            make.right.equalToSuperview().offset(-10)
        }
    }
    
    // MARK: API
    func hideUseAnim(_ hidden:Bool) {
        if !hidden {
            self.isHidden = hidden
        }
        
        let centerAnim = POPSpringAnimation.init(propertyNamed: kPOPViewCenter)
        centerAnim?.springSpeed = 10
        centerAnim?.springBounciness = 6
        
        if hidden {
            centerAnim?.fromValue = NSValue.init(cgPoint: self.center)
            centerAnim?.toValue = NSValue.init(cgPoint: CGPoint.init(x: self.center.x, y: self.center.y + self.frame.size.height * 0.3 + (centerAnim?.springBounciness)!))
        } else {
            centerAnim?.fromValue = NSValue.init(cgPoint: CGPoint.init(x: self.center.x, y: self.center.y + self.frame.size.height * 0.3 + (centerAnim?.springBounciness)!))
            centerAnim?.toValue = NSValue.init(cgPoint: self.center)
        }
        
        centerAnim?.completionBlock = { anim, complete in
            if complete && hidden {
                self.isHidden = hidden
            }
            
            if complete && !hidden {
                self.hideViewTrigger.isEnabled = true
            }
        }
        
        hideViewTrigger.isEnabled = false
        contentView.pop_removeAllAnimations()
        contentView.pop_add(centerAnim, forKey: nil)
    }
    
    @objc func onHideViewTiggerClick(_ button:UIButton) {
        self.hideUseAnim(true)
    }
    
    @objc func onSliderValueChange(_ slide:UISlider) {
        if slide == beautySlider {
            delegate?.beautyValueChange(slide.value)
            
        } else if slide == brightnessSlider {
            delegate?.brightnessValueChange(slide.value)
            
        } else if slide == saturationSlider {
            delegate?.saturationValueChange(slide.value)
        }
    }
}
