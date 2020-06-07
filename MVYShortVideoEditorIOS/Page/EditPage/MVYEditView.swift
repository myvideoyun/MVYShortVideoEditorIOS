//
//  MVYEditView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/24.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYEditViewDelegate : class {
    func onNextBtClick()
    func onOriginAudioBtClick(isOpen:Bool)
    func onPushMusicPage()
    func onShowCutAudioPanel()
    func onCutAudioPanelValueChange(currentTime:Double)
    func onShowVolumePanel()
    func onVolumePanelValueChange(originAudioVolume: Float, musicVolume: Float)
    func onShowStickerPanel()
    func onStickerPanelValueChange(stickerModels: Array<MVYImageStickerModel>)
    func onShowCoverPage()
    func onShowEffectPage()
}

class MVYEditView: UIView, MVYCutAudioPanelDelegate, MVYVolumeEditPanelDelegate, MVYStickerPanelDelegate {

    let cutAudioPanel = MVYCutAudioPanel()
    let volumeEditPanel = MVYVolumeEditPanel()
    let stickerPanel = MVYStickerPanel()
    let subtitlePanel = MVYSubtitlePanel()
    
    let containerView = UIView()
    
    let nextBt = UIButton()
    let originalAudioBt = UIButton()
    let musicBt = UIButton()
    let cutMusicBt = UIButton()
    let volumeBt = UIButton()
    let effectBt = UIButton()
    let stickerBt = UIButton()
    let subtitleBt = UIButton()
    let selectCoverBt = UIButton()
    
    weak var delegate:MVYEditViewDelegate? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        
        cutAudioPanel.delegate = self
        cutAudioPanel.isHidden = true
        
        volumeEditPanel.delegate = self
        volumeEditPanel.isHidden = true
        
        stickerPanel.delegate = self
        stickerPanel.isHidden = true
        
        subtitlePanel.delegate = self
        subtitlePanel.isHidden = true
        
