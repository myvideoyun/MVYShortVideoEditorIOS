//
//  MVYOutputViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/8.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import MBProgressHUD

typealias OutputPageEffectProcessBlock = (_ videoFrame: MVYVideoFrame) -> CVPixelBuffer?

class MVYOutputViewController: UIViewController {
    
    // 输入的视频
    var videoPaths = [String]()
    
    // 输入的音频
    var audioPaths = [String]()
    
    // 输入的背景音乐
    var musicPath = ""
    
    // 输入的音频音量
    var audioVolume:Double = 0
    
    // 输入的背景音乐开始时间
    var musicStartTime:Double = 0
    
    // 输入的音乐音量
    var musicVolume:Double = 0
    
    /// 帧率在最后合成的时候设置
    var frameRate = 0
    
    /// 视频码率在合成的时候设置
    var videoBitrate = 0
    
    /// 音频码率在合成的时候设置
    var audioBitrate = 0
    
    // UI
    private let contentView = MVYOutputView()
    
    // 解码器
    private let videoDecoder = MVYVideoDecoder()
    private let audioDecoder = MVYAudioDecoder()
    
    // 解码器工作类型
    private var decoderWorkType = MVYDecoderWorkTypeModel()
    
    // 数据处理
    var effectProcessBlock: OutputPageEffectProcessBlock? = nil
    
    // 编码器
    private var writer:MVYMediaWriter = MVYMediaWriter.sharedInstance()
    
    // 编码完成后的视频
    var videoPath = ""
    
    // 多段合并完成后的原始音频
    var concatOriginAudioPath = ""
    
    // 音量处理完成后的原始音频
    var volumeOriginAudioPath = ""
    
    // 剪切完成后的背景音乐
    var cutMusicPath = ""
    
    // 音量处理完成后的背景音乐
    var volumeMusicPath = ""
    
    // 音频混合完成后的音频
    var mixAudioPath = ""
    
    // 显示
    let preview = MVYPixelBufferPreview()
    
    convenience init(
        // 视频文件
        videoPaths:Array<String>,
        
        // 音频文件
        audioPaths:Array<String>,
        
        // 音乐路径
        musicPath:String,
        
        // 音乐开始时间
        musicStartTime:Double,
        
        // 音频文件音量
        audioVolume:Double,
        
        // 音乐音量
        musicVolume:Double,
        
        // 解码模式
        decoderWorkType:MVYDecoderWorkTypeModel,
        
        // 特效处理
        effectProcessBlock: @escaping OutputPageEffectProcessBlock) {
        self.init()
        
        self.videoPaths = videoPaths
        self.audioPaths = audioPaths
        self.musicPath = musicPath
        
        self.audioVolume = audioVolume
        self.musicVolume = musicVolume
        
        self.musicStartTime = musicStartTime
        
        self.decoderWorkType = decoderWorkType
        
        self.effectProcessBlock = effectProcessBlock
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        contentView.delegate = self
        
        self.view.addSubview(contentView)
        self.view.addSubview(preview)
        
        preview.snp.makeConstraints { (make) in
            make.width.equalTo(200)
            make.height.equalTo(200)
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(30)
        }
        
        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
        videoDecoder.decoderDelegate = self
        audioDecoder.decoderDelegate = self
    }
    
    deinit {
        self.videoDecoder.destroyNativeVideoDecoder()
        self.audioDecoder.destroyNativeAudioDecoder()
        
        NSLog("MVYOutputViewController deinit")
    }
}

// MARK: UI
extension MVYOutputViewController: MVYOutputViewDelegate {
    func saveMedia(frameRate: String, videoBitrate: String, audioBitrate: String) {
        self.frameRate = Int(frameRate) ?? 0
        self.videoBitrate = (Int(videoBitrate) ?? 0) * 1000
        self.audioBitrate = (Int(audioBitrate) ?? 0) * 1000
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        // 处理音频
        audioNextStepProcess()
    }
}

// MARK: 视频解码 MVYVideoDecoderDelegate
extension MVYOutputViewController: MVYVideoDecoderDelegate, MVYAudioDecoderDelegate {
    
    // 开始解码
    func startDecodeVideo() {
        videoDecoder.createNativeVideoDecoder(videoPaths)
        
        switch decoderWorkType.type {
        case .normal:
            videoDecoder.startDecode(withSeekTime: 0)
            
        case .reverse:
            videoDecoder.startReverseDecode(withSeekTime: 0)
            
        case .slow:
            videoDecoder.startSlowDecode(withSeekTime: 0, slowTime: decoderWorkType.slowDecoderRange)
        }
    }
    
    func startDecodeAudio() {
        audioDecoder.createNativeAudioDecoder([mixAudioPath])
        
        switch decoderWorkType.type {
        case .normal, .reverse:
            audioDecoder.startDecode(withSeekTime: 0)
            
        case .slow:
            audioDecoder.startSlowDecode(withSeekTime: 0, slowTime: decoderWorkType.slowDecoderRange)
        }
        
    }
    
