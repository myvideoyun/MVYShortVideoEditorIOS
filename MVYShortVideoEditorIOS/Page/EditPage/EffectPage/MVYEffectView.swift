//
//  MVYEffectView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/23.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYEffectViewDelegate: class {
    
    // 撤销
    func undo()
    
    // 划动进度条
    func seekTo(time: Double)
    
    // 慢放设置
    func slowPlay(startTime: Double, duration: Double)
    
    // 按住特效选择按钮
    func touchDown(model: MVYEffectCellModel)
    
    // 抬起特效选择按钮
    func touchUp(model: MVYEffectCellModel)
}

class MVYEffectView: UIView {
    
    weak var delegate: MVYEffectViewDelegate? = nil

    let lineView = UIView()
    let lineView2 = UIView()
    let undoLayout = UIView()
    let undoDescriptionLabel = UILabel()
    let undoBt = UIButton()
    var effectProgressView:MVYEffectProgressView? = nil
    var videoEffectSelectorView:MVYEffectSelectorView? = nil
    var timeEffectSelectorView:MVYEffectSelectorView? = nil
    var slowPlayProgressView:MVYSlowPlayProgressView? = nil
    let videoEffectBt = UIButton()
    let timeEffectBt = UIButton()
    
    convenience init(duration: Double, slowPlayIncreasedTime: Double, videoEffectCellModel: [MVYEffectCellModel], timeEffectCellModel: [MVYEffectCellModel]) {
        self.init()
        
        self.effectProgressView = MVYEffectProgressView.init(duration: duration)
        self.effectProgressView?.delegate = self
        
        self.slowPlayProgressView = MVYSlowPlayProgressView.init(duration: duration, slowPlayDuration: slowPlayIncreasedTime)
        self.slowPlayProgressView?.delegate = self
        self.slowPlayProgressView?.isHidden = true
        
        self.videoEffectSelectorView = MVYEffectSelectorView.init(effectCellModels: videoEffectCellModel)
        self.videoEffectSelectorView?.delegate = self
        
        self.timeEffectSelectorView = MVYEffectSelectorView.init(effectCellModels: timeEffectCellModel)
        self.timeEffectSelectorView?.delegate = self
        self.timeEffectSelectorView?.isHidden = true
        
        setupView()
    }
    
    private func setupView() {
                
        lineView.backgroundColor = UIColor.init(red: 153/255.0, green:153/255.0, blue:153/255.0, alpha:1/1.0)
        lineView2.backgroundColor = UIColor.init(red: 153/255.0, green:153/255.0, blue:153/255.0, alpha:1/1.0)

        undoDescriptionLabel.text = "选择位置后, 按住使用效果"
        undoDescriptionLabel.textColor = UIColor.black
        undoDescriptionLabel.font = UIFont.systemFont(ofSize: 12)
        
        undoBt.setHorizontalButton(UIImage.init(named: "btn_back_n")!, "撤销", UIFont.systemFont(ofSize: 12), UIColor.black, .normal, 4)
        undoBt.addTarget(self, action: #selector(undoBtClick(_ :)), for: .touchUpInside)
        
        effectProgressView!.backgroundColor = UIColor.clear
        slowPlayProgressView!.backgroundColor = UIColor.clear

        videoEffectBt.setTitle("视频特效", for: .normal)
        videoEffectBt.setTitleColor(UIColor.gray, for: .normal)
        videoEffectBt.setTitleColor(UIColor.blue, for: .selected)
        videoEffectBt.addTarget(self, action: #selector(onVideoEffectBtClick(_ :)), for: .touchUpInside)
        videoEffectBt.isSelected = true
        
        timeEffectBt.setTitle("时间特效", for: .normal)
        timeEffectBt.setTitleColor(UIColor.gray, for: .normal)
        timeEffectBt.setTitleColor(UIColor.blue, for: .selected)
        timeEffectBt.addTarget(self, action: #selector(onTimeEffectBtClick(_ :)), for: .touchUpInside)

        addSubview(videoEffectBt)
        addSubview(timeEffectBt)
        addSubview(videoEffectSelectorView!)
        addSubview(timeEffectSelectorView!)
        addSubview(lineView)
        addSubview(undoLayout)
        undoLayout.addSubview(undoDescriptionLabel)
        undoLayout.addSubview(undoBt)
        addSubview(slowPlayProgressView!)
        addSubview(effectProgressView!)

        videoEffectBt.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(44)
            make.right.equalTo(self.snp.centerX)
        }
        
        timeEffectBt.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.centerX)
            make.bottom.equalToSuperview()
            make.height.equalTo(44)
            make.right.equalToSuperview()
        }
        
        videoEffectSelectorView!.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(videoEffectBt.snp.top)
            make.height.equalTo(90)
        }
        
