//
//  MVYRecordViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import SnapKit
import MBProgressHUD

class MVYRecordViewController: UIViewController {
    
    /// 分辩率在录制的时候设置
    var resolution = ""
    
    /// 帧率在最后合成的时候设置
    var frameRate = ""
    
    /// 视频码率在合成的时候设置
    var videoBitrate = ""
    
    /// 音频码率在合成的时候设置
    var audioBitrate = ""
    
    /// 屏比
    var screenRate = ""
    
    /// 背景音乐
    var musicPlayer:AVAudioPlayer? = nil
    
    /// 最长录制时间
    private let longestVideoSeconds:Float64 = 30
    
    // 状态
    private var viewAppear = false
    
    // 是否写入
    private var writeData = false
    private var writeDataLock = NSLock()
    
    // 录制视频
    private var camera:MVYCamera? = nil
    private let preview = MVYPixelBufferPreview()
    private let tapGestureView = UIView()
    private var writer:MVYMediaWriter = MVYMediaWriter.sharedInstance()
    private var stopPreview = false
    
    // 特效
    private var effectHandler:MVYCameraEffectHandler? = nil
    private let openGLLock = NSLock()

    // 页面
    private let recordView = MVYRecordView()
    private var focusBoxLayer:CALayer? = nil
    private var focusBoxAnimation:CAAnimation? = nil
    
    // 数据
    private var medias = Array<MVYMediaItemModel>()
    private var recordingMedia = MVYMediaItemModel()
    private var synthesizeVideoURL:URL? = nil
    private var synthesizeAudioURL:URL? = nil
    
    // 音效
    private var audioTempoEffect:MVYAudioTempoEffect? = nil
    
    // 导出
    private var videoExporter:AVAssetExportSession? = nil
    private var audioExporter:AVAssetExportSession? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black

        recordView.delegate = self

        // 设置相机预览
        preview.previewContentMode = .scaleAspectFill
        
        self.view.addSubview(preview)
        self.view.addSubview(tapGestureView)
        self.view.addSubview(recordView)
        
        preview.snp.makeConstraints { (make) in
            // 处理预览时的屏比
            if screenRate == "16:9" {
                make.edges.equalTo(0)
                
            } else if screenRate == "4:3" {
                make.width.equalToSuperview()
                make.height.equalTo(self.view.snp.width).multipliedBy(4/3.0)
                make.centerY.equalToSuperview()
                
            } else if screenRate == "1:1" {
                make.width.equalToSuperview()
                make.height.equalTo(self.view.snp.width)
                make.centerY.equalToSuperview()
            }
        }
        
