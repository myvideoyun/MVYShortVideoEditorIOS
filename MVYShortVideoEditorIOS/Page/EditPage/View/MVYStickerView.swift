//
//  MVYStickerView.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/19.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYStickerView: UIImageView {

    public private(set) var rotation: CGFloat = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(image: UIImage?) {
        super.init(image: image)
        
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    private func setupView() {
        isUserInteractionEnabled = true
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        addGestureRecognizer(panGestureRecognizer)

        layer.borderWidth = 2
        layer.borderColor = UIColor.red.cgColor
    }
    
    @objc
    func panGesture(_ sender: UIPanGestureRecognizer) {
        let move = sender.translation(in: self)
        transform = transform.translatedBy(x: move.x, y: move.y)
        sender.setTranslation(CGPoint.zero, in: self)
    }
}
