//
//  MVYStylePanel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import SnapKit
import pop

protocol MVYStylePanelDelegate : class{
    func styleSelected(_ styleModel:MVYStyleModel)
}

class MVYStylePanel: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    weak var delegate:MVYStylePanelDelegate? = nil
    
    private let CELL_ID = "STYLE_CELL"
    
    private let contentView = UIView()
    private let hideViewTrigger = UIButton()
    private let titleLayout = UIView()
    private let titleLb = UILabel()
    private let flowLayout = UICollectionViewFlowLayout()
    private var collectionView:UICollectionView? = nil
    
    private var styles = Array<MVYStyleModel>()
    
    var selectedText:String? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
        isHidden = true
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    private func setupView() {
        
        collectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout:flowLayout)
        
        self.addSubview(contentView)
        contentView.addSubview(hideViewTrigger)
        contentView.addSubview(titleLayout)
        titleLayout.addSubview(titleLb)
        contentView.addSubview(collectionView!)
        
        hideViewTrigger.backgroundColor = UIColor.clear
        hideViewTrigger.addTarget(self, action: #selector(onHideViewTiggerClick(_:)), for: .touchUpInside)
    
        titleLayout.backgroundColor = UIColor.clear
        
        titleLb.text = "滤镜"
        titleLb.textColor = UIColor.white
        titleLb.font = UIFont.systemFont(ofSize: 12)
        
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        collectionView!.showsHorizontalScrollIndicator = false
        collectionView!.alwaysBounceHorizontal = true
        collectionView!.isPagingEnabled = false
        collectionView!.delegate = self
        collectionView!.dataSource = self
        collectionView!.backgroundColor = UIColor.clear
        collectionView!.allowsSelection = true
        collectionView!.register(MVYStylePanelCell.self, forCellWithReuseIdentifier: CELL_ID)
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        hideViewTrigger.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left);
            make.top.equalTo(self.snp.top);
            make.right.equalTo(self.snp.right);
            make.bottom.equalTo(titleLayout.snp.top);
        }
        
        titleLayout.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left);
            make.right.equalTo(self.snp.right);
            make.bottom.equalTo(collectionView!.snp.top);
            make.height.equalTo(25);
        }
        
        titleLb.snp.makeConstraints { (make) in
            make.centerX.equalTo(titleLayout.snp.centerX);
            make.centerY.equalTo(titleLayout.snp.centerY);
        }
        
        collectionView!.snp.makeConstraints { (make) in
            make.left.equalTo(self.snp.left);
            make.bottom.equalTo(self.snp.bottom);
            make.right.equalTo(self.snp.right);
            make.height.equalTo(100);
        }
    }
    
    // MARK: delegate, data source
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize.init(width: collectionView.frame.size.width / 5, height: collectionView.frame.size.height)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.styles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_ID, for: indexPath) as! MVYStylePanelCell
        
        //设置是否被选中
        let styleModel = styles[indexPath.row]
        cell.isSelected = styleModel.text == selectedText
        
        //设置数据
        cell.setThumbnail(UIImage.init(named: styleModel.thumbnail!)!)
        cell.setText(styleModel.text!)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let delegate = self.delegate {
            delegate.styleSelected(styles[indexPath.row])
        }
    }
    
    // MARK: API
    func hideUseAnim(_ hidden:Bool) {
        if !hidden {
            self.isHidden = hidden
        }
        
        let centerAnim = POPSpringAnimation.init(propertyNamed: kPOPViewCenter)
        centerAnim?.springSpeed = 10
        centerAnim?.springBounciness = 6
        
        if hidden {
            centerAnim?.fromValue = NSValue.init(cgPoint: self.center)
            centerAnim?.toValue = NSValue.init(cgPoint: CGPoint.init(x: self.center.x, y: self.center.y + 125 + (centerAnim?.springBounciness)!))
        } else {
            centerAnim?.fromValue = NSValue.init(cgPoint: CGPoint.init(x: self.center.x, y: self.center.y + 125 + (centerAnim?.springBounciness)!))
            centerAnim?.toValue = NSValue.init(cgPoint: self.center)
        }
        
        centerAnim?.completionBlock = { anim, complete in
            if complete && hidden {
                self.isHidden = hidden
            }
        
            if complete && !hidden {
                self.hideViewTrigger.isEnabled = true
            }
        }
        
        hideViewTrigger.isEnabled = false
        contentView.pop_removeAllAnimations()
        contentView.pop_add(centerAnim, forKey: nil)
    }
    
    func setStyles(_ styles: Array<MVYStyleModel>) {
        self.styles = styles
        
        collectionView!.reloadData()
    }
    
    // MARK: button target
    @objc func onHideViewTiggerClick(_ button:UIButton) {
        self.hideUseAnim(true)
    }
}