        tapGestureView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        recordView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
        // 添加点按手势, 点按时聚焦
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(tapScreen(_:)))
        tapGesture.numberOfTapsRequired = 1
        tapGestureView.addGestureRecognizer(tapGesture)
        
        // 相机, 录制视频分辩率,屏比
        if resolution == "1080p" {
            camera = MVYCamera.init(resolution: AVCaptureSession.Preset.hd1920x1080)
            
            if screenRate == "16:9" {
                writer.videoWidth = 1080
                writer.videoHeight = 1920
                
            } else if screenRate == "4:3" {
                writer.videoWidth = 1080
                writer.videoHeight = 1440
                
            } else if screenRate == "1:1" {
                writer.videoWidth = 1080
                writer.videoHeight = 1080
            }
            
        } else if resolution == "720p" {
            camera = MVYCamera.init(resolution: AVCaptureSession.Preset.hd1280x720)
            
            if screenRate == "16:9" {
                writer.videoWidth = 720
                writer.videoHeight = 1280
                
            } else if screenRate == "4:3" {
                writer.videoWidth = 720
                writer.videoHeight = 960
                
            } else if screenRate == "1:1" {
                writer.videoWidth = 720
                writer.videoHeight = 720
            }
            
        } else if resolution == "540p" {
            camera = MVYCamera.init(resolution: AVCaptureSession.Preset.iFrame960x540)
            
            if screenRate == "16:9" {
                writer.videoWidth = 540
                writer.videoHeight = 960
                
            } else if screenRate == "4:3" {
                writer.videoWidth = 540
                writer.videoHeight = 720
                
            } else if screenRate == "1:1" {
                writer.videoWidth = 540
                writer.videoHeight = 540
            }
        }
        camera?.delegate = self
        camera?.setFrameRate(60)
        
        // 页面状态监听
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterForeground(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        // 初始数据
        initData()
    }
    
    func initData() {
        recordView.progressView.recordingMedia = recordingMedia
        recordView.progressView.medias = medias
        recordView.progressView.longestVideoSeconds = longestVideoSeconds
    }
    
    // MARK: - ViewControllerLifeCycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        openGLLock.lock()

        self.viewAppear = true
        
        // 打开相机
        camera?.startCapture()
        
        // 开始预览
        stopPreview = false

        // 页面常亮
        UIApplication.shared.isIdleTimerDisabled = true
        
        openGLLock.unlock()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        openGLLock.lock()

        viewAppear = false
        
        // 关闭相机
        camera?.stopCapture()
        
        // 结束预览
        stopPreview = true
        
        // 关闭页面常亮
        UIApplication.shared.isIdleTimerDisabled = false
        
        // 释放画面预览的资源
        preview.releaseGLResources()
        
        // 释放特效处理的资源
        effectHandler?.destroy()
        effectHandler = nil
        
        openGLLock.unlock()
    }
    
    @objc func enterForeground(_ notification:Notification) {
        if viewAppear {
            
            openGLLock.lock()
            
            // 打开相机
            camera?.startCapture()
            
            // 开始预览
            stopPreview = false
            
            // 页面常亮
            UIApplication.shared.isIdleTimerDisabled = true
            
            openGLLock.unlock()
        }
    }
    
    @objc func enterBackground(_ notification:Notification) {
        if viewAppear {
            
            openGLLock.lock()
            
            // 取消录制
            cancelRecordVideo()
            
            // 关闭相机
            camera?.stopCapture()
            
            // 结束预览
            stopPreview = true
            
            // 关闭页面常亮
            UIApplication.shared.isIdleTimerDisabled = false
            
            // 释放画面预览的资源
            preview.releaseGLResources()
            
            // 释放特效处理的资源
            effectHandler?.destroy()
            effectHandler = nil
            
            openGLLock.unlock()
        }
    }
    
    // MARK: Tap Screen
    @objc func tapScreen(_ tapGesture:UITapGestureRecognizer) {
        let point = tapGesture.location(in: preview)
        
        var pointOfInterest:CGPoint? = nil
        pointOfInterest = CGPoint.init(x: point.y / preview.bounds.size.height, y: 1.0 - point.x / preview.bounds.size.width)
        
        camera?.focus(at: pointOfInterest!)
        showFocusBox(point)
    }
    
    //
    private func showFocusBox(_ point:CGPoint) {
        if focusBoxLayer == nil {
            let focusBoxLayer = CALayer.init()
            focusBoxLayer.cornerRadius = 3.0
            focusBoxLayer.bounds = CGRect.init(x: 0.0, y: 0.0, width: 70.0, height: 70.0)
            focusBoxLayer.borderWidth = 1.0
            focusBoxLayer.borderColor = UIColor.yellow.cgColor
            focusBoxLayer.opacity = 0.0
            tapGestureView.layer.addSublayer(focusBoxLayer)
            self.focusBoxLayer = focusBoxLayer
        }
        
        if focusBoxAnimation == nil {
            let focusBoxAnimation = CABasicAnimation.init(keyPath: "opacity")
            focusBoxAnimation.duration = 1;
            focusBoxAnimation.autoreverses = false;
            focusBoxAnimation.repeatCount = 0.0;
            focusBoxAnimation.fromValue = 1.0;
            focusBoxAnimation.toValue = 0.0;
            self.focusBoxAnimation = focusBoxAnimation
        }
        
        self.focusBoxLayer?.removeAllAnimations()
        
        CATransaction.begin()
        CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
        self.focusBoxLayer?.position = point
        CATransaction.commit()
        
        self.focusBoxLayer?.add(self.focusBoxAnimation!, forKey: "animateOpacity")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        NSLog("MVYRecordViewController deinit");
    }
}

