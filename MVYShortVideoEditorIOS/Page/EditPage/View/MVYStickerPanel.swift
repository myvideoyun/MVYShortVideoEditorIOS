//
//  MVYStickerPanel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/19.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYStickerPanelDelegate {
    func stickerPanelOnComplete()
}

class MVYStickerPanel: UIView {
    
    let stickerView1 = MVYStickerView.init(frame: CGRect.zero)
    let stickerView2 = MVYStickerView.init(frame: CGRect.zero)

    let okBt = UIButton()
    let descriptionLb = UILabel()
    let sticker1IconIv = UIImageView()
    let sticker1Switch = UISwitch()
    let sticker1RangSlider = RangeSeekSlider()
    let sticker2IconIv = UIImageView()
    let sticker2Switch = UISwitch()
    let sticker2RangSlider = RangeSeekSlider()
    
    var delegate:MVYStickerPanelDelegate? = nil

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    func setupView() {
        
        stickerView1.isHidden = true
        stickerView1.image = UIImage.init(named: "slack_logo")
        
        stickerView2.isHidden = true
        stickerView2.image = UIImage.init(named: "tripadvisor_logo")

        descriptionLb.text = "左右拖动调节贴纸起始或结束时间"
        descriptionLb.textColor = UIColor.white
        descriptionLb.font = UIFont.systemFont(ofSize: 14)
        
        okBt.setImage(UIImage.init(named: "btn_ok_n"), for: .normal)
        okBt.setImage(UIImage.init(named: "btn_ok_p"), for: .highlighted)
        okBt.addTarget(self, action: #selector(onOKBtClick(_:)), for: .touchUpInside)
        
        sticker1IconIv.image = UIImage.init(named: "slack_logo")
        
        sticker1Switch.isOn = false
        sticker1Switch.addTarget(self, action: #selector(onStickerSwithChange(_ :)), for: .valueChanged)
        
        sticker1RangSlider.hideLabels = true
        sticker1RangSlider.lineHeight = 2
        sticker1RangSlider.initialColor = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        sticker1RangSlider.tintColor = UIColor.init(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1)
        sticker1RangSlider.handleColor = UIColor.white
        sticker1RangSlider.colorBetweenHandles = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        sticker1RangSlider.selectedHandleDiameterMultiplier = 1
        sticker1RangSlider.handleDiameter = 26
        sticker1RangSlider.selectedMinValue = 0
        sticker1RangSlider.selectedMaxValue = 50
        
        sticker2IconIv.image = UIImage.init(named: "tripadvisor_logo")

        sticker2Switch.isOn = false
        sticker2Switch.addTarget(self, action: #selector(onStickerSwithChange(_ :)), for: .valueChanged)

        sticker2RangSlider.hideLabels = true
        sticker2RangSlider.lineHeight = 2
        sticker2RangSlider.initialColor = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        sticker2RangSlider.tintColor = UIColor.init(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1)
        sticker2RangSlider.handleColor = UIColor.white
        sticker2RangSlider.colorBetweenHandles = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        sticker2RangSlider.selectedHandleDiameterMultiplier = 1
        sticker2RangSlider.handleDiameter = 26
        sticker2RangSlider.selectedMinValue = 50
        sticker2RangSlider.selectedMaxValue = 100
        
        addSubview(stickerView1)
        addSubview(stickerView2)
        addSubview(okBt)
        addSubview(descriptionLb)
        addSubview(sticker1IconIv)
        addSubview(sticker1Switch)
        addSubview(sticker1RangSlider)
        addSubview(sticker2IconIv)
        addSubview(sticker2Switch)
        addSubview(sticker2RangSlider)
        
        stickerView1.snp.makeConstraints { (make) in
            make.width.height.equalTo(50)
            make.center.equalToSuperview()
        }
        
        stickerView2.snp.makeConstraints { (make) in
            make.width.height.equalTo(50)
            make.center.equalToSuperview()
        }
        
        sticker2IconIv.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.bottom.equalToSuperview().offset(-15)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }

        sticker2Switch.snp.makeConstraints { (make) in
            make.left.equalTo(sticker2IconIv.snp.right).offset(9)
            make.centerY.equalTo(sticker2IconIv)
        }
        
        sticker2RangSlider.snp.makeConstraints { (make) in
            make.left.equalTo(sticker2Switch.snp.right).offset(9)
            make.right.equalToSuperview().offset(-15)
            make.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
        
        sticker1IconIv.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.bottom.equalTo(sticker2IconIv.snp.top).offset(-30)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        
        sticker1Switch.snp.makeConstraints { (make) in
            make.left.equalTo(sticker1IconIv.snp.right).offset(9)
            make.centerY.equalTo(sticker1IconIv)
        }
        
        sticker1RangSlider.snp.makeConstraints { (make) in
            make.left.equalTo(sticker1Switch.snp.right).offset(9)
            make.right.equalToSuperview().offset(-15)
            make.height.equalTo(60)
            make.centerY.equalTo(sticker1IconIv)
        }
        
        descriptionLb.snp.makeConstraints { (make) in
            make.bottom.equalTo(sticker1IconIv.snp.top).offset(-20)
            make.centerX.equalToSuperview()
        }
        
        okBt.snp.makeConstraints { (make) in
            make.left.equalTo(descriptionLb.snp.right).offset(22)
            make.centerY.equalTo(descriptionLb.snp.centerY)
            make.width.height.equalTo(32)
        }
    }
    
    @objc func onOKBtClick(_ button: UIButton) {
        delegate?.stickerPanelOnComplete()
    }

    @objc func onStickerSwithChange(_ swith: UISwitch) {
        if swith == self.sticker1Switch {
            stickerView1.isHidden = !swith.isOn
        } else if swith == self.sticker2Switch {
            stickerView2.isHidden = !swith.isOn
        }
    }
    
}
