//
//  MVYEffectTimeModel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/23.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYEffectTimeModel {
    // 视频特效的ID
    var identification = 0
    
    // 特效的颜色
    var effectColor = UIColor.clear
    
    // 特效开始时间
    var startTime:Int64 = 0
    
    // 特效持续时间
    var duration:Int64 = 0
    
    // 当前全局的特效位置
    var effectIndexResult = [MVYEffectTimeIndexModel]()
}
