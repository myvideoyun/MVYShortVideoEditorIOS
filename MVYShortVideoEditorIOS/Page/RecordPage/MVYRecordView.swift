//
//  MVYRecordView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYRecordViewDelegate: class {
    func switchCamera()
    
    func next()
    
    func beautyValueChange(_ value: Float)
    
    func brightnessValueChange(_ value: Float)
    
    func saturationValueChange(_ value: Float)
    
    func style(_ model:MVYStyleModel)
    
    func music()
    
    func startRecord()
    
    func stopRecord()
    
    func delete()
}

class MVYRecordView: UIView, MVYStylePanelDelegate, MVYBeautyPanelDelegate {

    weak var delegate:MVYRecordViewDelegate? = nil
    
    private let contentTag = 1
    private let recordTag = 2
    
    private let stylePanel = MVYStylePanel()
    private let beautyPanel = MVYBeautyPanel()
    let speedRadioButton = MVYSpeedRadioButton()
    let progressView = MVYRecordProgressView()
    let recordButton = UIButton()
    private let beautyButton = UIButton()
    private let switchCameraButton = UIButton()
    private let containerView = UIView()
    private let nextButton = UIButton()
    private let styleButton = UIButton()
    private let recordButtonLeftLayout = UIView()
    private let progressBG = UIImageView()
    private let recordButtonRightLayout = UIView()
    private let removeVideoItemButton = UIButton()
    private let musicButton = UIButton()

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
        self.addSubview(switchCameraButton)
        self.addSubview(containerView)
        containerView.addSubview(nextButton)
        containerView.addSubview(styleButton)
        containerView.addSubview(beautyButton)
        containerView.addSubview(musicButton)
        self.addSubview(speedRadioButton)
        self.addSubview(recordButtonLeftLayout)
        self.addSubview(progressBG)
        self.addSubview(progressView)
        self.addSubview(recordButton)
        self.addSubview(recordButtonRightLayout)
        recordButtonRightLayout.addSubview(removeVideoItemButton)
        self.addSubview(stylePanel)
        self.addSubview(beautyPanel)
        
        // 设置普通控件的TAG
        switchCameraButton.tag = contentTag
        containerView.tag = contentTag
        nextButton.tag = contentTag
        styleButton.tag = contentTag
        beautyButton.tag = contentTag
        musicButton.tag = contentTag
        speedRadioButton.tag = contentTag
        recordButtonLeftLayout.tag = contentTag
        recordButtonRightLayout.tag = contentTag
        
        // 设置录制控件的TAG
        progressBG.tag = recordTag
        progressView.tag = recordTag
        recordButton.tag = recordTag
        
