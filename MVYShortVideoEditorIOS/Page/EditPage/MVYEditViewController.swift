//
//  MVYEditViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/24.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYEditViewController: UIViewController {

    // 输入的视频
    var videoPaths:Array<String>? = nil
    
    // 输入的音频
    var audioPaths:Array<String>? = nil
    
    // 背景音乐
    private var musicStartTime:Double = 0
    private var musicVolume:Float = 1
    private var musicPlayer:AVAudioPlayer? = nil

    // 预览UI
    private let preview = MVYPixelBufferPreview.init()
    
    // 布局
    private let contentView = MVYEditView()
    
    // 播放器
    private var mediaPlayer:MVYMediaPlayer? = nil
    
    // 解码器工作类型
    private var decoderWorkType = MVYDecoderWorkTypeModel()
    
    // 数据处理
    private let effectHandler = MVYVideoEffectHandler.init(processTexture: false)
    
    // 音频播放器
    private let audioTracker = MVYAudioTracker.init(sampleRate: 44100)
    private var audioTrackerVolume:Float = 1
    
    // 贴纸数据
    private var stickerModels = [MVYImageStickerModel]()
    private var showingStickerModels = [(MVYImageStickerModel, MVYGPUImageStickerModel)]()
    
    // 特效数据
    private var effectTimeModels = [MVYEffectTimeModel]()
    
    // 状态
    private var viewAppear = false
    
    convenience init(videoPaths:Array<String>, audioPaths:Array<String>) {
        self.init()
        
        self.videoPaths = videoPaths
        self.audioPaths = audioPaths
        self.mediaPlayer = MVYMediaPlayer.init(videoPaths: videoPaths, audioPaths: audioPaths)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black

        contentView.delegate = self
        
        self.view.addSubview(preview)
        self.view.addSubview(contentView)
        
        preview.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }

        contentView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(topLayoutGuide.snp.bottom)
            make.bottom.equalTo(bottomLayoutGuide.snp.top)
        }
        
        mediaPlayer?.playerDelegate = self;
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewAppear = true
        startPlay()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewAppear = false
        stopPlay()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        NSLog("MVYEditViewController deinit");
    }
}

// MARK: 播放控制
extension MVYEditViewController {
    func startPlay() {
        // 开始音视频播放
        switch decoderWorkType.type {
        case .normal:
            mediaPlayer?.startPlay()
            
        case .reverse:
            mediaPlayer?.startReversePlay()
            
        case .slow:
            mediaPlayer?.startSlowPlay(withSeekTime: 0, slowTime: NSMakeRange(0, 500));
            
        case .fast:
            mediaPlayer?.startFastPlay(withSeekTime: 0, slowTime: NSMakeRange(0, 500));
        }
        
        if #available(iOS 10.0, *) { // 打开扬声器
            try? AVAudioSession.sharedInstance().setActive(true, options: .init(rawValue: 0))
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .defaultToSpeaker)
        }
        
        // 打开音频播放器
        audioTracker?.volume = CGFloat(audioTrackerVolume)
        audioTracker?.play()
        
        // 打开音乐播放器
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let musicPath = appDelegate.musicPath {
            musicPlayer = try? AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: musicPath))
            musicPlayer?.currentTime = musicStartTime
            musicPlayer?.volume = musicVolume
            musicPlayer?.play()
        }
    }
    
    func stopPlay() {
        // 停止音视频播放
        mediaPlayer?.stopPlay()
        
        // 停止音频播放
        audioTracker?.stop()
        
        // 停止音乐播放
        musicPlayer?.stop()
    }
}

// MARK: 音视频播放
extension MVYEditViewController: MVYMediaPlayerDelegate {
    func videoPlayerOutput(with videoFrame: MVYVideoFrame!) {
        // 添加各种图片效果
        let pixelBuffer = processEffect(videoFrame: videoFrame)

        if let pixelBuffer = pixelBuffer {
            // 渲染到画面
            if videoFrame.rotate == 90 {
                preview.previewRotationMode = .rotateLeft
            }
            preview.previewContentMode = .scaleAspectFit
            preview.render(pixelBuffer)
        }
    }
    
    func audioPlayerOutput(with audioFrame: MVYAudioFrame!) {
        audioTracker?.write(audioFrame.buffer)
    }
    
    func videoPlayerStop() {
        
    }
    
    func videoPlayerFinish() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            // 重新开始播放
            self.stopPlay()
            if self.viewAppear {
                self.startPlay()
            }
        })
    }
}

// MARK: UI事件
extension MVYEditViewController: MVYEditViewDelegate {

