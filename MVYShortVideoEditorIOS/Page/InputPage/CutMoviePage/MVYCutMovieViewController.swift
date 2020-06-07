//
//  MVYCutMovieViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/5.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import SnapKit
import MBProgressHUD

// 裁剪影音数据
class MVYCutMovieViewController: UIViewController, RangeSeekSliderDelegate, MVYVideoPlayerDelegate {
    
    var mediaURL:URL? = nil
    
    private let cutMediaPath = NSTemporaryDirectory() + "cut.mp4"
    private let separateVideoPath = NSTemporaryDirectory() + "separate.mp4"
    private let separateAudioPath = NSTemporaryDirectory() + "separate.wav"
    
    private let contentView = MVYCutMovieView()
    
    private var totalVideoLength:Double = 0
    
    private let effectHandler = MVYVideoEffectHandler.init(processTexture: false)
    private var videoPlayer: MVYVideoPlayer? = nil
    
    private var startTime:Double = 0
    private var endTime:Double = 0
    
    convenience init(mediaURL:URL) {
        self.init()
        
        self.mediaURL = mediaURL
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.addSubview(contentView)
        
        contentView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalTo(self.topLayoutGuide.snp.bottom)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
        
        // UI监听
        contentView.seekSlider.delegate = self
        contentView.nextBt.addTarget(self, action: #selector(onNextBtClick), for: .touchUpInside)
        
        // 设置预览画面填充模式
        contentView.previewView.previewContentMode = .scaleAspectFit
        
        // 创建播放器
        self.videoPlayer = MVYVideoPlayer.init(paths: [self.mediaURL!.path])
        self.videoPlayer?.playerDelegate = self
        
        // 视频总长度
        let sourceAsset = AVURLAsset (url: self.mediaURL!)
        totalVideoLength = sourceAsset.duration.seconds
        
        startTime = 0
        endTime = totalVideoLength * 1000
        
        // 截取的视频不能少于2秒
        contentView.seekSlider.minDistance = CGFloat(2 / totalVideoLength * 100)
        
        NotificationCenter.default.addObserver(self, selector: #selector(enterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        videoPlayer?.startPlay(withSeekTime: Int64(startTime))
    }
    
    @objc func enterBackground() {
        videoPlayer?.stopPlay()
        
        contentView.previewView.releaseGLResources()
    }
    
    @objc func onNextBtClick() {
        videoPlayer?.stopPlay()
        
        // 删除已经存在的文件
        try? FileManager.default.removeItem(atPath: cutMediaPath)
        try? FileManager.default.removeItem(atPath: separateVideoPath)
        try? FileManager.default.removeItem(atPath: separateAudioPath)

        MBProgressHUD.showAdded(to: self.view, animated: true)
        cutMedia()
    }
    
    // 截取视频
    private func cutMedia() {
        
        let cmd = MVYFFmpegCMD.cutVideoCMD(withStartPointTime: MVYFFmpegCMD.getMMSSFromSS("\(startTime / 1000)"), needDuration: MVYFFmpegCMD.getMMSSFromSS("\((endTime - startTime) / 1000)"), inputMediaPath: "\(self.mediaURL!.path)", outputMediaPath: cutMediaPath)
        
        NSLog("截取视频 \(cmd!)")
        
        MVYFFmpegCMD.exec(cmd) { (result) in
            
            NSLog("截取视频 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.separateVideo()
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    self.present(UIAlertController.init(title: "错误", message: "裁剪视频失败", preferredStyle: .alert), animated: true, completion: nil)
                }
            }
        }
    }
    
    // 分离视频
    private func separateVideo() {

        let separateVideoCMD = MVYFFmpegCMD.separateVideoCMD(withInputMediaPath: cutMediaPath, outputVideoPath: separateVideoPath)
        
        NSLog("分离视频 \(separateVideoCMD!)")
        
        MVYFFmpegCMD.exec(separateVideoCMD) { (result) in
            
            NSLog("分离视频 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if result == 0 {
                    self.separateAudio()
                } else {
                    MBProgressHUD.hide(for: self.view, animated: true)
                    let alert = UIAlertController.init(title: "错误", message: "分离视频失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: { (action) in
                        self.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 分离音频
    private func separateAudio() {
        
        let separateAudioCMD = MVYFFmpegCMD.separateAudioCMD(withInputMediaPath: cutMediaPath, outputAudioPath: separateAudioPath)
        
        NSLog("分离音频 \(separateAudioCMD!)")
        
        MVYFFmpegCMD.exec(separateAudioCMD) { (result) in
            
            NSLog("分离音频 执行结果%d", result)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                MBProgressHUD.hide(for: self.view, animated: true)

                if result == 0 {
                    self.enterNextPate()
                } else {
                    let alert = UIAlertController.init(title: "错误", message: "分离音频失败", preferredStyle: .alert)
                    alert.addAction(UIAlertAction.init(title: "取消", style: .cancel, handler: {[weak self] (action) in
                        self?.dismiss(animated: true , completion: nil)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    // 跳转到下一个页面
    private func enterNextPate() {
        let vc = MVYEditViewController.init(videoPaths: [separateVideoPath], audioPaths: [separateAudioPath])
        
        if let viewControllers = self.navigationController?.viewControllers {
            var newViewControllers = viewControllers
            newViewControllers.removeLast()
            newViewControllers.append(vc)
            self.navigationController?.setViewControllers(newViewControllers, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }        
    }

    // MARK: RangeSeekSliderDelegate
    func didStartTouches(in slider: RangeSeekSlider) {
        videoPlayer?.stopPlay()
    }
    
    func didEndTouches(in slider: RangeSeekSlider) {
        startTime = Double(slider.selectedMinValue) / Double(slider.maxValue) * Double(totalVideoLength) * 1000.0
        endTime = Double(slider.selectedMaxValue) / Double(slider.maxValue) * Double(totalVideoLength) * 1000.0

        videoPlayer?.startPlay(withSeekTime: Int64(startTime))
    }
    
    // MARK: MVYVideoPlayerDelegate
    func videoPlayerOutput(with frame: MVYVideoFrame!) {
        guard (frame != nil) else { return }
        
        if frame.globalPts > Int64(self.endTime) {
            DispatchQueue.main.async {
                self.videoPlayer?.stopPlay()
            }
        }
                
        var pixelBuffer: CVPixelBuffer? = nil
                
        let bgraBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(frame!.lineSize * frame!.height * 4), alignment: MemoryLayout<Int8>.alignment)

        effectHandler?.process(withYBuffer: frame.yData, uBuffer: frame.uData, vBuffer: frame.vData, width: frame.lineSize, height: frame.height, bgraBuffer: bgraBuffer)
        
        CVPixelBufferCreateWithBytes(kCFAllocatorDefault, Int(frame!.width), Int(frame!.height), kCVPixelFormatType_32BGRA, bgraBuffer, Int(frame!.lineSize * 4), {(releaseRefCon, baseAddress) in
            baseAddress?.deallocate()
        }, nil, nil, &pixelBuffer)
        
        if frame.rotate == 0 {
            contentView.previewView.previewRotationMode = .noRotation

        } else if frame.rotate == 90 {
            contentView.previewView.previewRotationMode = .rotateLeft
            
        } else if frame.rotate == 180 {
            contentView.previewView.previewRotationMode = .rotate180
            
        } else if frame.rotate == 270 {
            contentView.previewView.previewRotationMode = .rotateRight
        }
        
        contentView.previewView.render(pixelBuffer)
    }
        
    deinit {
        self.videoPlayer?.stopPlay()
        
        self.videoPlayer = nil
        
        NotificationCenter.default.removeObserver(self)
        
        NSLog("MVYCutMovieViewController deinit");
    }
}
