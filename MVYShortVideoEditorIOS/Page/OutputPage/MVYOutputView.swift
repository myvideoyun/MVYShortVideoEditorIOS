//
//  MVYOutputView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/8.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYOutputViewDelegate : class {
    func saveMedia(frameRate:String, videoBitrate:String, audioBitrate:String)
}

class MVYOutputView: UIView {
    
    weak var delegate:MVYOutputViewDelegate?
    
    private let titleLabel = UILabel()
    private let frameRateLabel = UILabel()
    private let frameRateRadioBt = MVYRadioButton()
    private let line = UIView()
    private let videoBitrateLabel = UILabel()
    private let videoBitrateRadioBt = MVYRadioButton()
    private let line1 = UIView()
    private let audioBitrateLabel = UILabel()
    private let audioBitrateRadioBt = MVYRadioButton()
    private let line2 = UIView()
    let saveBt = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        self.addSubview(titleLabel)
        self.addSubview(frameRateLabel)
        self.addSubview(frameRateRadioBt)
        self.addSubview(line)
        self.addSubview(videoBitrateLabel)
        self.addSubview(videoBitrateRadioBt)
        self.addSubview(line1)
        self.addSubview(audioBitrateLabel)
        self.addSubview(audioBitrateRadioBt)
        self.addSubview(line2)
        self.addSubview(saveBt)
        
        self.backgroundColor = UIColor.white
        
        titleLabel.text = "导出参数"
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textAlignment = NSTextAlignment.center
        
        frameRateLabel.text = "分辨率"
        frameRateLabel.font = UIFont.systemFont(ofSize: 14)
        frameRateLabel.textColor = UIColor.gray
        
        frameRateRadioBt.setupView(texts: ["15","24","30"])
        frameRateRadioBt.setSelectedText("30")
        
        line.backgroundColor = UIColor.gray
        
        videoBitrateLabel.text = "视频码率\n(kbps)"
        videoBitrateLabel.font = UIFont.systemFont(ofSize: 14)
        videoBitrateLabel.textColor = UIColor.gray
        videoBitrateLabel.numberOfLines = 2
        
        videoBitrateRadioBt.setupView(texts: ["2048","4096","8192"])
        videoBitrateRadioBt.setSelectedText("4096")
        
        line1.backgroundColor = UIColor.gray
        
        audioBitrateLabel.text = "音频帧率\n(kbps)"
        audioBitrateLabel.font = UIFont.systemFont(ofSize: 14)
        audioBitrateLabel.textColor = UIColor.gray
        audioBitrateLabel.numberOfLines = 2
        
        audioBitrateRadioBt.setupView(texts: ["64","128","256"])
        audioBitrateRadioBt.setSelectedText("64")
        
        line2.backgroundColor = UIColor.gray
        
        saveBt.setTitle("保存到相册", for: .normal)
        saveBt.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        saveBt.setTitleColor(UIColor.blue, for: .normal)
        saveBt.addTarget(self, action: #selector(onSaveBtClick(_:)), for: .touchUpInside)
        
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.snp.top).offset(22)
            make.width.equalTo(self.snp.width)
            make.height.equalTo(44)
        }
        
        frameRateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.26)
            make.height.equalTo(45)
        }
        
        frameRateRadioBt.snp.makeConstraints { (make) in
            make.left.equalTo(frameRateLabel.snp.right)
            make.top.equalTo(frameRateLabel.snp.top)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(frameRateLabel.snp.bottom)
        }
        
        line.snp.makeConstraints { (make) in
            make.left.equalTo(frameRateLabel.snp.left)
            make.right.equalTo(frameRateRadioBt.snp.right)
            make.top.equalTo(frameRateLabel.snp.bottom)
            make.height.equalTo(0.5)
        }
        
        videoBitrateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.top.equalTo(frameRateLabel.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.26)
            make.height.equalTo(45)
        }
        
        videoBitrateRadioBt.snp.makeConstraints { (make) in
            make.left.equalTo(videoBitrateLabel.snp.right)
            make.top.equalTo(videoBitrateLabel.snp.top)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(videoBitrateLabel.snp.bottom)
        }
        
        line1.snp.makeConstraints { (make) in
            make.left.equalTo(videoBitrateLabel.snp.left)
            make.right.equalTo(videoBitrateRadioBt.snp.right)
            make.top.equalTo(videoBitrateLabel.snp.bottom)
            make.height.equalTo(0.5)
        }
        
        audioBitrateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.top.equalTo(videoBitrateLabel.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.26)
            make.height.equalTo(45)
        }
        
        audioBitrateRadioBt.snp.makeConstraints { (make) in
            make.left.equalTo(audioBitrateLabel.snp.right)
            make.top.equalTo(audioBitrateLabel.snp.top)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(audioBitrateLabel.snp.bottom)
        }
        
        line2.snp.makeConstraints { (make) in
            make.left.equalTo(audioBitrateLabel.snp.left)
            make.right.equalTo(self.audioBitrateRadioBt.snp.right)
            make.top.equalTo(audioBitrateLabel.snp.bottom)
            make.height.equalTo(0.5)
        }
        
        saveBt.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(90)
            make.right.equalToSuperview().offset(-90)
            make.bottom.equalToSuperview().offset(-60)
            make.height.equalTo(80)
        }
    }
    
    func setResolution(_ frameRate:String) {
        frameRateRadioBt.setSelectedText(frameRate)
    }
    
    func frameRate()->String {
        return frameRateRadioBt.selectedText!;
    }
    
    func setVideoBitrate(_ videoBitrate:String) {
        videoBitrateRadioBt.setSelectedText(videoBitrate)
    }
    
    func videoBitrate()->String {
        return videoBitrateRadioBt.selectedText!
    }
    
    func setAudioBitrate(_ audioBitrate:String) {
        audioBitrateRadioBt.setSelectedText(audioBitrate)
    }
    
    func audioBitrate()->String {
        return audioBitrateRadioBt.selectedText!
    }
    
    @objc func onSaveBtClick(_ button: UIButton) {
        delegate?.saveMedia(frameRate: frameRate(), videoBitrate: videoBitrate(), audioBitrate: audioBitrate())
    }
}
