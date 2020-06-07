//
//  MVYStylePanelCell.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYStylePanelCell: UICollectionViewCell {

    private let imageView = UIImageView()
    private let label = UILabel()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    private func setupView() {
        self.contentView.addSubview(imageView)
        self.contentView.addSubview(label)
        
        imageView.contentMode = .scaleAspectFit
        
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.white
        label.textAlignment = .center
        
        imageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView.snp.left).offset(5)
            make.right.equalTo(self.contentView.snp.right).offset(-5)
            make.top.equalTo(self.contentView.snp.top)
            make.bottom.equalTo(self.label.snp.top)
        }
        
        label.snp.makeConstraints { (make) in
            make.left.equalTo(self.contentView.snp.left)
            make.bottom.equalTo(self.contentView.snp.bottom).offset(-5)
            make.right.equalTo(self.contentView.snp.right)
            make.height.equalTo(25)
        }
    }
    
    func setThumbnail(_ thumbnailImage:UIImage) {
        imageView.image = thumbnailImage
    }
    
    func setText(_ text:String) {
        label.text = text
    }

}
