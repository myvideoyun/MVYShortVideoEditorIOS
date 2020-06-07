//
//  MVYMusicCellView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYMusicCellViewDelegate : class{
    func musicCellViewOnClick(_ cell:MVYMusicCellView)
}

class MVYMusicCellView: UIView {

    let arrowIv = UIImageView()
    let nameLabel = UILabel()
    let timeLabel = UILabel()
    let button = UIButton()
    
    weak var delegate:MVYMusicCellViewDelegate? = nil
    
    var model:MVYMusicModel? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        button.addTarget(self, action: #selector(onBtnClick), for: .touchUpInside)
    
        arrowIv.image = UIImage.init(named: "icon_selected")
        
        nameLabel.font = UIFont.systemFont(ofSize: 14)
        nameLabel.textColor = UIColor.gray
        
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textColor = UIColor.gray
        
        let lineView = UIView.init()
        lineView.backgroundColor = UIColor.gray
        
        addSubview(arrowIv)
        addSubview(nameLabel)
        addSubview(timeLabel)
        addSubview(lineView)
        addSubview(button)

        arrowIv.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.width.equalTo(14)
            make.height.equalTo(14)
            make.centerY.equalToSuperview()
        }
        
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(arrowIv.snp.right).offset(11)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(220)
        }
        
        timeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.width.equalTo(60)
        }
        
        lineView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
        button.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }
    
    func setModel(_ model:MVYMusicModel) {
        self.model = model
        nameLabel.text = model.musicName
        timeLabel.text = String.init(format: "%02ld:%02ld", model.musicDuration/60, model.musicDuration%60)
    }
    
    @objc func onBtnClick() {
        delegate?.musicCellViewOnClick(self)
    }
    
    func setSelected(_ selected: Bool) {
        if selected {
            arrowIv.isHidden = false
            nameLabel.textColor = UIColor.blue
            timeLabel.textColor = UIColor.blue
            
        } else {
            arrowIv.isHidden = true
            nameLabel.textColor = UIColor.gray
            timeLabel.textColor = UIColor.gray
        }
    }
}
