//
//  MVYEffectViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/23.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

// 特效处理
typealias EffectPageEffectProcessBlock = (MVYVideoFrame) -> CVPixelBuffer?

// 普通特效时间数据
typealias EffectPageSetEffectTimeBlock = ([MVYEffectTimeModel]) -> Void

// 解码工作模式, 如果是慢速解码会有时间参数
typealias EffectPageSetDecoderWorkTypeBlock = (MVYDecoderWorkTypeModel)->Void

class MVYEffectViewController: UIViewController {

    // 输入的视频
    var videoPaths = [String]()
    
    // 视频总长度
    var totalDuration:Int64 = 0
    
    // 预览UI
    private let preview = MVYPixelBufferPreview.init()
    
    // 视频播放器
    var videoPlayer:MVYVideoPlayer? = nil
    
    // 视频seeker
    var videoSeeker:MVYVideoSeeker? = nil
    
    // 解码器工作类型
    var decoderWorkType = MVYDecoderWorkTypeModel()
    
    // 慢速解码参数
    static let slowDuration = 500

    // 当前播放器的时间
    var currentTime: Int64 = 0
    
    // UI
    var effectView:MVYEffectView? = nil
    
    // 特效时间数据
    var effectTimeModels = [MVYEffectTimeModel]()
    var currentTimeModel = MVYEffectTimeModel()
    
    // 特效处理的block
    var setEffectTimeBlock :EffectPageSetEffectTimeBlock? = nil
    var effectProcessBlock: EffectPageEffectProcessBlock? = nil
    var setDecoderWorkTypeBlock: EffectPageSetDecoderWorkTypeBlock? = nil
    
    convenience init(videoPaths: Array<String>,
                     effectTimeModels: [MVYEffectTimeModel],
                     decoderWorkType: MVYDecoderWorkTypeModel,
                     effectProcessBlock: @escaping EffectPageEffectProcessBlock,
                     setEffectTimeBlock: @escaping EffectPageSetEffectTimeBlock,
                     setDecoderWorkTypeBlock: @escaping EffectPageSetDecoderWorkTypeBlock) {
        self.init()
        
        self.videoPaths = videoPaths
        self.effectTimeModels = effectTimeModels
        self.setEffectTimeBlock = setEffectTimeBlock
        self.effectProcessBlock = effectProcessBlock
        self.decoderWorkType = decoderWorkType
        self.setDecoderWorkTypeBlock = setDecoderWorkTypeBlock
        
        for videoPath in videoPaths {
            let asset = AVURLAsset.init(url: URL.init(fileURLWithPath: videoPath))
            totalDuration = totalDuration + Int64(asset.duration.seconds * 1000.0)
        }
        
        // 创建视频播放器
        videoPlayer = MVYVideoPlayer.init(paths: videoPaths)
        videoPlayer?.playerDelegate = self
        
        // 创建seek解码器
        videoSeeker = MVYVideoSeeker.init(paths: videoPaths)
        videoSeeker?.seekerDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        
        // 显示第一帧
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            switch self.decoderWorkType.type {
            case .normal, .slow:
                self.videoSeeker?.setSeekTime(0)
            case .reverse:
                self.videoSeeker?.setSeekTime(self.totalDuration)
            }
        }
    }
    
    func setupView() {
        self.view.backgroundColor = UIColor.white
        
        effectView = MVYEffectView.init(duration: Double(totalDuration), slowPlayIncreasedTime: Double(MVYEffectViewController.slowDuration), videoEffectCellModel: MVYEffectViewController.videoEffectCellModels(), timeEffectCellModel: MVYEffectViewController.timeEffectCellModels())
        
        effectView!.delegate = self
        
        self.view.addSubview(preview)
        self.view.addSubview(effectView!)
        
        preview.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom).offset(17)
            make.bottom.equalTo(effectView!.effectProgressView!.snp.top).offset(-17)
        }
        
        effectView!.snp.makeConstraints { (make) in
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        // 更新特效时间
        effectView!.update(effectTimeModels: effectTimeModels)
        effectView!.update(decoderWorkType: decoderWorkType)
    }
    
    deinit {
        NSLog("MVYEffectViewController deinit")
    }
}

// MARK: UI控制
extension MVYEffectViewController: MVYEffectViewDelegate {
    
    func undo() {
        if effectTimeModels.count > 0 {
            effectTimeModels.removeLast()
            effectView!.update(effectTimeModels: effectTimeModels)
            
            if let setEffectTimeBlock = self.setEffectTimeBlock {
                setEffectTimeBlock(effectTimeModels)
            }
        }
    }
    
