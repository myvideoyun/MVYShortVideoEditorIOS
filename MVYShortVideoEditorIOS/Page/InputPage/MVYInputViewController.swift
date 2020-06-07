//
//  MVYInputViewController.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/1/20.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit
import AVFoundation
import CoreServices
import TZImagePickerController

class MVYInputViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, TZImagePickerControllerDelegate {
    
    let contentView = MVYInputView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(contentView)
                
        MVYLicenseManager.initLicense(withAppKey: "jAwdRWLiAhQN3lJ2zfJv7YoZVZy+v0jlrtLK5NCc1eucuR6x4MXBTNEI3VoIH+0KQNj5hkHVu9o/H34rL9aIsA==") { (result) in
            NSLog("License初始化结束 \(result)")
        }
        
        contentView.snp.makeConstraints { (make) in
            make.edges.equalTo(0)
        }
        
        contentView.inputBt.addTarget(self, action: #selector(onInputBtClick(_ :)), for: .touchUpInside)
        contentView.inputImageBt.addTarget(self, action:  #selector(onInputImageBtClick(_ :)), for: .touchUpInside)
        contentView.recordBt.addTarget(self, action: #selector(onRecordBtClick(_ :)), for: .touchUpInside)
        
        // 请求相机 和 麦克风的权限
        AVCaptureDevice.requestAccess(for: .video) { (granted) in
            if granted {
                NSLog("相机权限请求成功")
            } else {
                NSLog("相机权限请求失败")
            }
        }
        
        AVCaptureDevice.requestAccess(for: .audio) { (granted) in
            if granted {
                NSLog("麦克风权限请求成功")
            } else {
                NSLog("麦克风权限请求成功")
            }
        }
    }
    
    @objc func onInputBtClick(_ button:UIButton) {

        //弹出图片控制器
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        imagePicker.allowsEditing = false
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let url = info[.mediaURL] as? URL {
            
            // 跳转到本地导入页面
            let vc = MVYCutMovieViewController.init(mediaURL: url)
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc func onInputImageBtClick(_ button:UIButton) {
        let vc = TZImagePickerController.init(maxImagesCount: 30, delegate: self)
        vc?.allowTakeVideo = false
        vc?.allowTakePicture = false
        self.present(vc!, animated: true, completion: nil)
    }
    
    // 添加了一组新图片
    func imagePickerController(_ picker: TZImagePickerController!, didFinishPickingPhotos photos: [UIImage]!, sourceAssets assets: [Any]!, isSelectOriginalPhoto: Bool) {
        let vc = MVYImageTransitionViewController.init(images: photos)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func onRecordBtClick(_ button:UIButton) {
        
        // 跳转到录制页面
        let vc = MVYRecordViewController()
        vc.resolution = self.contentView.resolution()
        vc.frameRate = self.contentView.frameRate()
        vc.videoBitrate = self.contentView.videoBitrate()
        vc.audioBitrate = self.contentView.audioBitrate()
        vc.screenRate = self.contentView.screenRate()
        navigationController?.pushViewController(vc, animated: true)
    }
}
