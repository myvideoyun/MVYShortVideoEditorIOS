//
//  MVYCoverViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/5/21.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import MBProgressHUD

typealias ConverPageEffectProcessBlock = (_ videoFrame: MVYVideoFrame) -> CVPixelBuffer?

class MVYCoverViewController: UIViewController {
    
    // 输入的视频
    var videoPaths = [String]()
    
    // 视频总长度
    var totalDuration:Double = 0
    
    // 预览UI
    private let preview = MVYPixelBufferPreview.init()
    
    // UI
    private let contentView = MVYCoverView()
    
    // 解码器
    private var videoSeeker:MVYVideoSeeker? = nil
    
    // 解码器工作类型
    var decoderWorkType = MVYDecoderWorkTypeModel()
    
    // 数据处理
    var effectProcessBlock: ConverPageEffectProcessBlock? = nil
    
    // 当前显示的图像
    var currentPixelBuffer: CVPixelBuffer? = nil
    
    convenience init(videoPaths:Array<String>, decoderWorkType:MVYDecoderWorkTypeModel, effectProcessBlock: @escaping ConverPageEffectProcessBlock) {
        self.init()
        
        self.videoPaths = videoPaths
        self.decoderWorkType = decoderWorkType
        self.effectProcessBlock = effectProcessBlock
        
        for videoPath in videoPaths {
            let asset = AVURLAsset.init(url: URL.init(fileURLWithPath: videoPath))
            totalDuration = totalDuration + asset.duration.seconds * 1000
        }
        
        videoSeeker = MVYVideoSeeker.init(paths: videoPaths)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = UIColor.black
        
        contentView.slider.maximumValue = Float(totalDuration)
        contentView.slider.addTarget(self, action: #selector(onSliderValueChange(_ :)), for: .valueChanged)
        contentView.completeBt.addTarget(self, action: #selector(onCompleteBtClick(_ :)), for: .touchUpInside)
        
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
        
        videoSeeker?.seekerDelegate = self
        
        // 显示第一帧
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            if self.decoderWorkType.type == .normal {
                self.videoSeeker?.setSeekTime(0)
            } else {
                self.videoSeeker?.setSeekTime(Int64(self.totalDuration))
            }
        }
    }

    @objc func onSliderValueChange(_ slider: UISlider) {
        
        var time = Double(slider.value)
        
        if decoderWorkType.type == .reverse {
            time = totalDuration - time
        }
        
        videoSeeker?.setSeekTime(Int64(time))
    }
    
    @objc func onCompleteBtClick(_ button: UIButton) {
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        if let pixelBuffer = currentPixelBuffer {
            let ciImage = CIImage.init(cvImageBuffer: pixelBuffer)
            
            if let filter = CIFilter.init(name: "CIAffineTransform") {
                
                var transform = CGAffineTransform(rotationAngle:CGFloat(-Double.pi/2))

                transform = transform.scaledBy(x: 1, y: -1)
                
                filter.setValue(transform, forKey: kCIInputTransformKey)
                
                filter.setValue(ciImage, forKey: kCIInputImageKey)
                
                if let ciImage = filter.value(forKey: kCIOutputImageKey) as? CIImage {
                    
                    let context = CIContext.init()
                    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                        
                        let image = UIImage.init(cgImage: cgImage)
                        
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    }
                }
            }
        }
        
        MBProgressHUD.hide(for: self.view, animated: true)

        self.navigationController?.popViewController(animated: true)
    }
    
    deinit {
        NSLog("MVYCoverViewController deinit");
    }
}

extension MVYCoverViewController: MVYVideoSeekerDelegate {
    func seekerOutput(with videoFrame: MVYVideoFrame!) {
        
        if decoderWorkType.type == .reverse {
            videoFrame.pts = videoFrame.length - videoFrame.pts - videoFrame.duration
            videoFrame.globalPts = videoFrame.globalLength - videoFrame.globalPts - videoFrame.duration
        }
        
        NSLog("videoFrame.pts \(videoFrame.pts)")
        
        if let effectProcessBlock = self.effectProcessBlock {
            if let pixelBuffer = effectProcessBlock(videoFrame) {
                if (videoFrame.rotate == 90) {
                    preview.previewRotationMode = .rotateLeft
                }
                preview.previewContentMode = .scaleAspectFit
                preview.render(pixelBuffer)
                
                currentPixelBuffer = pixelBuffer
            }
        }
    }
}