    func seekTo(time: Double) {
        var time = time
        
        if decoderWorkType.type == .reverse {
            time = Double(totalDuration) - time
        }
        
        videoSeeker?.setSeekTime(Int64(time))
    }
    
    func slowPlay(startTime: Double, duration: Double) {
        decoderWorkType.slowDecoderRange.location = Int(startTime);
        decoderWorkType.slowDecoderRange.length = Int(duration);
        if let setDecoderWorkTypeBlock = self.setDecoderWorkTypeBlock {
            setDecoderWorkTypeBlock(self.decoderWorkType)
        }
    }
    
    func touchDown(model: MVYEffectCellModel) {
        if model.effectType < 0 { // 时间特效
            addTimeEffect(effectCell: model)
            
        } else { // 普通特效
            addEffect(effectCell: model)
        }
        
        // 开始播放
        play(startTime: currentTime)
    }
    
    func touchUp(model: MVYEffectCellModel) {
        // 停止播放器
        stop()
        
        if model.effectType < 0 { // 时间特效
            saveTimeEffect(effectCell: model)
            
        } else { // 普通特效
            saveEffect()
        }
        
        if let setEffectTimeBlock = self.setEffectTimeBlock {
            setEffectTimeBlock(effectTimeModels)
        }
    }
}

// MARK: 播放控制
extension MVYEffectViewController {
    // 开始播放
    func play(startTime: Int64) {
        switch decoderWorkType.type {
        case .normal:
            videoPlayer?.startPlay(withSeekTime: startTime)
            
        case .reverse:
            videoPlayer?.startReversePlay(withSeekTime: startTime)
        
        case .slow:
            videoPlayer?.startSlowPlay(withSeekTime: startTime, slowTime: decoderWorkType.slowDecoderRange)
        }
    }
    
    // 停止
    func stop() {
        self.videoPlayer?.stopPlay()
    }
}

// MARK: 解码回调
extension MVYEffectViewController: MVYVideoPlayerDelegate, MVYVideoSeekerDelegate {
    
    func videoPlayerOutput(with frame: MVYVideoFrame!) {
        // 更新特效进度
        currentTime = frame.globalPts + frame.duration
        if currentTimeModel.startTime == -1 {
            currentTimeModel.startTime = frame.globalPts
        }
        currentTimeModel.duration = currentTime - currentTimeModel.startTime;
        
        DispatchQueue.main.async {
            // 更新特效时间
            self.updateEffect(pts: Double(frame!.globalPts), duration: Double(frame!.duration))
        }
        
        if let setEffectTimeBlock = self.setEffectTimeBlock {
            setEffectTimeBlock(effectTimeModels)
        }

        if let effectProcessBlock = self.effectProcessBlock {
            if let pixelBuffer = effectProcessBlock(frame) {
                if (frame.rotate == 90) {
                    preview.previewRotationMode = .rotateLeft
                }
                preview.previewContentMode = .scaleAspectFit
                preview.render(pixelBuffer)
            }
        }
    }
    
    func seekerOutput(with frame: MVYVideoFrame!) {
        
        if decoderWorkType.type == .reverse {
            frame.pts = frame.length - frame.pts - frame.duration
            frame.globalPts = frame.globalLength - frame.globalPts - frame.duration
        }
        
        // 时间指向当前帧
        currentTime = frame.globalPts

        if let setEffectTimeBlock = self.setEffectTimeBlock {
            setEffectTimeBlock(effectTimeModels)
        }
        
        if let effectProcessBlock = self.effectProcessBlock {
            if let pixelBuffer = effectProcessBlock(frame) {
                if (frame.rotate == 90) {
                    preview.previewRotationMode = .rotateLeft
                }
                preview.previewContentMode = .scaleAspectFit
                preview.render(pixelBuffer)
            }
        }
    }
}

// MARK: 普通特效
extension MVYEffectViewController {
    
    // 添加新的特效时间
    func addEffect(effectCell: MVYEffectCellModel) {
        currentTimeModel = MVYEffectTimeModel()
        currentTimeModel.startTime = -1
        currentTimeModel.duration = 0
        currentTimeModel.effectColor = effectCell.effectColor
        currentTimeModel.identification = effectCell.effectType
        
        effectTimeModels.append(currentTimeModel)
    }
    
    // 更新特效时间
    func updateEffect(pts:Double, duration: Double) {
        
        // 更新进度条, 时间指向下一帧开始
        effectView?.update(currentTime: pts + duration)
        effectView?.update(effectTimeModels: effectTimeModels)
    }
    
