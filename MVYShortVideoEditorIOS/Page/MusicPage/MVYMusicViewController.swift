//
//  MVYMusicViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/7.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYMusicViewController: UIViewController {
    
    let musicView = MVYMusicView()
    
    var musicDataArr = [MVYMusicModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        view.backgroundColor = UIColor.white
        view.addSubview(musicView)
        
        musicView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
        initData()
    }
    
    func initData() {
        var model = MVYMusicModel()
        model.musicName = "无"
        musicDataArr.append(model)
        
        model = MVYMusicModel()
        model.musicName = "AlanWalker-TheSpectre"
        model.musicPath = Bundle.main.path(forResource: model.musicName, ofType: "m4a")!
        model.musicDuration = Int(CMTimeGetSeconds(AVAsset.init(url: URL.init(fileURLWithPath: model.musicPath!)).duration))
        musicDataArr.append(model)
        
        model = MVYMusicModel()
        model.musicName = "AlanWalker-Alone"
        model.musicPath = Bundle.main.path(forResource: model.musicName, ofType: "m4a")!
        model.musicDuration = Int(CMTimeGetSeconds(AVAsset.init(url: URL.init(fileURLWithPath: model.musicPath!)).duration))
        musicDataArr.append(model)
        
        musicView.setMsuciDataArr(musicDataArr)
    }
}