    // 下一步导出
    func onNextBtClick() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let musicPath = appDelegate.musicPath ?? ""
        
        let vc = MVYOutputViewController.init(
            // 视频文件
            videoPaths: videoPaths!,
            
            // 音频文件
            audioPaths: audioPaths!,
            
            // 音乐文件
            musicPath: musicPath,
            
            // 音乐开始时间
            musicStartTime: musicStartTime,
            
            // 音频音量
            audioVolume: Double(audioTrackerVolume),
            
            // 音乐音量
            musicVolume: Double(musicVolume),
            
            // 解码模式
            decoderWorkType: decoderWorkType
        ) {[weak self] (frame) -> CVPixelBuffer? in
            let result = self?.processEffect(videoFrame: frame)
            return result
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // 原始音频开关
    func onOriginAudioBtClick(isOpen: Bool) {
        if isOpen {
            audioTrackerVolume = 1
        } else {
            audioTrackerVolume = 0
        }
        
        // 更新音量大小
        audioTracker?.volume = CGFloat(audioTrackerVolume)
    }
    
    // 弹出选择背景音乐的页面
    func onPushMusicPage() {
        let vc = MVYMusicViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // 弹出剪切背景音乐控件
    func onShowCutAudioPanel() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let musicPath = appDelegate.musicPath {
            
            var totalDuration:Double = 0
            for videoPath in videoPaths! {
                let asset = AVURLAsset.init(url: URL.init(fileURLWithPath: videoPath))
                totalDuration = totalDuration + asset.duration.seconds
            }
            
            contentView.cutAudioPanel.setData(audioURL: URL.init(fileURLWithPath: musicPath), startTime: musicStartTime, duration: totalDuration)
        }
    }
    
    // 剪切背景音乐的结果
    func onCutAudioPanelValueChange(currentTime:Double) {
        musicStartTime = currentTime
        
        // 重新开始播放
        self.stopPlay()
        self.startPlay()
    }
    
    // 弹出音量调节的控件
    func onShowVolumePanel() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let _ = appDelegate.musicPath {
            contentView.volumeEditPanel.hideMusicSlider(isHidden: false)
        } else {
            contentView.volumeEditPanel.hideMusicSlider(isHidden: true)
        }
        
        contentView.volumeEditPanel.setVolume(audioTrackerVolume, musicVolume)
    }
    
    // 音量调节的结果
    func onVolumePanelValueChange(originAudioVolume: Float, musicVolume: Float) {
        self.audioTrackerVolume = originAudioVolume
        self.musicVolume = musicVolume
        
        audioTracker?.volume = CGFloat(audioTrackerVolume)
        musicPlayer?.volume = musicVolume
    }
    
    // 弹出贴纸
    func onShowStickerPanel() {
        self.stopPlay()
    }
    
    // 贴纸数据变化
    func onStickerPanelValueChange(stickerModels: Array<MVYImageStickerModel>) {
        self.stickerModels = stickerModels
        self.startPlay()
    }
    
    // 跳转选择封面页面
    func onShowCoverPage() {
        let viewController = MVYCoverViewController.init(videoPaths: videoPaths!, decoderWorkType: decoderWorkType) {[weak self] videoFrame in
            return self?.processEffect(videoFrame: videoFrame)
        }
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    // 跳转选择特效页面
    func onShowEffectPage() {
        let viewController = MVYEffectViewController.init(
            // 特效视频
            videoPaths: videoPaths!,
            
            // 普通特效时间数据
            effectTimeModels: effectTimeModels,
            
            // 时间特效数据
            decoderWorkType: decoderWorkType,
            
            // 处理每帧
            effectProcessBlock: {[weak self] videoFrame  -> CVPixelBuffer? in
                return self?.processEffect(videoFrame: videoFrame)
            },
            
            // 普通特效时间数据
            setEffectTimeBlock: {[weak self] (effectTimeModels) in
                self?.effectTimeModels = effectTimeModels
            },
            
            // 时间特效数据
            setDecoderWorkTypeBlock: {[weak self] decoderWorkType in
                self?.decoderWorkType = decoderWorkType
            }
        )
        
        navigationController?.pushViewController(viewController, animated: true)
    }
}

// MARK: 处理各种效果
extension MVYEditViewController {
    
    // 处理各种效果
    func processEffect(videoFrame: MVYVideoFrame!) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer? = nil
        
        if let effectHandler = effectHandler {
            
            let bgraBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(videoFrame!.lineSize * videoFrame!.height * 4), alignment: MemoryLayout<Int8>.alignment)

