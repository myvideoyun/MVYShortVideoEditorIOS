//
//  MVYImageTransitionView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/7/1.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYImageTransitionViewDelegate: class {
    
    func pushToNextPage()
    
    func imageTransitionTypeChange(type: MVYImageTransitionType)
}

class MVYImageTransitionView: UIView {
    
    weak var delegate: MVYImageTransitionViewDelegate?

    let nextBt = UIButton()
    let previewView = MVYPixelBufferPreview()
    let effectBt1 = UIButton()
    let effectBt2 = UIButton()
    let effectBt3 = UIButton()
    let effectBt4 = UIButton()
    let effectBt5 = UIButton()
    let effectBt6 = UIButton()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        bindView()
    }
    
    private func setupView() {
        nextBt.setTitle("下一步", for: .normal)
        nextBt.setTitleColor(UIColor.white, for: .normal)
        
        effectBt1.setVerticalButton(UIImage.init(named: "btn_edit_image_1")!, "左右", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)
        
        effectBt2.setVerticalButton(UIImage.init(named: "btn_edit_image_2")!, "上下", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)
        
        effectBt3.setVerticalButton(UIImage.init(named: "btn_edit_image_3")!, "放大", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)
        
        effectBt4.setVerticalButton(UIImage.init(named: "btn_edit_image_4")!, "缩小", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)

        effectBt5.setVerticalButton(UIImage.init(named: "btn_edit_image_5")!, "旋转", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)

        effectBt6.setVerticalButton(UIImage.init(named: "btn_edit_image_6")!, "淡入淡出", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)


        self.addSubview(previewView)
        self.addSubview(nextBt)
        self.addSubview(effectBt1)
        self.addSubview(effectBt2)
        self.addSubview(effectBt3)
        self.addSubview(effectBt4)
        self.addSubview(effectBt5)
        self.addSubview(effectBt6)

        previewView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
        }
        
        nextBt.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-50)
            make.top.equalToSuperview().offset(20)
        }
        
        effectBt1.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalTo(previewView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(6)
        }
        
        effectBt2.snp.makeConstraints { (make) in
            make.left.equalTo(effectBt1.snp.right)
            make.top.equalTo(previewView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(6)
        }
        
        effectBt3.snp.makeConstraints { (make) in
            make.left.equalTo(effectBt2.snp.right)
            make.top.equalTo(previewView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(6)
        }
        
        effectBt4.snp.makeConstraints { (make) in
            make.left.equalTo(effectBt3.snp.right)
            make.top.equalTo(previewView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(6)
        }
        
        effectBt5.snp.makeConstraints { (make) in
            make.left.equalTo(effectBt4.snp.right)
            make.top.equalTo(previewView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(6)
        }
        
        effectBt6.snp.makeConstraints { (make) in
            make.left.equalTo(effectBt5.snp.right)
            make.top.equalTo(previewView.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(6)
        }
    }
    
    private func bindView() {
        nextBt.addTarget(self, action: #selector(onNextBtClick(_:)), for: .touchUpInside)
        effectBt1.addTarget(self, action: #selector(onEffectBtClick(_:)), for: .touchUpInside)
        effectBt2.addTarget(self, action: #selector(onEffectBtClick(_:)), for: .touchUpInside)
        effectBt3.addTarget(self, action: #selector(onEffectBtClick(_:)), for: .touchUpInside)
        effectBt4.addTarget(self, action: #selector(onEffectBtClick(_:)), for: .touchUpInside)
        effectBt5.addTarget(self, action: #selector(onEffectBtClick(_:)), for: .touchUpInside)
        effectBt6.addTarget(self, action: #selector(onEffectBtClick(_:)), for: .touchUpInside)
    }
    
    @objc func onNextBtClick(_ button: UIButton) {
        delegate?.pushToNextPage()
    }
    
    @objc func onEffectBtClick(_ button: UIButton) {
        switch button {
        case effectBt1:
            delegate?.imageTransitionTypeChange(type: .LeftToRight)
            break
        case effectBt2:
            delegate?.imageTransitionTypeChange(type: .TopToBottom)
            break
        case effectBt3:
            delegate?.imageTransitionTypeChange(type: .ZoomOut)
            break
        case effectBt4:
            delegate?.imageTransitionTypeChange(type: .ZoomIn)
            break
        case effectBt5:
            delegate?.imageTransitionTypeChange(type: .RotateAndZoomIn)
            break
        case effectBt6:
            delegate?.imageTransitionTypeChange(type: .Transparent)
            break
        default:
            delegate?.imageTransitionTypeChange(type: .LeftToRight)
        }
    }
}