    // 音频解码
    func audioDecoderOutput(with audioFrame: MVYAudioFrame!) {
        // 处理慢速解码
        if (decoderWorkType.type == .slow) {
            audioFrame.globalPts += audioFrame.offset
            if musicPath == "" {
                audioFrame.resampleUseTempo()
            }
        }
        
        if let sampleBuffer:CMSampleBuffer = MVYMediaWriterTool.pcmData(toSampleBuffer: audioFrame.buffer, pts: CMTime.init(seconds: Double(audioFrame.pts)/1000.0, preferredTimescale: 44100), duration: CMTime.init(seconds: Double(audioFrame.duration)/1000.0, preferredTimescale: 44100))?.takeUnretainedValue() {
            
            // 编码音频
            writeAudioFrame(sampleBuffer: sampleBuffer)
        } else {
            NSLog("音频编码失败")
        }
    }
    
    func audioDecoderStop() {
        
    }
    
    func audioDecoderFinish() {

    }
    
    // 视频解码
    func videoDecoderOutput(with videoFrame: MVYVideoFrame!) {
        // 处理慢速解码
        if (decoderWorkType.type == .slow) {
            videoFrame.globalPts += videoFrame.offset
        }
        
        if let effectProcessBlock = self.effectProcessBlock {
            let pixelBuffer = effectProcessBlock(videoFrame)
            if let pixelBuffer = pixelBuffer {
                
                // 编码视频
                self.writeVideoFrame(pixelBuffer: pixelBuffer, time: CMTime.init(seconds: Double(videoFrame.globalPts)/1000.0, preferredTimescale: 1000000))
            
                if videoFrame.rotate == 90 {
                    preview.previewRotationMode = .rotateLeft
                }
                preview.previewContentMode = .scaleAspectFit
                preview.render(pixelBuffer)
            }
        }
    }
    
    func videoDecoderStop() {
        
    }
    
    func videoDecoderFinish() {
        NSLog("视频解码完成")
        DispatchQueue.main.sync {
            finishEncode()
        }
    }
}

// MARK: 视频编码
extension MVYOutputViewController {
    // 开始编码
    func startEncode() {
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let videoFileName = "\(uuid).mp4"
        
        videoPath = "\(NSTemporaryDirectory())\(videoFileName)"
        
        writer.outputMediaURL = URL.init(fileURLWithPath: videoPath)
        writer.videoFrameRate = frameRate
        writer.videoBitRate = videoBitrate
    }
    
    // 写入视频
    func writeVideoFrame(pixelBuffer: CVPixelBuffer, time: CMTime) {
        writer.writeVideoPixelBuffer(pixelBuffer, time: time)
    }
    
    // 写入音频
    func writeAudioFrame(sampleBuffer: CMSampleBuffer) {
        writer.writeAudioSampleBuffer(sampleBuffer)
    }
    
    // 结束编码
    func finishEncode() {
        
        writer.finishWriting {[weak self] in
            // 视频处理完成
            DispatchQueue.main.sync {
                
                if let view = self?.view {
                    MBProgressHUD.hide(for: view, animated: true)
                }
                
                let videoFileSize = (try? FileManager.default.attributesOfItem(atPath: self?.videoPath ?? "")[.size]) as? Int ?? 0
                
                if videoFileSize > 0 {
                    
                    if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(self?.videoPath ?? ""){
                        UISaveVideoAtPathToSavedPhotosAlbum(self?.videoPath ?? "", self, nil, nil)
                        
                        let alert = UIAlertController.init(title: "完成", message: "音视频编码成功", preferredStyle: .alert)
                        alert.addAction(UIAlertAction.init(title: "确定", style: .cancel, handler: { (action) in
                            self?.dismiss(animated: true , completion: nil)
                            
                            self?.navigationController?.popViewController(animated: true)
                        }))
                        self?.present(alert, animated: true, completion: nil)
                    }
                    
                } else {

                        let alert = UIAlertController.init(title: "错误", message: "音视频编码失败", preferredStyle: .alert)
                        alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                            self?.dismiss(animated: true , completion: nil)
                        }))
                        self?.present(alert, animated: true, completion: nil)
                    
                }
            }
        }
    }
}