extension MVYRecordViewController: MVYRecordViewDelegate {
    
    // 切换相机
    func switchCamera() {
        if camera?.cameraPosition == AVCaptureDevice.Position.back {
            camera?.cameraPosition = AVCaptureDevice.Position.front
        } else {
            camera?.cameraPosition = AVCaptureDevice.Position.back
        }
    }
    
    // 下一步
    func next() {
        if medias.count == 0 {
            NSLog("请录制一段视频")
            return
        }
        
        if !writer.isWriteFinish() {
            NSLog("请等待录制完成")
            return
        }
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        enterEditViewController()
    }
    
    // 美颜
    func beautyValueChange(_ value: Float) {
        effectHandler?.intensityOfBeauty = CGFloat(value)
    }
    
    // 亮度
    func brightnessValueChange(_ value: Float) {
        effectHandler?.intensityOfBrightness = CGFloat(value)
    }
    
    // 饱合度
    func saturationValueChange(_ value: Float) {
        effectHandler?.intensityOfSaturation = CGFloat(value)
    }
    
    // 音乐
    func music() {
        let vc = MVYMusicViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // 风格滤镜
    func style(_ model: MVYStyleModel) {
        effectHandler?.style = UIImage.init(contentsOfFile: model.path!)
        effectHandler?.intensityOfStyle = 0.8
    }
    
    // 开始录制
    func startRecord() {
        NSLog("开始录制")
        
        // 设置音频处理方式
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 10.0, *) {
            do {
                try session.setCategory(.playAndRecord, mode: .default, options: AVAudioSession.CategoryOptions.mixWithOthers)
            } catch {
                
            }
        }

        try? session.setActive(true)
        
        // 开始录制
        startRecordVideo()
        
        // 播放音乐
        var seekTime = 0.0
        for media in medias {
            seekTime = seekTime + Double(media.videoSeconds)
        }
        
        // 创建背景音乐播放器
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let musidPath = appDelegate.musicPath {
            musicPlayer = try? AVAudioPlayer.init(contentsOf: URL.init(fileURLWithPath: musidPath))
            musicPlayer?.currentTime = seekTime
            musicPlayer?.play()
        }
    }
    
    // 停止录制
    func stopRecord() {
        NSLog("停止录制")
        finishRecordVideo()
        
        // 暂停音乐
        musicPlayer?.pause()
    }
    
    // 删除
    func delete() {
        // 删除音视频文件
        if medias.count > 0 {
            let modelItemModel = medias.removeLast()
            if FileManager.default.fileExists(atPath: modelItemModel.videoPath) {
                try? FileManager.default.removeItem(atPath: modelItemModel.videoPath)
            }
            if FileManager.default.fileExists(atPath: modelItemModel.audioPath) {
                try? FileManager.default.removeItem(atPath: modelItemModel.audioPath)
            }
            
            recordView.progressView.medias = medias
            recordView.progressView.setNeedsDisplay()
        }
    }
}

