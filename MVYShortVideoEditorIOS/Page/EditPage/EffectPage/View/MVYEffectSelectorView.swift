//
//  MVYEffectSelectorView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/23.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

protocol MVYEffectSelectorViewDelegate: class {
    
    // 按住特效选择按钮
    func touchDownModel(model: MVYEffectCellModel)
    
    // 抬起特效选择按钮
    func touchUp(model: MVYEffectCellModel)
}

class MVYEffectSelectorView: UIView {

    weak var delegate:MVYEffectSelectorViewDelegate? = nil

    let scrollView = UIScrollView()
    let containerView = UIView()
    
    // 数据
    private var effectCellModels = [MVYEffectCellModel]()
    
    convenience init(effectCellModels: [MVYEffectCellModel]) {
        self.init()
        
        setupView()
        update(effectCellModels: effectCellModels)
    }
    
    private func setupView() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        addSubview(scrollView)
        
        scrollView.addSubview(containerView)
        
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
    }
    
    func update(effectCellModels: [MVYEffectCellModel]) {
        self.effectCellModels = effectCellModels
        
        containerView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(self.scrollView)
            make.width.equalTo(72 * effectCellModels.count)
            make.height.equalTo(scrollView.snp.height)
        }
        
        var bt:UIButton? = nil
        
        for x in 0..<effectCellModels.count {
        
            let model = effectCellModels[x]
            
            // 加入特效编辑按钮
            let button = UIButton.init()
            button.setVerticalButton(UIImage(contentsOfFile: model.thumbnail)!, model.text, UIFont.systemFont(ofSize: 14), model.effectColor, .normal, 2)
            button.setVerticalButton(UIImage(contentsOfFile: model.selectedThumbnail)!, model.text, UIFont.systemFont(ofSize: 14), model.effectColor, .highlighted, 2)
            button.setVerticalButton(UIImage(contentsOfFile: model.selectedThumbnail)!, model.text, UIFont.systemFont(ofSize: 14), model.effectColor, .selected, 2)

            button.contentMode = .scaleAspectFill
            button.tag = x
            button.addTarget(self, action: #selector(touchDown(_ :)), for: .touchDown)
            button.addTarget(self, action: #selector(touchUp(_ :)), for: .touchUpInside)
            button.addTarget(self, action: #selector(touchUp(_ :)), for: .touchUpOutside)
            button.addTarget(self, action: #selector(touchUp(_ :)), for: .touchCancel)
            
            containerView.addSubview(button)

            button.snp.makeConstraints { (make) in
                make.height.equalTo(containerView.snp.height)
                make.width.equalTo(72)
                make.top.equalTo(containerView.snp.top)

                if x == 0 {
                    make.left.equalTo(containerView.snp.left)
                } else {
                    make.left.equalTo(bt!.snp.right)
                }

                if x == effectCellModels.count - 1 {
                    make.right.equalTo(scrollView.snp.right)
                }
            }

            bt = button
        }
    }
        
    @objc func touchDown(_ button: UIButton) {
        
        let model = effectCellModels[button.tag]
        
        delegate?.touchDownModel(model: model)
        
        for view in containerView.subviews {
            let view = view as! UIButton
            if button === view {
                view.isEnabled = true
                view.isSelected = true
            } else {
                view.isEnabled = false
                view.isSelected = false
            }
        }
    }
    
    @objc func touchUp(_ button: UIButton) {
        
        let model = effectCellModels[button.tag]

        delegate?.touchUp(model: model)
        
        for view in containerView.subviews {
            let view = view as! UIButton
            view.isEnabled = true
        }
    }
}
