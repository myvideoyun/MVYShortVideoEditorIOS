//
//  MVYImageTransitionViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/7/1.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import MBProgressHUD

enum MVYImageTransitionType {
    case LeftToRight
    case TopToBottom
    case ZoomIn
    case ZoomOut
    case RotateAndZoomIn
    case Transparent
}

class MVYImageTransitionViewController: UIViewController {

    private let contentView = MVYImageTransitionView()
    
    // 渲染器
    var imageRender = MVYImageEffectHandler.init(processTexture: false)
    
    // 当前渲染的位置
    var renderIndex = 0
    
    // 定时器
    var timer: Timer? = nil
    
    // 数据
    var textureModels = [MVYGPUImageTextureModel]()
    var images = [UIImage]()
    
    // 每张纹理显示多少帧
    let frameCountOfPreTexture = 60;
    
    // 当前转场特效
    var currentImageTransitionType: MVYImageTransitionType = .LeftToRight
    
    // 渲染锁
    var canRender = true
    let openGLLock = NSLock()
    
    // 录制
    var writer:MVYMediaWriter = MVYMediaWriter.sharedInstance()
    
    // 录制的总帧数
    var recordFrameCount = 0
    
    convenience init(images: [UIImage]) {
        self.init()
        
        self.images = images
        
        for image in images {
            let textureModel = MVYGPUImageTextureModel()
            textureModel.image = image
            self.textureModels.append(textureModel)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
        // 设置预览画面填充模式
        contentView.previewView.previewContentMode = .scaleAspectFit
        
        contentView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(enterForeground), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    @objc func enterForeground() {
        openGLLock.lock()
        
        canRender = true
        
        openGLLock.unlock()
    }
    
    @objc func enterBackground() {
        openGLLock.lock()
        
        contentView.previewView.releaseGLResources()
        canRender = false
        
        openGLLock.unlock()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 开始渲染
        timer = Timer.scheduledTimer(timeInterval: 0.033, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer?.invalidate()
    }
    
    @objc func timerHandler() {
        DispatchQueue.global().async {[weak self] in
            self?.render()
        }
    }

    // 定时渲染
    func render() {
        openGLLock.lock()
        
        if !canRender {
            return
        }
        
        imageRender?.setRenderTextures(processImageTransition())
        
        renderIndex = renderIndex + 1
        
        autoreleasepool { () -> () in
            
            let width = 720
            let height = 1280
            var pixelBuffer: CVPixelBuffer? = nil
            
            let bgraBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(width * height * 4), alignment: MemoryLayout<Int8>.alignment)
            
            imageRender?.process(withWidth: Int32(width), height: Int32(height), rotateMode:.noRotation, bgraBuffer: bgraBuffer)
            
            CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, bgraBuffer, Int(width * 4), {(releaseRefCon, baseAddress) in
                baseAddress?.deallocate()
            }, nil, nil, &pixelBuffer)
            
            if let pixelBuffer = pixelBuffer {
                contentView.previewView.previewRotationMode = .noRotation
                contentView.previewView.render(pixelBuffer)
            }
            
            pixelBuffer = nil
        }
        
        openGLLock.unlock()
    }
    
    // 生成视频
    func generateVideo() {
        
        // 设置音频处理方式
        let session = AVAudioSession.sharedInstance()
        if #available(iOS 10.0, *) {
            do {
                try session.setCategory(.record, mode: .default, options: AVAudioSession.CategoryOptions.mixWithOthers)
            } catch {
                
            }
        }
        
        try? session.setActive(true)
        
        let uuid = UUID().uuidString.filter { (c) -> Bool in return c != "-" }
        let videoFileName = "\(uuid).m4v"
        let audioFileName = "\(uuid).m4a"
        
        let videoPath = "\(NSTemporaryDirectory())\(videoFileName)"
        let audioPath = "\(NSTemporaryDirectory())\(audioFileName)"
        
        writer.outputVideoURL = URL.init(fileURLWithPath: videoPath)
        writer.outputAudioURL = URL.init(fileURLWithPath: audioPath)
        
        writer.videoFrameRate = 30
        writer.videoBitRate = 2048 * 1000
        writer.audioBitRate = 64000
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        DispatchQueue.global().async {
            
            self.openGLLock.lock()
            
            if !self.canRender {
                return
            }
            
            // 设置总帧数, 每张图片录制30帧
            self.recordFrameCount = self.frameCountOfPreTexture * self.textureModels.count
            
            self.renderIndex = 0
            
            while true {
                self.imageRender?.setRenderTextures(self.processImageTransition())

                // 写入视频数据
                autoreleasepool { () -> () in
                    
                    let width = 1280
                    let height = 720
                    var pixelBuffer: CVPixelBuffer? = nil
                    
                    let bgraBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(width * height * 4), alignment: MemoryLayout<Int8>.alignment)
                    
                    self.imageRender?.process(withWidth: Int32(width), height: Int32(height), rotateMode: .rotateRight, bgraBuffer: bgraBuffer)
                    
                    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(width), Int(height), kCVPixelFormatType_32BGRA, bgraBuffer, Int(width * 4), {(releaseRefCon, baseAddress) in
                        baseAddress?.deallocate()
                    }, nil, nil, &pixelBuffer)
                    
                    if let pixelBuffer = pixelBuffer {
                        self.writer.writeVideoPixelBuffer(pixelBuffer, time: CMTime.init(seconds: Double(self.renderIndex) * 33.333 / 1000.0, preferredTimescale: 1000000))
                    }
                    
                    pixelBuffer = nil
                }
                
                self.renderIndex = self.renderIndex + 1
                
                if self.renderIndex == self.recordFrameCount {
                    
                    // 录制完成
                    self.writer.finishWriting {[weak self] in
                        
                        DispatchQueue.main.async {
                            
                            if let view = self?.view {
                                MBProgressHUD.hide(for: view, animated: true)
                            }
                            
                            self?.enterEditViewController(videoPath: videoPath, audioPath: audioPath)
                        }
                    }
                    
                    break;
                }
                
                Thread.sleep(forTimeInterval: 0.001)
            }
            
