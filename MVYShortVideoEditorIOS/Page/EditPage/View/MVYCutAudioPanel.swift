//
//  MVYCutAudioPanel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/15.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYCutAudioPanelDelegate : class {
    // 手指滑动停止时更新时间
    func cutAudioPanelTouchFinish(_ currentTime: Double);
    
    // 更新结束
    func cutAudioPanelOnComplete();
}

class MVYCutAudioPanel: UIView, MVYCutAudioViewDelegate {

    var cutAudioView = MVYCutAudioView()
    let okBt = UIButton()
    let descriptionLb = UILabel()
    let startTimeLb = UILabel()
    let popIv = UIImageView()
    
    private var currentTime:Double = 0

    weak var delegate:MVYCutAudioPanelDelegate? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        
        backgroundColor = UIColor.clear
        
        descriptionLb.text = "左右拖动声谱以剪取音乐"
        descriptionLb.textColor = UIColor.white
        descriptionLb.font = UIFont.systemFont(ofSize: 14)
        
        okBt.setImage(UIImage.init(named: "btn_ok_n"), for: .normal)
        okBt.setImage(UIImage.init(named: "btn_ok_p"), for: .highlighted)
        okBt.addTarget(self, action: #selector(onOKBtClick(_:)), for: .touchUpInside)
        
        cutAudioView.backgroundColor = UIColor.clear
        cutAudioView.delegate = self
        
        popIv.image = UIImage.init(named: "pic_bubbles")?.resizableImage(withCapInsets: UIEdgeInsets.init(top: 3, left: 10, bottom: 9, right: 10))
        
        startTimeLb.textColor = UIColor.white
        startTimeLb.font = UIFont.systemFont(ofSize: 12)
        startTimeLb.text = "当前从00:00开始"
        
        addSubview(descriptionLb)
        addSubview(okBt)
        addSubview(popIv)
        addSubview(startTimeLb)
        addSubview(cutAudioView)
        
        cutAudioView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview().offset(-5)
            make.height.equalTo(100)
        }
        
        popIv.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalTo(cutAudioView.snp.top).offset(-25)
            make.height.equalTo(23)
            make.width.equalTo(startTimeLb.snp.width).offset(10)
        }
        
        startTimeLb.snp.makeConstraints { (make) in
            make.left.equalTo(popIv.snp.left).offset(10)
            make.top.equalTo(popIv.snp.top).offset(3)
            make.bottom.equalTo(popIv.snp.bottom).offset(-9)
        }
        
        descriptionLb.snp.makeConstraints { (make) in
            make.bottom.equalTo(popIv.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
        
        okBt.snp.makeConstraints { (make) in
            make.left.equalTo(descriptionLb.snp.right).offset(22)
            make.centerY.equalTo(descriptionLb.snp.centerY)
            make.width.height.equalTo(32)
        }
    }
    
    func setData(audioURL: URL, startTime: Double, duration: Double) {
        cutAudioView.setData(audioURL: audioURL, startTime: startTime, duration: duration)
    }
    
    @objc func onOKBtClick(_ button: UIButton) {
        delegate?.cutAudioPanelOnComplete()
    }
    
    // MARK: - MVYCutAudioViewDelegate
    func cutAudioOnTouching(_ currentTime: Double) {
        self.currentTime = currentTime
        
        startTimeLb.text = String.init(format: "当前从%02ld:%02ld开始", Int.init(currentTime) / 60, Int.init(currentTime) % 60)
    }
    
    func cutAudioOnTouchEnd() {
        delegate?.cutAudioPanelTouchFinish(self.currentTime)
    }
}
