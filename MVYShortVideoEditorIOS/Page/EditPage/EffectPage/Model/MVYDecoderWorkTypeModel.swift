//
//  MVYDecoderWorkTypeModel.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/6/10.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

enum MVYDecoderWokType: Int {
    case normal // 正常解码
    case reverse // 倒序解码
    case slow // 慢速解码
    case fast // fast play
}

class MVYDecoderWorkTypeModel {

    // 解码类型
    var type:MVYDecoderWokType = .normal

    // 特效的颜色
    var color = UIColor.gray
    
    // 慢速解码的时间数据
    var slowDecoderRange = NSMakeRange(0, MVYEffectViewController.slowDuration)
    
}
