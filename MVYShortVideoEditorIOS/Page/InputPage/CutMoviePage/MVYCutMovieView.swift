//
//  MVYCutMovieView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/5.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import SnapKit

class MVYCutMovieView: UIView {
    
    let previewView = MVYPixelBufferPreview()

    let seekSlider = RangeSeekSlider()
    
    let nextBt = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {        
        seekSlider.hideLabels = true
        seekSlider.lineHeight = 4
        seekSlider.initialColor = UIColor.red
        seekSlider.tintColor = UIColor.gray
        seekSlider.handleColor = UIColor.red
        seekSlider.colorBetweenHandles = UIColor.red
        seekSlider.selectedHandleDiameterMultiplier = 1
        seekSlider.handleDiameter = 15
        
        nextBt.setTitle("下一步", for: .normal)
        nextBt.setTitleColor(UIColor.white, for: .normal)
        
        self.addSubview(previewView)
        self.addSubview(seekSlider)
        self.addSubview(nextBt)
        
        previewView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-100)
        }
        
        seekSlider.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(40)
            make.top.equalTo(previewView.snp.bottom)
            make.right.equalToSuperview().offset(-40)
            make.bottom.equalToSuperview()
        }
        
        nextBt.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-50)
            make.top.equalToSuperview().offset(20)
        }
    }
}