            processSticker(videoFrame: videoFrame)
            
            if (videoFrame.rotate == 90) {
                effectHandler.rotateMode = .rotateLeft
            }

            effectHandler.process(withYBuffer: videoFrame.yData, uBuffer: videoFrame.uData, vBuffer: videoFrame.vData, width: videoFrame.lineSize, height: videoFrame.height, bgraBuffer: bgraBuffer)
            
            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(videoFrame!.width), Int(videoFrame!.height), kCVPixelFormatType_32BGRA, bgraBuffer, Int(videoFrame!.lineSize * 4), {(releaseRefCon, baseAddress) in
                baseAddress?.deallocate()
            }, nil, nil, &pixelBuffer)
        }
        
        return pixelBuffer
    }
    
    // 处理贴纸
    func processSticker(videoFrame: MVYVideoFrame!) {
        
        if let effectHandler = effectHandler {
            
            if videoFrame.globalPts < 10 { // 第一帧
                // 清空贴纸
                effectHandler.clearSticker()
                showingStickerModels.removeAll()
            }
            
            // 处理贴纸
            for stickerModel in stickerModels {
                
                let stickerStartPts = Int64(Double(stickerModel.start) * Double(videoFrame.globalLength))
                let stickerEndPts = Int64(Double(stickerModel.end) * Double(videoFrame.globalLength))
                
                // 添加贴纸
                if stickerStartPts <= videoFrame.globalPts || abs(stickerStartPts - videoFrame.globalPts) < 10 {
                    
                    if !showingStickerModels.contains(where: { $0.0 === stickerModel }) {
                        
                        let gpuImageStickerModel = MVYGPUImageStickerModel()
                        gpuImageStickerModel.image = stickerModel.image
                        // 移动位置
                        let videoPreviewWidth = contentView.stickerPanel.frame.width
                        let asset = AVAsset.init(url: URL.init(fileURLWithPath: videoPaths![0]))
                        let tracks = asset.tracks(withMediaType: .video)
                        let videoSize = __CGSizeApplyAffineTransform(tracks[0].naturalSize, tracks[0].preferredTransform)
                        let videoPreviewHeight = videoPreviewWidth * abs(videoSize.height) / abs(videoSize.width)
                        let translationX = (stickerModel.bound.origin.x + stickerModel.bound.size.width / 2) / videoPreviewWidth * 2.0 - 1.0
                        let translationY = (stickerModel.bound.origin.y + stickerModel.bound.size.height / 2) / videoPreviewHeight * 2.0 - 1.0
                        gpuImageStickerModel.transformMatrix = CATransform3DMakeTranslation(translationX, translationY, 0)
                        // 缩放大小
                        let scaleX = stickerModel.bound.width * UIScreen.main.scale / stickerModel.image.size.width
                        let scaleY = stickerModel.bound.height * UIScreen.main.scale / stickerModel.image.size.height
                        gpuImageStickerModel.transformMatrix = CATransform3DScale(gpuImageStickerModel.transformMatrix, scaleX, scaleY, 1)
                        
                        // 添加
                        effectHandler.addSticker(with: gpuImageStickerModel)
                        
                        showingStickerModels.append((stickerModel, gpuImageStickerModel))
                    }
                }
                
                // 删除贴纸
                if stickerEndPts + 10 < videoFrame.globalPts + videoFrame.duration {
                    
                    if showingStickerModels.contains(where: { $0.0 === stickerModel }) { // 显示过
                        
                        showingStickerModels.removeAll { (model) -> Bool in
                            let result = model.0 === stickerModel
                            if result {
                                
                                effectHandler.removeSticker(with: model.1) // 删除
                            }
                            return result
                        }
                    }
                }
            }
            
            // 处理特效
            if let effectTimeModel = effectTimeModels.last {
                if effectTimeModel.effectIndexResult.count > 0 { // 完整的特效数据
                    for effectIndexModel in effectTimeModel.effectIndexResult {
                        if effectIndexModel.startTime >= videoFrame.globalPts{
                            if (effectIndexModel.startTime <= videoFrame.globalPts + videoFrame.duration) { // 特效第一帧, 重置特效
                                effectHandler.resetMagicShaderEffect()
                                effectHandler.setTypeOfMagicShaderEffect(effectIndexModel.identification)
                            }
                            break
                        }
                    }
                } else { // 特效编辑页面还在处理中的特效数据
                    effectHandler.setTypeOfMagicShaderEffect(effectTimeModel.identification)
                }
            } else {
                effectHandler.setTypeOfMagicShaderEffect(0)
            }
        }
    }
}

