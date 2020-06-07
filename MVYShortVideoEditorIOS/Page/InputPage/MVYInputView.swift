//
//  MVYInputView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import SnapKit

class MVYInputView: UIView {
    
    private let titleLabel = UILabel()
    private let resolutionLabel = UILabel()
    private let resolutionRadioBt = MVYRadioButton()
    private let line = UIView()
    private let frameRateLabel = UILabel()
    private let frameRateRadioBt = MVYRadioButton()
    private let line1 = UIView()
    private let videoBitrateLabel = UILabel()
    private let videoBitrateRadioBt = MVYRadioButton()
    private let line2 = UIView()
    private let audioBitrateLabel = UILabel()
    private let audioBitrateRadioBt = MVYRadioButton()
    private let line3 = UIView()
    private let screenRateLabel = UILabel()
    private let screenRateRadioBt = MVYRadioButton()
    private let line4 = UIView()
    let inputBt = UIButton()
    let inputImageBt = UIButton()
    let recordBt = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        self.addSubview(titleLabel)
        self.addSubview(resolutionLabel)
        self.addSubview(resolutionRadioBt)
        self.addSubview(line)
        self.addSubview(frameRateLabel)
        self.addSubview(frameRateRadioBt)
        self.addSubview(line1)
        self.addSubview(videoBitrateLabel)
        self.addSubview(videoBitrateRadioBt)
        self.addSubview(line2)
        self.addSubview(audioBitrateLabel)
        self.addSubview(audioBitrateRadioBt)
        self.addSubview(line3)
        self.addSubview(screenRateLabel)
        self.addSubview(screenRateRadioBt)
        self.addSubview(line4)
        self.addSubview(inputBt)
        self.addSubview(inputImageBt)
        self.addSubview(recordBt)
        
        self.backgroundColor = UIColor.white
        
        titleLabel.text = "录制参数"
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textAlignment = NSTextAlignment.center
        
        resolutionLabel.text = "分辨率"
        resolutionLabel.font = UIFont.systemFont(ofSize: 14)
        resolutionLabel.textColor = UIColor.gray

        resolutionRadioBt.setupView(texts: ["540p","720p","1080p"])
        resolutionRadioBt.setSelectedText("720p")
        
        line.backgroundColor = UIColor.gray
        
        frameRateLabel.text = "帧率(fps)"
        frameRateLabel.font = UIFont.systemFont(ofSize: 14)
        frameRateLabel.textColor = UIColor.gray

        frameRateRadioBt.setupView(texts: ["15","24","30"])
        frameRateRadioBt.setSelectedText("30")
        
        line1.backgroundColor = UIColor.gray
        
        videoBitrateLabel.text = "视频码率\n(kbps)"
        videoBitrateLabel.font = UIFont.systemFont(ofSize: 14)
        videoBitrateLabel.textColor = UIColor.gray
        videoBitrateLabel.numberOfLines = 2
        
        videoBitrateRadioBt.setupView(texts: ["2048","4096","8192"])
        videoBitrateRadioBt.setSelectedText("4096")
        
        line2.backgroundColor = UIColor.gray
        
        audioBitrateLabel.text = "音频帧率\n(kbps)"
        audioBitrateLabel.font = UIFont.systemFont(ofSize: 14)
        audioBitrateLabel.textColor = UIColor.gray
        audioBitrateLabel.numberOfLines = 2
        
        audioBitrateRadioBt.setupView(texts: ["64","128","256"])
        audioBitrateRadioBt.setSelectedText("64")
        
        line3.backgroundColor = UIColor.gray
        
        screenRateLabel.text = "屏幕比例"
        screenRateLabel.font = UIFont.systemFont(ofSize: 14)
        screenRateLabel.textColor = UIColor.gray
        screenRateLabel.numberOfLines = 1
        
        screenRateRadioBt.setupView(texts: ["16:9","4:3","1:1"])
        screenRateRadioBt.setSelectedText("16:9")
        
        line4.backgroundColor = UIColor.gray
        