    // 计算, 存储特效时间
    func saveEffect() {
    
        // 当前特效没有时长
        if currentTimeModel.duration == 0 {
            return
        }
        
        // 获取最后一次的特效位置数组
        var lastEffectIndexResult = [MVYEffectTimeIndexModel]()
    
        if effectTimeModels.count == 1 {
            let defaultEffectIndex = MVYEffectTimeIndexModel()
            defaultEffectIndex.startTime = 0
            defaultEffectIndex.identification = 0
            
            lastEffectIndexResult = [defaultEffectIndex]
        } else {
            let effectIndexResult = effectTimeModels[effectTimeModels.count - 2].effectIndexResult
            
            lastEffectIndexResult = effectIndexResult
        }
        
        // 获取被覆盖的特效位置数据
        let effectEndTime = currentTimeModel.startTime + currentTimeModel.duration
        var coveredEffectIndexModel = [MVYEffectTimeIndexModel]()
        for effectIndexModel in lastEffectIndexResult {
            if (effectIndexModel.startTime >= currentTimeModel.startTime
                && effectIndexModel.startTime <= effectEndTime)
                || abs(effectIndexModel.startTime - currentTimeModel.startTime) < 10
                || abs(effectIndexModel.startTime - effectEndTime) < 10 {
                
                coveredEffectIndexModel.append(effectIndexModel)
            }
        }
        
        // 获取被覆盖的特效位置中最远的一个位置
        var farthestEffectIndexModel: MVYEffectTimeIndexModel? = nil
        for effectIndexModel in coveredEffectIndexModel {
            if farthestEffectIndexModel == nil {
                farthestEffectIndexModel = effectIndexModel
            } else {
                if farthestEffectIndexModel!.startTime < effectIndexModel.startTime {
                    farthestEffectIndexModel = effectIndexModel
                }
            }
        }
        
        // 删除除了最远的一个特效以外的其它特效
        for effectIndexModel in coveredEffectIndexModel {
            if effectIndexModel != farthestEffectIndexModel {
                lastEffectIndexResult.removeAll(where: { (model) -> Bool in
                    effectIndexModel == model
                })
            }
        }
        
        // 当前特效已经覆盖到了结尾, 删除最远的一个特效
        if abs(effectEndTime - totalDuration) < 10 {
            lastEffectIndexResult.removeAll(where: { (model) -> Bool in
                model == farthestEffectIndexModel
            })
        }
        
        // 插入当前的特效
        let currentEffectIndexModel = MVYEffectTimeIndexModel()
        currentEffectIndexModel.startTime = currentTimeModel.startTime
        currentEffectIndexModel.identification = currentTimeModel.identification
        lastEffectIndexResult.append(currentEffectIndexModel)
        
        // 被覆盖的特效位置中最远的一个位置设置到当前特效的尾部
        if let farthestEffectIndexModel = farthestEffectIndexModel {
            farthestEffectIndexModel.startTime = effectEndTime
        }
        
        // 没有覆盖别的特效, 完全在前一个特效之内
        if farthestEffectIndexModel == nil && abs(effectEndTime - totalDuration) > 10 {
            // 在尾部再插入一个特效
            var nearestEffectIndexModel:MVYEffectTimeIndexModel? = nil
            for effectIndexModel in lastEffectIndexResult {
                if effectIndexModel.startTime <= Int64(currentTimeModel.startTime) {
                    if nearestEffectIndexModel == nil {
                        nearestEffectIndexModel = effectIndexModel
                    }else {
                        if (nearestEffectIndexModel!.startTime < effectIndexModel.startTime) {
                            nearestEffectIndexModel = effectIndexModel
                        }
                    }
                }
            }
            let nextEffectIndex = MVYEffectTimeIndexModel()
            nextEffectIndex.startTime = effectEndTime
            nextEffectIndex.identification = nearestEffectIndexModel!.identification
            lastEffectIndexResult.append(nextEffectIndex)
        }
        
        // 重置特效位置
        lastEffectIndexResult.sort(by: { (model1, model2) -> Bool in
            model1.startTime < model2.startTime
        })
        currentTimeModel.effectIndexResult = lastEffectIndexResult
        
        currentTimeModel = MVYEffectTimeModel()
        
        for effectIndexModel in lastEffectIndexResult {
            NSLog("effect : %ld , startTime : %.2f",effectIndexModel.identification, effectIndexModel.startTime)
        }
        NSLog("\n")
    }
}

// MARK: 时间特效
extension MVYEffectViewController {
    
