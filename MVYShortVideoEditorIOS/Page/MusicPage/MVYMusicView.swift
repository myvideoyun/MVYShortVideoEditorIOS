//
//  MVYMusicView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYMusicView: UIView, MVYMusicCellViewDelegate{

    let titleLabel = UILabel()
    let scrollView = UIScrollView()
    let containerView = UIView()
        
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {

        titleLabel.text = "选择音乐"
        titleLabel.textColor = UIColor.black
        titleLabel.font = UIFont.systemFont(ofSize: 18)
        titleLabel.textAlignment = .center
        
        scrollView.showsVerticalScrollIndicator = true
        
        addSubview(titleLabel)
        addSubview(scrollView)
        addSubview(containerView)

        titleLabel.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(44)
        }
        
        scrollView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(15)
            make.top.equalTo(titleLabel.snp.bottom)
            make.right.equalToSuperview().offset(-15)
            make.bottom.equalToSuperview()
        }
        
        containerView.snp.makeConstraints { (make) in
            make.edges.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
    }
    
    func setMsuciDataArr(_ musicDataArr:[MVYMusicModel]) {
        
        for view in containerView.subviews {
            view.removeFromSuperview()
        }
        
        var lastView:UIView? = nil
        var selectedView:MVYMusicCellView? = nil
        
        for x in 0..<musicDataArr.count {
            
            let model = musicDataArr[x]
            
            let cellView = MVYMusicCellView()
            cellView.delegate = self
            cellView.setModel(model)
            
            containerView.addSubview(cellView)
            
            let delegate = UIApplication.shared.delegate as! AppDelegate
            if delegate.musicName == nil && model.musicName == "无"{
                selectedView = cellView
            } else if delegate.musicName == model.musicName {
                selectedView = cellView
            }
            
            cellView.snp.makeConstraints { (make) in
                make.width.equalToSuperview()
                make.height.equalTo(55)
                make.left.equalToSuperview()
                
                if x == 0 {
                    make.top.equalTo(containerView.snp.top)
                } else {
                    make.top.equalTo(lastView!.snp.bottom)
                }
                
                if x == musicDataArr.count - 1 {
                    make.bottom.lessThanOrEqualTo(containerView.snp.bottom)
                }
            }
            
            lastView = cellView
        }
        
        self.musicCellViewOnClick(selectedView!)
    }
    
    func musicCellViewOnClick(_ view: MVYMusicCellView) {
        let subviews = containerView.subviews
        
        for subview in subviews {
            let cellView = subview as! MVYMusicCellView
            cellView.setSelected(view == cellView)
        }
        
        let delegate = UIApplication.shared.delegate as! AppDelegate
        delegate.musicName = view.model?.musicName
        delegate.musicPath = view.model?.musicPath
    }
}