        timeEffectSelectorView!.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(videoEffectBt.snp.top)
            make.height.equalTo(90)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(videoEffectSelectorView!.snp.top)
            make.height.equalTo(1)
        }
        
        undoLayout.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(lineView.snp.top)
            make.height.equalTo(25)
        }
        
        undoDescriptionLabel.snp.makeConstraints { (make) in
            make.left.equalTo(undoLayout.snp.left).offset(15)
            make.centerY.equalTo(undoLayout.snp.centerY)
        }
        
        undoBt.snp.makeConstraints { (make) in
            make.right.equalTo(undoLayout.snp.right).offset(-15)
            make.centerY.equalTo(undoLayout.snp.centerY)
            make.width.equalTo(50)
            make.height.equalTo(undoLayout.snp.height)
        }
        
        slowPlayProgressView!.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.bottom.equalTo(undoLayout.snp.top).offset(0.1)
            make.right.equalTo(self.snp.right).offset(-15)
            make.height.equalTo(0.1)
        }
        
        effectProgressView!.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left).offset(15)
            make.bottom.equalTo(slowPlayProgressView!.snp.top).offset(-15)
            make.right.equalTo(self.snp.right).offset(-15)
            make.height.equalTo(29)
        }
    }
    
    @objc func undoBtClick(_ button: UIButton) {
        delegate?.undo()
    }
    
    // 更新特效时间数据
    func update(effectTimeModels: [MVYEffectTimeModel]) {
        effectProgressView?.update(effectTimeModels: effectTimeModels)
    }
    
    // 更新解码模式
    func update(decoderWorkType: MVYDecoderWorkTypeModel) {
        effectProgressView?.update(decoderWorkType: decoderWorkType)
        
        switch decoderWorkType.type {
        case .normal, .reverse:
            slowPlayProgressView(isHidden: true)
        case .slow:
            slowPlayProgressView(isHidden: false)
            slowPlayProgressView?.update(decoderWorkType: decoderWorkType)
        }
    }
    
    // 更新当前时间进度
    func update(currentTime: Double) {
        effectProgressView?.update(currentTime: currentTime)
    }
    
    // 是否显示慢速播放控件
    private func slowPlayProgressView(isHidden: Bool) {
        if !isHidden {
            slowPlayProgressView!.snp.updateConstraints { (make) in
                make.bottom.equalTo(undoLayout.snp.top).offset(-15)
                make.height.equalTo(29)
            }
        } else {
            slowPlayProgressView!.snp.updateConstraints { (make) in
                make.bottom.equalTo(undoLayout.snp.top).offset(0.1)
                make.height.equalTo(0.1)
            }
        }
        
        slowPlayProgressView!.isHidden = isHidden
    }
    
    // 切换到视频特效控件面板
    @objc func onVideoEffectBtClick(_ button: UIButton) {
        videoEffectBt.isSelected = true
        timeEffectBt.isSelected = false
        
        videoEffectSelectorView?.isHidden = false
        timeEffectSelectorView?.isHidden = true
    }
    
    // 切换到时间特效控件面板
    @objc func onTimeEffectBtClick(_ button: UIButton) {
        videoEffectBt.isSelected = false
        timeEffectBt.isSelected = true
        
        videoEffectSelectorView?.isHidden = true
        timeEffectSelectorView?.isHidden = false
    }
}

extension MVYEffectView: MVYEffectSelectorViewDelegate ,MVYEffectProgressViewDelegate, MVYSlowPlayProgressViewDelegate {
    
    // 按下特效Cell
    func touchDownModel(model: MVYEffectCellModel) {
        delegate?.touchDown(model: model)
        
        undoBt.isHidden = true
    }
    
    // 松开特效Cell
    func touchUp(model: MVYEffectCellModel) {
        delegate?.touchUp(model: model)
        
        undoBt.isHidden = false
    }

    // 滑动播放进度条
    func seekTo(time: Double) {
        delegate?.seekTo(time: time)
    }
    
    // 滑动慢放进度条
    func slowPlay(startTime: Double, duration: Double) {
        delegate?.slowPlay(startTime: startTime, duration: duration)
    }
}
