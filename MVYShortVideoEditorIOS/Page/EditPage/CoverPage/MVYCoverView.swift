//
//  MVYCoverView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYCoverView: UIView {

    let slider = UISlider()
    let completeBt = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        slider.minimumValue = 0
        slider.value = 0
        slider.minimumTrackTintColor = UIColor.init(red: 254/255.0, green: 112/255.0, blue: 68/255.0, alpha: 1)
        slider.maximumTrackTintColor = UIColor.init(red: 153/255.0, green: 153/255.0, blue: 153/255.0, alpha: 1)
        slider.setThumbImage(UIImage.init(named: "btn"), for: .normal)
        
        completeBt.setTitle("保存到相册", for: .normal)
        
        self.addSubview(slider)
        self.addSubview(completeBt)
        
        slider.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(40)
            make.right.equalToSuperview().offset(-40)
            make.bottom.equalToSuperview().offset(-50)
        }
        
        completeBt.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
            make.height.equalTo(50)
        }
    }
}