extension MVYRecordViewController: MVYCameraDelegate {
    func cameraVideoOutput(_ sampleBuffer: CMSampleBuffer!) {
        //========== 当前为相机视频数据传输 线程==========//
        
        openGLLock.lock()
        
        if effectHandler == nil {
            effectHandler = MVYCameraEffectHandler.init(processTexture: false)

            // 添加左上角贴纸
            let stickerModel = MVYGPUImageStickerModel.init()
            stickerModel.image = UIImage.init(named: "cctv")
            // 移动位置
            stickerModel.transformMatrix = CATransform3DMakeTranslation(-0.7, -0.8, 0)
            // 缩放大小
            stickerModel.transformMatrix = CATransform3DScale(stickerModel.transformMatrix, 1.2, 1.2, 1)
            // 旋转Z轴15度
            stickerModel.transformMatrix = CATransform3DRotate(stickerModel.transformMatrix, CGFloat(Double.pi / -12), 0, 0, 1)
            effectHandler?.addSticker(with: stickerModel)
            
//            // 测试Zoom
//            effectHandler?.intensityOfZoom = 0.5;
        }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        // 设置画面方向
        effectHandler?.rotateMode = .rotateLeft

        // 设置镜像
        if camera?.cameraPosition == AVCaptureDevice.Position.front {
            effectHandler?.mirror = true
        }else if camera?.cameraPosition == AVCaptureDevice.Position.back{
            effectHandler?.mirror = false
        }
        effectHandler?.process(with: pixelBuffer)
        
        // 写数据到MP4文件
        if writeData {
            let time = CMTimeGetSeconds(writer.lastFramePresentationTimeStamp)

            DispatchQueue.main.async {
                self.recordingMedia.videoSeconds = time
                self.recordView.progressView.setNeedsDisplay()
            }

            var recordedTime:Double = 0
            for media in medias {
                recordedTime += media.videoSeconds
            }

            if recordedTime + time >= longestVideoSeconds { // 超过了写入的时长, 强制完成
                DispatchQueue.main.async {
                    self.recordView.clickRecordButton()
                }
            } else {
                if pixelBuffer != nil {
                    let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                    writer.writeVideoPixelBuffer(pixelBuffer, time: time)
                }
            }
        }
        
        // 预览相机画面
        if stopPreview == false {
            // 设置预览方向
            preview.previewRotationMode = .rotateLeft
            
            // 预览PixelBuffer
            preview.render(pixelBuffer)
        }
        
        openGLLock.unlock()
        
        //========== 当前为相机视频数据传输 线程==========//
    }
    
    func cameraAudioOutput(_ sampleBuffer: CMSampleBuffer!) {
        //========== 当前为相机音频数据传输 线程==========//
        
        //写数据到Mp4文件
        if writeData {
            writer.writeAudioSampleBuffer(sampleBuffer)
        }
        
        //========== 当前为相机音频数据传输 线程==========//
    }
    
    // MARK: Record Video Controller
    private func startRecordVideo() {
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let videoFileName = "\(uuid).m4v"
        let audioFileName = "\(uuid).m4a"
        
        let videoPath = "\(NSTemporaryDirectory())\(videoFileName)"
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        writer.outputVideoURL = URL.init(fileURLWithPath: videoPath)
        writer.outputAudioURL = URL.init(fileURLWithPath: audioPath)
        
        recordingMedia.speed = CMTime.init(value: 1, timescale: 1)
        if "极慢" == recordView.speedRadioButton.selectedText! {
            recordingMedia.speed = CMTime.init(value: 4, timescale: 10)
        } else if "慢" == recordView.speedRadioButton.selectedText! {
            recordingMedia.speed = CMTime.init(value: 8, timescale: 10)
        } else if "标准" == recordView.speedRadioButton.selectedText! {
            recordingMedia.speed = CMTime.init(value:10, timescale: 10)
        } else if "快" == recordView.speedRadioButton.selectedText! {
            recordingMedia.speed = CMTime.init(value: 12, timescale: 10)
        } else if "极快" == recordView.speedRadioButton.selectedText! {
            recordingMedia.speed = CMTime.init(value: 14, timescale: 10)
        }
        
        writer.videoSpeed = recordingMedia.speed
        
        writer.videoFrameRate = Int(frameRate) ?? 0
        
        writer.videoBitRate = (Int(videoBitrate) ?? 0) * 1000
        
        writer.audioBitRate = (Int(audioBitrate) ?? 0) * 1000

        if CMTimeGetSeconds(recordingMedia.speed) != 1 {
            audioTempoEffect = MVYAudioTempoEffect()
            audioTempoEffect?.inputPath = audioPath
            audioTempoEffect?.outputPath = "\(NSTemporaryDirectory())\(uuid)t.wav"
            audioTempoEffect?.tempo = CGFloat(CMTimeGetSeconds((recordingMedia.speed)))
        }
        
        writeData = true
        
        recordingMedia.videoPath = videoPath
        recordingMedia.audioPath = audioPath
        recordingMedia.videoSeconds = 0
        
        NSLog("录制的视频保存地址 \(videoPath) \(audioPath)")
    }
    