        recordBt.setVerticalButton(UIImage.init(named: "btn_shooting_n")!, "开始录制", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)
        recordBt.setVerticalButton(UIImage.init(named: "btn_shooting_p")!, "开始录制", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x99/0x255, green: 0x99/0x255, blue: 0x99/0x255, alpha: 1), .highlighted, 10)
        
        inputImageBt.setVerticalButton(UIImage.init(named: "btn_the_import_n")!, "导入图片", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)
        inputImageBt.setVerticalButton(UIImage.init(named: "btn_the_import_p")!, "导入图片", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x99/0x255, green: 0x99/0x255, blue: 0x99/0x255, alpha: 1), .highlighted, 10)

        inputBt.setVerticalButton(UIImage.init(named: "btn_the_import_n")!, "本地导入", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x33/0x255, green: 0x33/0x255, blue: 0x33/0x255, alpha: 1), .normal, 10)
        inputBt.setVerticalButton(UIImage.init(named: "btn_the_import_p")!, "本地导入", UIFont.systemFont(ofSize: 14), UIColor.init(red: 0x99/0x255, green: 0x99/0x255, blue: 0x99/0x255, alpha: 1), .highlighted, 10)
        
        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.top.equalTo(self.snp.top).offset(22)
            make.width.equalTo(self.snp.width)
            make.height.equalTo(44)
        }
        
        resolutionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.26)
            make.height.equalTo(45)
        }
        
        resolutionRadioBt.snp.makeConstraints { (make) in
            make.left.equalTo(resolutionLabel.snp.right)
            make.top.equalTo(resolutionLabel.snp.top)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(resolutionLabel.snp.bottom)
        }

        line.snp.makeConstraints { (make) in
            make.left.equalTo(resolutionLabel.snp.left)
            make.right.equalTo(resolutionRadioBt.snp.right)
            make.top.equalTo(resolutionLabel.snp.bottom)
            make.height.equalTo(0.5)
        }

        frameRateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.top.equalTo(resolutionLabel.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.26)
            make.height.equalTo(45)
        }

        frameRateRadioBt.snp.makeConstraints { (make) in
            make.left.equalTo(frameRateLabel.snp.right)
            make.top.equalTo(frameRateLabel.snp.top)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(frameRateLabel.snp.bottom)
        }

        line1.snp.makeConstraints { (make) in
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

        line2.snp.makeConstraints { (make) in
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
        
        line3.snp.makeConstraints { (make) in
            make.left.equalTo(audioBitrateLabel.snp.left)
            make.right.equalTo(self.audioBitrateRadioBt.snp.right)
            make.top.equalTo(audioBitrateLabel.snp.bottom)
            make.height.equalTo(0.5)
        }
        
        screenRateLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.top.equalTo(audioBitrateLabel.snp.bottom)
            make.width.equalTo(self.snp.width).multipliedBy(0.26)
            make.height.equalTo(45)
        }
        
        screenRateRadioBt.snp.makeConstraints { (make) in
            make.left.equalTo(screenRateLabel.snp.right)
            make.top.equalTo(screenRateLabel.snp.top)
            make.right.equalTo(self.snp.right).offset(-15)
            make.bottom.equalTo(screenRateLabel.snp.bottom)
        }
        
        line4.snp.makeConstraints { (make) in
            make.left.equalTo(screenRateLabel.snp.left)
            make.right.equalTo(screenRateRadioBt.snp.right)
            make.top.equalTo(screenRateLabel.snp.bottom)
            make.height.equalTo(0.5)
        }

        recordBt.snp.makeConstraints { (make) in
            make.right.equalTo(self.snp.right)
            make.bottom.equalTo(self.snp.bottom).offset(-30)
            make.width.equalTo(self.snp.width).dividedBy(3)
        }
        
        inputImageBt.snp.makeConstraints { (make) in
            make.right.equalTo(self.recordBt.snp.left)
            make.bottom.equalTo(self.snp.bottom).offset(-30)
            make.width.equalTo(self.snp.width).dividedBy(3)
        }
        
        inputBt.snp.makeConstraints { (make) in
            make.right.equalTo(self.inputImageBt.snp.left)
            make.bottom.equalTo(self.snp.bottom).offset(-30)
            make.width.equalTo(self.snp.width).dividedBy(3)
        }
    }
    
    func setResolution(_ resolution:String) {
        resolutionRadioBt.setSelectedText(resolution)
    }
    
    func resolution()->String {
        return resolutionRadioBt.selectedText!;
    }
    
    func setFrameRate(_ frameRate:String) {
        frameRateRadioBt.setSelectedText(frameRate)
    }
    
    func frameRate()->String {
        return frameRateRadioBt.selectedText!
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
    
    func setScreenRate(_ screenRate:String) {
        screenRateRadioBt.setSelectedText(screenRate)
    }
    
    func screenRate()->String {
        return screenRateRadioBt.selectedText!
    }
}
