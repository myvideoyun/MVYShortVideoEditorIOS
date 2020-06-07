//
//  MVYAudioVolumeEditPanel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYVolumeEditPanelDelegate {
    // 手指滑动时监听音量变化
    func volumeEditPanelOnValueChange(originAudioVolume:Float, musicVolume:Float);
    
    // 音量调节完成
    func volumeEditPanelOnComplete();
}

class MVYVolumeEditPanel: UIView {

    var delegate: MVYVolumeEditPanelDelegate? = nil
    
    let okBt = UIButton()
    let descriptionLb = UILabel()
    let originAudioLb = UILabel()
    let originAudioSlider = UISlider()
    let musicLb = UILabel()
    let musicSlider = UISlider()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        
        backgroundColor = UIColor.clear
        
        descriptionLb.text = "左右拖动调节音量大小"
        descriptionLb.textColor = UIColor.white
        descriptionLb.font = UIFont.systemFont(ofSize: 14)
        
        okBt.setImage(UIImage.init(named: "btn_ok_n"), for: .normal)
        okBt.setImage(UIImage.init(named: "btn_ok_p"), for: .highlighted)
        okBt.addTarget(self, action: #selector(onOKBtClick(_:)), for: .touchUpInside)
        
        originAudioLb.text = "视频原声"
        originAudioLb.font = UIFont.systemFont(ofSize: 14)
        originAudioLb.textColor = UIColor.white
        
        originAudioSlider.minimumValue = 0
        originAudioSlider.maximumValue = 1.8
        originAudioSlider.value = 1
        originAudioSlider.minimumTrackTintColor = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        originAudioSlider.maximumTrackTintColor = UIColor.init(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1)
        originAudioSlider.setThumbImage(UIImage.init(named: "btn"), for: .normal)
        originAudioSlider.addTarget(self, action: #selector(onOriginAudioValueChange(_ :)), for: .valueChanged)
        
        musicLb.text = "配乐"
        musicLb.font = UIFont.systemFont(ofSize: 14)
        musicLb.textColor = UIColor.white
        
        musicSlider.minimumValue = 0
        musicSlider.maximumValue = 1.8
        musicSlider.value = 1
        musicSlider.minimumTrackTintColor = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        musicSlider.maximumTrackTintColor = UIColor.init(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1)
        musicSlider.setThumbImage(UIImage.init(named: "btn"), for: .normal)
        musicSlider.addTarget(self, action: #selector(onMusicValueChange(_ :)), for: .valueChanged)
        
        addSubview(descriptionLb)
        addSubview(okBt)
        addSubview(originAudioLb)
        addSubview(originAudioSlider)
        addSubview(musicLb)
        addSubview(musicSlider)
        
        musicLb.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.bottom.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        musicSlider.snp.makeConstraints { (make) in
            make.left.equalTo(musicLb.snp.right).offset(9)
            make.right.equalToSuperview().offset(-15)
            make.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
        
        originAudioLb.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.bottom.equalTo(musicLb.snp.top)
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        originAudioSlider.snp.makeConstraints { (make) in
            make.left.equalTo(originAudioLb.snp.right).offset(9)
            make.right.equalToSuperview().offset(-15)
            make.bottom.equalTo(musicSlider.snp.top)
            make.height.equalTo(60)
        }
        
        descriptionLb.snp.makeConstraints { (make) in
            make.bottom.equalTo(originAudioSlider.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
        
        okBt.snp.makeConstraints { (make) in
            make.left.equalTo(descriptionLb.snp.right).offset(22)
            make.centerY.equalTo(descriptionLb.snp.centerY)
            make.width.height.equalTo(32)
        }
    }
    
    func hideMusicSlider(isHidden:Bool) {
        musicLb.isHidden = isHidden
        musicSlider.isHidden = isHidden
    }
    
    @objc func onOKBtClick(_ button: UIButton) {
        delegate?.volumeEditPanelOnComplete()
    }
    
    @objc func onOriginAudioValueChange(_ slider: UISlider) {
        delegate?.volumeEditPanelOnValueChange(originAudioVolume: originAudioSlider.value, musicVolume: musicSlider.value)
    }
    
    @objc func onMusicValueChange(_ slider: UISlider) {
        delegate?.volumeEditPanelOnValueChange(originAudioVolume: originAudioSlider.value, musicVolume: musicSlider.value)
    }

    func setVolume(_ originAudioVolume:Float, _ musicVolume:Float) {
        originAudioSlider.value = originAudioVolume
        musicSlider.value = musicVolume
    }
}