        nextBt.setTitle("下一步", for: .normal)
        nextBt.addTarget(self, action: #selector(onNextBtClick), for: .touchUpInside)

        originalAudioBt.setVerticalButton(UIImage.init(named: "btn_origin_sound_n")!, "原声开", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        originalAudioBt.setVerticalButton(UIImage.init(named: "btn_origin_sound_p")!, "原声关", UIFont.systemFont(ofSize: 14), UIColor.white, .selected, 5)
        originalAudioBt.addTarget(self, action: #selector(onOriginalAudioBtClick), for: .touchUpInside)
        
        musicBt.setVerticalButton(UIImage.init(named: "btn_music_n")!, "音乐", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        musicBt.setVerticalButton(UIImage.init(named: "btn_music_p")!, "音乐", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        musicBt.addTarget(self, action: #selector(onMusicBtClick), for: .touchUpInside)

        cutMusicBt.setVerticalButton(UIImage.init(named: "btn_clip_n")!, "剪音乐", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        cutMusicBt.setVerticalButton(UIImage.init(named: "btn_clip_p")!, "剪音乐", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        cutMusicBt.addTarget(self, action: #selector(onCutAudioBtClick), for: .touchUpInside)
        
        volumeBt.setVerticalButton(UIImage.init(named: "btn_volume_n")!, "音量", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        volumeBt.setVerticalButton(UIImage.init(named: "btn_volume_p")!, "音量", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        volumeBt.addTarget(self, action: #selector(onVolumeBtClick), for: .touchUpInside)
        
        effectBt.setVerticalButton(UIImage.init(named: "btn_effect_n")!, "特效", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        effectBt.setVerticalButton(UIImage.init(named: "btn_effect_p")!, "特效", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        effectBt.addTarget(self, action: #selector(onEffectBtClick), for: .touchUpInside)
        
        stickerBt.setVerticalButton(UIImage.init(named: "btn_effect_n")!, "贴纸", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        stickerBt.setVerticalButton(UIImage.init(named: "btn_effect_p")!, "贴纸", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        stickerBt.addTarget(self, action: #selector(onStickerBtClick), for: .touchUpInside)
        
        subtitleBt.setVerticalButton(UIImage.init(named: "btn_effect_n")!, "字幕", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        subtitleBt.setVerticalButton(UIImage.init(named: "btn_effect_p")!, "字幕", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        subtitleBt.addTarget(self, action: #selector(onSubtitleBtClick), for: .touchUpInside)
        
        selectCoverBt.setVerticalButton(UIImage.init(named: "btn_effect_n")!, "封面", UIFont.systemFont(ofSize: 14), UIColor.white, .normal, 5)
        selectCoverBt.setVerticalButton(UIImage.init(named: "btn_effect_p")!, "封面", UIFont.systemFont(ofSize: 14), UIColor.white, .highlighted, 5)
        selectCoverBt.addTarget(self, action: #selector(onSelectCoverBtClick), for: .touchUpInside)
        
        containerView.addSubview(nextBt)
        containerView.addSubview(originalAudioBt)
        containerView.addSubview(musicBt)
        containerView.addSubview(cutMusicBt)
        containerView.addSubview(volumeBt)
        containerView.addSubview(effectBt)
        containerView.addSubview(stickerBt)
        containerView.addSubview(subtitleBt)
        containerView.addSubview(selectCoverBt)
        addSubview(containerView)
        addSubview(cutAudioPanel)
        addSubview(volumeEditPanel)
        addSubview(stickerPanel)
        addSubview(subtitlePanel)
        
        containerView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(80)
        }
        
        nextBt.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(50)
        }
        
        originalAudioBt.snp.makeConstraints { (make) in
            make.top.equalTo(nextBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        musicBt.snp.makeConstraints { (make) in
            make.top.equalTo(originalAudioBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        cutMusicBt.snp.makeConstraints { (make) in
            make.top.equalTo(musicBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        volumeBt.snp.makeConstraints { (make) in
            make.top.equalTo(cutMusicBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        effectBt.snp.makeConstraints { (make) in
            make.top.equalTo(volumeBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        stickerBt.snp.makeConstraints { (make) in
            make.top.equalTo(effectBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        subtitleBt.snp.makeConstraints { (make) in
            make.top.equalTo(stickerBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        selectCoverBt.snp.makeConstraints { (make) in
            make.top.equalTo(subtitleBt.snp.bottom).offset(5)
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        cutAudioPanel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
            make.height.equalTo(200)
        }
        
        volumeEditPanel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.bottom.equalToSuperview()
            make.height.equalTo(200)
        }
        
        stickerPanel.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        subtitlePanel.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }

    @objc func onNextBtClick() {
        delegate?.onNextBtClick()
    }
    
    @objc func onOriginalAudioBtClick() {
        originalAudioBt.isSelected = !originalAudioBt.isSelected

        delegate?.onOriginAudioBtClick(isOpen: !originalAudioBt.isSelected)
    }
    
    @objc func onMusicBtClick() {
        delegate?.onPushMusicPage()
    }
    
    @objc func onCutAudioBtClick() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let _ = appDelegate.musicPath {
            containerView.isHidden = true
            cutAudioPanel.isHidden = false
            volumeEditPanel.isHidden = true
            stickerPanel.isHidden = true
            subtitlePanel.isHidden = true
            delegate?.onShowCutAudioPanel()
        }
    }
    
    @objc func onVolumeBtClick() {
        containerView.isHidden = true
        cutAudioPanel.isHidden = true
        volumeEditPanel.isHidden = false
        stickerPanel.isHidden = true
        subtitlePanel.isHidden = true
        delegate?.onShowVolumePanel()
    }
    
    @objc func onEffectBtClick() {
        delegate?.onShowEffectPage()
    }
    
    @objc func onStickerBtClick() {
        containerView.isHidden = true
        cutAudioPanel.isHidden = true
        volumeEditPanel.isHidden = true
        stickerPanel.isHidden = false
        subtitlePanel.isHidden = true
        delegate?.onShowStickerPanel()
    }
    
    @objc func onSubtitleBtClick() {
        containerView.isHidden = true
        cutAudioPanel.isHidden = true
        volumeEditPanel.isHidden = true
        stickerPanel.isHidden = true
        subtitlePanel.isHidden = false
        delegate?.onShowStickerPanel()
    }
    
    @objc func onSelectCoverBtClick() {
        delegate?.onShowCoverPage()
    }
    
    // MARK: - MVYCutAudioPanelDelegate
    func cutAudioPanelTouchFinish(_ currentTime: Double) {
        delegate?.onCutAudioPanelValueChange(currentTime: currentTime)
    }
    
    func cutAudioPanelOnComplete() {
        containerView.isHidden = false
        cutAudioPanel.isHidden = true
    }
    
    // MARK: - MVYVolumeEditPanelDelegate
    func volumeEditPanelOnValueChange(originAudioVolume: Float, musicVolume: Float) {
        if originAudioVolume == 0 {
            originalAudioBt.isSelected = true
        } else {
            originalAudioBt.isSelected = false
        }
        
        delegate?.onVolumePanelValueChange(originAudioVolume: originAudioVolume, musicVolume: musicVolume)
    }
    
    func volumeEditPanelOnComplete() {
        containerView.isHidden = false
        volumeEditPanel.isHidden = true
    }
    
    // MARK: - MVYStickerPanelDelegate
    func stickerPanelOnComplete() {
        containerView.isHidden = false
        stickerPanel.isHidden = true
        subtitlePanel.isHidden = true
        
        var stickerModels = [MVYImageStickerModel]()
        
        if stickerPanel.sticker1Switch.isOn {
            let stickerModel = MVYImageStickerModel()
            stickerModel.image = stickerPanel.stickerView1.image!
            
            let window = UIApplication.shared.delegate?.window!
            stickerModel.bound = stickerPanel.stickerView1.convert(stickerPanel.stickerView1.bounds, to: window)
            
            stickerModel.start = stickerPanel.sticker1RangSlider.selectedMinValue / 100
            
            stickerModel.end = stickerPanel.sticker1RangSlider.selectedMaxValue / 100
            
            stickerModels.append(stickerModel)
            
        }
        
        if stickerPanel.sticker2Switch.isOn {
            let stickerModel = MVYImageStickerModel()
            stickerModel.image = stickerPanel.stickerView2.image!
            
            let window = UIApplication.shared.delegate?.window!
            stickerModel.bound = stickerPanel.stickerView2.convert(stickerPanel.stickerView2.bounds, to: window)
            
            stickerModel.start = stickerPanel.sticker2RangSlider.selectedMinValue / 100
            
            stickerModel.end = stickerPanel.sticker2RangSlider.selectedMaxValue / 100
            
            stickerModels.append(stickerModel)

        }
        
        if subtitlePanel.sticker1Switch.isOn {
            let stickerModel = MVYImageStickerModel()
            stickerModel.image = subtitlePanel.stickerView1.image!
            
            let window = UIApplication.shared.delegate?.window!
            stickerModel.bound = subtitlePanel.stickerView1.convert(subtitlePanel.stickerView1.bounds, to: window)
            
            stickerModel.start = subtitlePanel.sticker1RangSlider.selectedMinValue / 100
            
            stickerModel.end = subtitlePanel.sticker1RangSlider.selectedMaxValue / 100
            
            stickerModels.append(stickerModel)
            
        }
        
        if subtitlePanel.sticker2Switch.isOn {
            let stickerModel = MVYImageStickerModel()
            stickerModel.image = subtitlePanel.stickerView2.image!
            
            let window = UIApplication.shared.delegate?.window!
            stickerModel.bound = subtitlePanel.stickerView2.convert(subtitlePanel.stickerView2.bounds, to: window)
            
            stickerModel.start = subtitlePanel.sticker2RangSlider.selectedMinValue / 100
            
            stickerModel.end = subtitlePanel.sticker2RangSlider.selectedMaxValue / 100
            
            stickerModels.append(stickerModel)
            
        }
        
        delegate?.onStickerPanelValueChange(stickerModels: stickerModels)
    }
}