            self.openGLLock.unlock()
        }
        
        DispatchQueue.global().async {
            
            // 设置总采样数, 每张图片录制30帧
            let recordSampleCount = Int(Double(self.frameCountOfPreTexture) / 30.0 * Double(self.textureModels.count) * 44100)
            
            for sampleIndex in stride(from: 0, to: recordSampleCount, by: 1024) {
                
                // 写入音频数据
                autoreleasepool { () -> () in
                    if let sampleBuffer:CMSampleBuffer = MVYMediaWriterTool.pcmData(toSampleBuffer: Data.init(count: 2048), pts: CMTime.init(seconds: Double(sampleIndex)/44100.0, preferredTimescale: 44100), duration: CMTime.init(seconds: 0.02321995, preferredTimescale: 44100))?.takeUnretainedValue() {
                        // 编码音频
                        self.writer.writeAudioSampleBuffer(sampleBuffer)
                    } else {
                        NSLog("音频编码失败")
                    }
                }
                
                Thread.sleep(forTimeInterval: 0.001)
            }
        }
    }
    
    // 处理转场
    func processImageTransition() -> [MVYGPUImageTextureModel] {
        switch currentImageTransitionType {
        case .LeftToRight:
            return MVYImageTransition.leftToRight(textures: textureModels, renderIndex: renderIndex, frameCountOfPreTexture: frameCountOfPreTexture)
        case .TopToBottom:
            return MVYImageTransition.topToBottom(textures: textureModels, renderIndex: renderIndex, frameCountOfPreTexture: frameCountOfPreTexture)
        case .ZoomIn:
            return MVYImageTransition.zoomIn(textures: textureModels, renderIndex: renderIndex, frameCountOfPreTexture: frameCountOfPreTexture)
        case .ZoomOut:
            return MVYImageTransition.zoomOut(textures: textureModels, renderIndex: renderIndex, frameCountOfPreTexture: frameCountOfPreTexture)
        case .RotateAndZoomIn:
            return MVYImageTransition.rotateAndZoomIn(textures: textureModels, renderIndex: renderIndex, frameCountOfPreTexture: frameCountOfPreTexture)
        case .Transparent:
            return MVYImageTransition.transparent(textures: textureModels, renderIndex: renderIndex, frameCountOfPreTexture: frameCountOfPreTexture)
        }
    }
    
    // 跳转到下个页面
    func enterEditViewController(videoPath: String, audioPath: String) {

        let vc = MVYEditViewController.init(videoPaths: [videoPath], audioPaths: [audioPath])
        
        if let viewControllers = self.navigationController?.viewControllers {
            var newViewControllers = viewControllers
            newViewControllers.removeLast()
            newViewControllers.append(vc)
            self.navigationController?.setViewControllers(newViewControllers, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: UI事件
extension MVYImageTransitionViewController: MVYImageTransitionViewDelegate {
    func pushToNextPage() {
        generateVideo()
    }
    
    func imageTransitionTypeChange(type: MVYImageTransitionType) {
        currentImageTransitionType = type
    }
}