        switchCameraButton.setImage(UIImage.init(named: "btn_toggle_n"), for: .normal)
        switchCameraButton.setImage(UIImage.init(named: "btn_toggle_p"), for: .highlighted)
        switchCameraButton.addTarget(self, action: #selector(onSwitchCameraButtonClick(_:)), for: .touchUpInside)

        nextButton.setTitle("下一步", for: .normal)
        nextButton.setTitleColor(UIColor.white, for: .normal)
        nextButton.addTarget(self, action: #selector(onNextButtonClick(_:)), for: .touchUpInside)
        
        styleButton.setVerticalButton(UIImage.init(named: "btn_filter_n")!, "滤镜", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        styleButton.setVerticalButton(UIImage.init(named: "btn_filter_p")!, "滤镜", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        styleButton.addTarget(self, action: #selector(onStyleButtonClick), for: .touchUpInside)
        
        beautyButton.setVerticalButton(UIImage.init(named: "btn_skin care_n")!, "美颜关", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        beautyButton.setVerticalButton(UIImage.init(named: "btn_skin care_p")!, "美颜开", UIFont.systemFont(ofSize: 14), UIColor.white, .selected, 5)
        beautyButton.addTarget(self, action: #selector(onBeautyButtonClick(_:)), for: .touchUpInside)
        
        musicButton.setVerticalButton(UIImage.init(named: "btn_music_n")!, "音乐", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        musicButton.setVerticalButton(UIImage.init(named: "btn_music_p")!, "音乐", UIFont.systemFont(ofSize: 14), UIColor.white, .selected, 5)
        musicButton.addTarget(self, action: #selector(onMusicButtonClick(_:)), for: .touchUpInside)
        
        speedRadioButton.setSelectedText("标准")

        progressBG.image = UIImage.init(named: "pic_the progress bar")
        
        recordButton.setImage(UIImage.init(named: "btn_luzhi_n"), for: .normal)
        recordButton.setImage(UIImage.init(named: "btn_suspended_n"), for: .selected)
        recordButton.addTarget(self, action: #selector(onRecordButtonClick(_:)), for: .touchUpInside)
        recordButton.addObserver(self, forKeyPath: "selected", options: .new, context: nil)
        
        removeVideoItemButton.setImage(UIImage.init(named: "btn_delete_n"), for: .normal)
        removeVideoItemButton.setImage(UIImage.init(named: "btn_delete_p"), for: .highlighted)
        removeVideoItemButton.addTarget(self, action: #selector(onRemoveVideoItemButtonClick(_:)), for: .touchUpInside)
        
        stylePanel.setStyles(sytleData())
        stylePanel.delegate = self
        stylePanel.addObserver(self, forKeyPath: "hidden", options: .new, context: nil)
        
        beautyPanel.delegate = self
        beautyPanel.addObserver(self, forKeyPath: "hidden", options: .new, context: nil)
        
        switchCameraButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.top);
            make.centerX.equalTo(self.snp.centerX);
            make.width.equalTo(44);
            make.height.equalTo(44);
        }
        
        containerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.top);
            make.right.equalTo(self.snp.right);
            make.bottom.equalTo(musicButton.snp.bottom);
            make.width.equalTo(80);
        }
        
        nextButton.snp.makeConstraints { (make) in
            make.top.equalTo(self.snp.top);
            make.right.equalTo(self.snp.right).offset(-15);
            make.height.equalTo(44);
        }
        
        styleButton.snp.makeConstraints { (make) in
            make.top.equalTo(nextButton.snp.bottom).offset(48);
            make.right.equalTo(self.snp.right).offset(-10);
            make.width.equalTo(44);
            make.height.equalTo(60);
        }
        
        beautyButton.snp.makeConstraints { (make) in
            make.top.equalTo(styleButton.snp.bottom).offset(25);
            make.right.equalTo(self.snp.right).offset(-10);
            make.width.equalTo(44);
            make.height.equalTo(60);
        }
        
        musicButton.snp.makeConstraints { (make) in
            make.top.equalTo(beautyButton.snp.bottom).offset(25);
            make.right.equalTo(self.snp.right).offset(-10);
            make.width.equalTo(44);
            make.height.equalTo(60);
        }
        
        speedRadioButton.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(75);
            make.right.equalTo(self.snp.right).offset(-75);
            make.centerX.equalTo(self.snp.centerX);
            make.bottom.equalTo(self.progressView.snp.top).offset(-35);
            make.height.equalTo(30);
        }
        
        recordButtonLeftLayout.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left);
            make.right.equalTo(self.recordButton.snp.left);
            make.top.equalTo(self.recordButton.snp.top);
            make.bottom.equalTo(self.recordButton.snp.bottom);
        }
        
        progressBG.snp.makeConstraints { (make) in
            make.left.equalTo(self.progressView.snp.left);
            make.right.equalTo(self.progressView.snp.right);
            make.centerY.equalTo(self.progressView.snp.centerY);
            make.height.equalTo(3);
        }
        
        progressView.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left);
            make.bottom.equalTo(self.recordButton.snp.top).offset(-30);
            make.right.equalTo(self.snp.right);
            make.height.equalTo(10);
        }
        
        recordButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX);
            make.width.equalTo(60);
            make.height.equalTo(60);
            make.bottom.equalTo(self.snp.bottom).offset(-20);
        }
        
        recordButtonRightLayout.snp.makeConstraints { (make) in
            make.left.equalTo(self.recordButton.snp.right);
            make.right.equalTo(self.snp.right);
            make.top.equalTo(self.recordButton.snp.top);
            make.bottom.equalTo(self.recordButton.snp.bottom);
        }
        
        removeVideoItemButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(recordButtonRightLayout.snp.centerX);
            make.centerY.equalTo(recordButtonRightLayout.snp.centerY);
            make.width.equalTo(80);
            make.height.equalTo(50);
        }
    
        stylePanel.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        beautyPanel.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }
    
    @objc func onSwitchCameraButtonClick(_ button:UIButton) {
        delegate?.switchCamera()
    }
    
    @objc func onNextButtonClick(_ button:UIButton) {
        delegate?.next()
    }
    
    @objc func onBeautyButtonClick(_ button:UIButton) {
        beautyPanel.hideUseAnim(false)
    }
    
    @objc func onMusicButtonClick(_ button:UIButton) {
        delegate?.music()
    }
    
    @objc func onStyleButtonClick(_ button:UIButton) {
        stylePanel.hideUseAnim(false)
    }
    
    @objc func onRecordButtonClick(_ button:UIButton) {
        if !button.isSelected {
            delegate?.startRecord()
        } else {
            delegate?.stopRecord()
        }
        
        button.isSelected = !button.isSelected

    }
    
    @objc func onRemoveVideoItemButtonClick(_ button:UIButton) {
        delegate?.delete()
    }
    
    // MARK: MVYStylePanelDelegate
    func styleSelected(_ styleModel: MVYStyleModel) {
        delegate?.style(styleModel)
    }
    
    // MARK: MVYBeautyPanelDelegate
    func beautyValueChange(_ value: Float) {
        self.delegate?.beautyValueChange(value)
    }
    
    func brightnessValueChange(_ value: Float) {
        delegate?.brightnessValueChange(value)
    }
    
    func saturationValueChange(_ value: Float) {
        delegate?.saturationValueChange(value)
    }
    
    // MARK:Observer
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let _ = object as? MVYStylePanel { // 滤镜板
            let hidden = change?[NSKeyValueChangeKey.newKey] as! Bool
            for view in self.subviews {
                if view.tag == contentTag || view.tag == recordTag {
                    view.isHidden = !hidden
                }
            }
        }else if let _ = object as? MVYBeautyPanel { // 美颜板
            let hidden = change?[NSKeyValueChangeKey.newKey] as! Bool
            for view in self.subviews {
                if view.tag == contentTag || view.tag == recordTag {
                    view.isHidden = !hidden
                }
            }
        }else if let button = object as? UIButton { // 录制按钮
            if button == recordButton {
                let selected = change?[NSKeyValueChangeKey.newKey] as! Bool
                for view in self.subviews {
                    if view.tag == contentTag {
                        view.isHidden = selected
                    }
                }
            }
        }
    }
    
    // MARK: API
    func clickRecordButton() {
        self.onRecordButtonClick(self.recordButton)
    }
    
    func deselectBeautyButton() {
        beautyButton.isSelected = false
    }
    
    // MARK: style data
    private func sytleData()->Array<MVYStyleModel> {
        var array = Array<MVYStyleModel>()
        
        let styleRootPath = "\(Bundle.main.bundlePath)/FilterResources/filter"
        let iconRootPath = "\(Bundle.main.bundlePath)/FilterResources/icon"
        
        let fileList = try! FileManager.default.contentsOfDirectory(atPath: styleRootPath)
        
        for fileName in fileList {
            let path = "\(styleRootPath)/\(fileName)"
            
            if !FileManager.default.fileExists(atPath: path) {
                continue
            }
            
            let name = (fileName as NSString).substring(to: fileName.count - 4)
            
            let model = MVYStyleModel()
            model.thumbnail = "\(iconRootPath)/\(name).png"
            model.text = (name as NSString).substring(from: 2)
            model.path = path
            
            array.append(model)
        }
        
        return array
    }
    
    deinit {
        stylePanel.removeObserver(self, forKeyPath: "hidden")
        beautyPanel.removeObserver(self, forKeyPath: "hidden")
        recordButton.removeObserver(self, forKeyPath: "selected")
    }
}