    // 添加时间特效
    func addTimeEffect(effectCell: MVYEffectCellModel) {
        
        decoderWorkType.color = effectCell.effectColor

        if effectCell.effectType == -1 { // 正常
            decoderWorkType.type = .normal
            if let setDecoderWorkTypeBlock = self.setDecoderWorkTypeBlock {
                setDecoderWorkTypeBlock(self.decoderWorkType)
            }
        } else if effectCell.effectType == -2 { // 倒序解码
            decoderWorkType.type = .reverse
            if let setDecoderWorkTypeBlock = self.setDecoderWorkTypeBlock {
                setDecoderWorkTypeBlock(self.decoderWorkType)
            }
        } else if effectCell.effectType == -3 { // 慢速解码
            decoderWorkType.type = .slow
            if let setDecoderWorkTypeBlock = self.setDecoderWorkTypeBlock {
                setDecoderWorkTypeBlock(self.decoderWorkType)
            }
        }
        
        effectView!.update(decoderWorkType: decoderWorkType)
        
        currentTime = 0
    }
    
    // 保存时间特效
    func saveTimeEffect(effectCell: MVYEffectCellModel) {

    }
}

// MARK: 特效数据
extension MVYEffectViewController {
    class func videoEffectCellModels()-> [MVYEffectCellModel] {
        
        var datas = [MVYEffectCellModel]()
        
        let iconRootPath = "\(Bundle.main.bundlePath)/VideoEffectResources/icon/"
        if let iconNames = try? FileManager.default.contentsOfDirectory(atPath: iconRootPath) {
            for iconName in iconNames {
                
                let data = MVYEffectCellModel()
                
                data.thumbnail = iconRootPath + iconName
                data.selectedThumbnail = data.thumbnail
                let start = iconName.index(iconName.startIndex, offsetBy:3)
                let end = iconName.index(iconName.endIndex, offsetBy:-8)
                data.text = String(iconName[start...end])
                data.effectType = Int(iconName[iconName.startIndex..<iconName.index(iconName.startIndex, offsetBy:2)]) ?? 0
                
                switch data.effectType % 6 {
                case 0:
                    data.effectColor = UIColor.init(red: 0.8, green: 0, blue: 0, alpha: 1)
                    break
                case 1:
                    data.effectColor = UIColor.init(red: 0, green: 0.8, blue: 0, alpha: 1)
                    break
                case 2:
                    data.effectColor = UIColor.init(red: 0, green: 0, blue: 0.8, alpha: 1)
                    break
                case 3:
                    data.effectColor = UIColor.init(red: 0.8, green: 0.8, blue: 0, alpha: 1)
                    break
                case 4:
                    data.effectColor = UIColor.init(red: 0.8, green: 0, blue: 0.8, alpha: 1)
                    break
                case 5:
                    data.effectColor = UIColor.init(red: 0, green: 0.8, blue: 0.8, alpha: 1)
                    break
                default:
                    break
                }
                
                datas.append(data)
            }
            
            datas.sort { (model_1, model_2) -> Bool in
                model_1.effectType < model_2.effectType
            }
        }
        
        return datas
    }
    
    class func timeEffectCellModels()-> [MVYEffectCellModel] {
        
        var datas = [MVYEffectCellModel]()
       
        let data = MVYEffectCellModel()
        data.thumbnail = "\(Bundle.main.bundlePath)/TimeEffectResources/icon/默认@2x.png"
        data.selectedThumbnail = "\(Bundle.main.bundlePath)/TimeEffectResources/icon/默认_selected@2x.png"
        data.text = "默认"
        data.effectType = -1
        data.effectColor = UIColor.gray
        datas.append(data)
        
        let data2 = MVYEffectCellModel()
        data2.thumbnail = "\(Bundle.main.bundlePath)/TimeEffectResources/icon/时间倒流@2x.png"
        data2.selectedThumbnail = "\(Bundle.main.bundlePath)/TimeEffectResources/icon/时间倒流_selected@2x.png"
        data2.text = "时光倒流"
        data2.effectType = -2
        data2.effectColor = UIColor.init(red: 0xec/0xff, green: 0x61/0xff, blue: 0xc9/0xff, alpha: 1)
        datas.append(data2)
        
        let data3 = MVYEffectCellModel()
        data3.thumbnail = "\(Bundle.main.bundlePath)/TimeEffectResources/icon/慢动作@2x.png"
        data3.selectedThumbnail = "\(Bundle.main.bundlePath)/TimeEffectResources/icon/慢动作_selected@2x.png"
        data3.text = "慢动作"
        data3.effectType = -3
        data3.effectColor = UIColor.init(red: 0x7c/0xff, green: 0xcf/0xff, blue: 0x30/0xff, alpha: 1)
        datas.append(data3)

        return datas
    }
}