// MARK: 音视处理
extension MVYOutputViewController {
    // 音频拼接
    private func concatOriginAudio(inputAudioPaths:[String]) {
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let audioFileName = "\(uuid).wav"
        
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"

        let concatAudioCMD = MVYFFmpegCMD.concatAudioCMD(withInputAudioPath: inputAudioPaths, outputAudioPath: audioPath)
        
        NSLog("原始音频音频拼接 \(concatAudioCMD!)")
        
        MVYFFmpegCMD.exec(concatAudioCMD) { (result) in
            
            NSLog("原始音频音频拼接 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.concatOriginAudioPath = audioPath
                    self.audioNextStepProcess()
                    
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "原始音频拼接失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 音量调节
    private func setOriginAudioVolume(inputAudioPath:String) {
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let audioFileName = "\(uuid).wav"
        
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        let increaseVolumeCMD = MVYFFmpegCMD.increaseVolumeCMD(withVolume: "\(audioVolume)", inputAudioPath: inputAudioPath, outputAudioPath: audioPath)
        
        NSLog("原始音频音量调节 \(increaseVolumeCMD!)")
        
        MVYFFmpegCMD.exec(increaseVolumeCMD) { (result) in
            
            NSLog("原始音频音量调节 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.volumeOriginAudioPath = audioPath
                    self.audioNextStepProcess()

                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "原始音频音量调节", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 背景音乐剪切
    private func cutMusic(inputAudioPath:String) {
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let audioFileName = "\(uuid).wav"
        
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        let cutAudioCMD = MVYFFmpegCMD.cutAudioCMD(withStartPointTime: "\(musicStartTime)", inputAudioPath: inputAudioPath, outputAudioPath: audioPath)
        
        NSLog("背景音乐剪切 \(cutAudioCMD!)")
        
        MVYFFmpegCMD.exec(cutAudioCMD) { (result) in
            
            NSLog("背景音乐剪切 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.cutMusicPath = audioPath
                    self.audioNextStepProcess()
                    
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "背景音乐剪切", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 音量调节
    private func setMusicVolume(inputAudioPath:String) {
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let audioFileName = "\(uuid).wav"
        
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        let increaseVolumeCMD = MVYFFmpegCMD.increaseVolumeCMD(withVolume: "\(musicVolume)", inputAudioPath: inputAudioPath, outputAudioPath: audioPath)
        
        NSLog("背景音乐音量调节 \(increaseVolumeCMD!)")
        
        MVYFFmpegCMD.exec(increaseVolumeCMD) { (result) in
            
            NSLog("背景音乐音量调节 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.volumeMusicPath = audioPath
                    self.audioNextStepProcess()
                    
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "背景音乐音量调节", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 音频合并
    private func mixAudio(inputMajorAudioPath:String, inputMinorAudioPath:String) {
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let audioFileName = "\(uuid).wav"
        
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        let mixAudioCMD = MVYFFmpegCMD.mixAudioCMD(withInputMajorAudioPath: inputMajorAudioPath, inputMinorAudioPath: inputMinorAudioPath, outputAudioPath: audioPath)
        NSLog("音频合并 \(mixAudioCMD!)")
        
        MVYFFmpegCMD.exec(mixAudioCMD) { (result) in
            
            NSLog("音频合并 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.mixAudioPath = audioPath
                    self.audioNextStepProcess()
                    
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "音量调节失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 音视频合并
    private func mixVideo(inputMajorAudioPath:String, inputMinorAudioPath:String) {
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let audioFileName = "\(uuid).wav"
        
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        let mixAudioCMD = MVYFFmpegCMD.mixAudioCMD(withInputMajorAudioPath: inputMajorAudioPath, inputMinorAudioPath: inputMinorAudioPath, outputAudioPath: audioPath)
        NSLog("音频合并 \(mixAudioCMD!)")
        
        MVYFFmpegCMD.exec(mixAudioCMD) { (result) in
            
            NSLog("音频合并 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.mixAudioPath = audioPath
                    self.audioNextStepProcess()
                    
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "音量调节失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 音频下一步处理
    private func audioNextStepProcess() {
        if audioPaths.count > 0 {
            if concatOriginAudioPath == "" {
                concatOriginAudio(inputAudioPaths: audioPaths)
                return
            }
            
            if audioVolume != 1 {
                if volumeOriginAudioPath == "" {
                    setOriginAudioVolume(inputAudioPath: concatOriginAudioPath)
                    return
                }
            } else {
                volumeOriginAudioPath = concatOriginAudioPath
            }
        } else {
            if audioVolume != 1 {
                if volumeOriginAudioPath == "" {
                    setOriginAudioVolume(inputAudioPath: audioPaths[0])
                    return
                }
            } else {
                volumeOriginAudioPath = concatOriginAudioPath
            }
        }
        
        if musicPath != "" {
            if cutMusicPath == "" {
                cutMusic(inputAudioPath: musicPath)
                return
            }
            
            if musicVolume != 1 {
                if volumeMusicPath == "" {
                    setMusicVolume(inputAudioPath: cutMusicPath)
                    return
                }
            } else {
                volumeMusicPath = cutMusicPath
            }
            
            if mixAudioPath == "" {
                mixAudio(inputMajorAudioPath: volumeOriginAudioPath, inputMinorAudioPath: volumeMusicPath)
                return
            }
        } else {
            mixAudioPath = volumeOriginAudioPath
        }
        
        // 开始解码
        startDecodeVideo()
        startDecodeAudio()

        // 开始编码
        startEncode()
    }
    
}
