//
//  MVYEffectCellModel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/23.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYEffectCellModel: NSObject {

    // 缩略图
    var thumbnail = ""
    
    // 选中时候的缩略图
    var selectedThumbnail = ""
    
    // 描述
    var text = ""
    
    // 特效类型
    var effectType:Int = 0
    
    // 视频特效显示在进度条上的颜色
    var effectColor = UIColor.clear
}