    private func finishRecordVideo() {
        if writeData {
            writeData = false
            
            writer.finishWriting {[weak self] in
                 //========== 当前为视频录制 线程==========//
                
                NSLog("视频录制完成")
                
                let time = CMTimeGetSeconds((self?.writer.lastFramePresentationTimeStamp)!)
                if time < 1 {
                    NSLog("视频录制时长小于一秒")
                } else {
                    // 处理音频节奏
                    if CMTimeGetSeconds((self?.recordingMedia.speed)!) != 1 {
                        
                        // 处理中
                        self?.audioTempoEffect?.process()
                        
                        // 删除输入的音频数据
                        if FileManager.default.fileExists(atPath: self?.audioTempoEffect?.inputPath ?? "") {
                            try? FileManager.default.removeItem(atPath: self?.audioTempoEffect?.inputPath ?? "")
                        }
                        
                        // 设置输出的音频
                        self?.recordingMedia.audioPath = self?.audioTempoEffect?.outputPath ?? ""
                        
                        self?.audioTempoEffect = nil
                    }
                    
                    // 判断音视频数据是否录制成功
                    let fileManager = FileManager.default
                    let videoFileSize = (try? fileManager.attributesOfItem(atPath: self?.recordingMedia.videoPath ?? "")[.size]) as? Int ?? 0
                    let audioFileSize = (try? fileManager.attributesOfItem(atPath: self?.recordingMedia.audioPath ?? "")[.size]) as? Int ?? 0
                    
                    // 添加到数据队列
                    if videoFileSize > 0 && audioFileSize > 0 {
                        let media = MVYMediaItemModel()
                        media.videoPath = (self?.recordingMedia.videoPath)!
                        media.audioPath = (self?.recordingMedia.audioPath)!
                        media.videoSeconds = time
                        media.speed = (self?.recordingMedia.speed)!
                        self?.medias.append(media)
                    }
                    
                    // 刷新UI
                    if let medias = self?.medias {
                        self?.recordView.progressView.medias = medias
                    }
                }
                
                // 更新布局
                self?.recordingMedia.videoSeconds = 0
                
                DispatchQueue.main.async {
                    self?.recordView.progressView.setNeedsDisplay()
                }
                
                 //========== 当前为视频录制 线程==========//
            }
        }
    }
    
    private func cancelRecordVideo() {
        if writeData {
            writeData = false
            
            NSLog("视频录制取消");
            
            writer.cancelWriting()
            
            // 更新布局
            recordingMedia.videoSeconds = 0
            recordView.progressView.setNeedsDisplay()
            recordView.recordButton.isSelected = false
        }
    }
    
    /// 跳转到下个页面
    private func enterEditViewController() {
        MBProgressHUD.hide(for: view, animated: true)
        
        var videoPaths = [String]()
        var audioPaths = [String]()
        
        for media in medias {
            videoPaths.append(media.videoPath)
            audioPaths.append(media.audioPath)
        }

        let vc = MVYEditViewController.init(videoPaths: videoPaths, audioPaths: audioPaths)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
