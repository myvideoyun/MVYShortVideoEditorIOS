//
//  MVYImageTransition.swift
//  MVYShortVideoEditorIOS
//
//  Created by myvideoyun on 2019/7/1.
//  Copyright © 2019 myvideoyun. All rights reserved.
//

import UIKit

class MVYImageTransition: NSObject {

    // 计算从左到右转场效果
    class func leftToRight(textures: [MVYGPUImageTextureModel], renderIndex: Int, frameCountOfPreTexture: Int) -> [MVYGPUImageTextureModel] {
        
        var renderTexture = [MVYGPUImageTextureModel]()
        
        let processCount = frameCountOfPreTexture / 2;
        
        // 当前帧
        let currentIndex = renderIndex / frameCountOfPreTexture % textures.count
        let textureModel = textures[currentIndex]
        textureModel.transformMatrix = CATransform3DIdentity
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            textureModel.transformMatrix = CATransform3DMakeTranslation(CGFloat(2.0 - (Double(renderIndex % frameCountOfPreTexture) / Double(processCount)) * 2.0), 0, 0)
        }
        textureModel.transparent = 1

        // 上一帧
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            let previousIndex = currentIndex - 1;

            let textureModel2 = textures[previousIndex]
            textureModel2.transformMatrix = CATransform3DMakeTranslation(CGFloat(0.0 - (Double(renderIndex % frameCountOfPreTexture) / Double(processCount)) * 2.0), 0, 0)
            textureModel2.transparent = 1
            renderTexture.append(textureModel2)
        }

        renderTexture.append(textureModel)

        return renderTexture
    }
    
    // 计算从上到下转场效果
    class func topToBottom(textures: [MVYGPUImageTextureModel], renderIndex: Int, frameCountOfPreTexture: Int) -> [MVYGPUImageTextureModel] {
        
        var renderTexture = [MVYGPUImageTextureModel]()

        let processCount = frameCountOfPreTexture / 2;
        
        // 当前帧
        let currentIndex = renderIndex / frameCountOfPreTexture % textures.count
        let textureModel = textures[currentIndex]
        textureModel.transformMatrix = CATransform3DIdentity
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            textureModel.transformMatrix = CATransform3DMakeTranslation(0, CGFloat(Double(renderIndex % frameCountOfPreTexture) / Double(processCount) * 3.4 - 3.4), 0)
        }
        textureModel.transparent = 1

        // 上一帧
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            let previousIndex = currentIndex - 1
            
            let textureModel2 = textures[previousIndex]
            textureModel2.transformMatrix = CATransform3DMakeTranslation(0, CGFloat(Double(renderIndex % frameCountOfPreTexture) / Double(processCount) * 3.4), 0)
            textureModel2.transparent = 1
            renderTexture.append(textureModel2)
        }
        
        renderTexture.append(textureModel)
        
        return renderTexture
    }

    // 计算放大转场效果
    class func zoomOut(textures: [MVYGPUImageTextureModel], renderIndex: Int, frameCountOfPreTexture: Int) -> [MVYGPUImageTextureModel] {
        
        var renderTexture = [MVYGPUImageTextureModel]()
        
        // 当前帧
        let currentIndex = renderIndex / frameCountOfPreTexture % textures.count
        let textureModel = textures[currentIndex]
        textureModel.transformMatrix = CATransform3DMakeScale(CGFloat(Double(renderIndex % frameCountOfPreTexture) / Double(frameCountOfPreTexture) * 0.5 + 1.0), CGFloat(Double(renderIndex % frameCountOfPreTexture) / Double(frameCountOfPreTexture) * 0.5 + 1.0), 1)
        textureModel.transparent = 1

        renderTexture.append(textureModel)

        return renderTexture
    }

    // 计算缩小转场效果
    class func zoomIn(textures: [MVYGPUImageTextureModel], renderIndex: Int, frameCountOfPreTexture: Int) -> [MVYGPUImageTextureModel] {
        
        var renderTexture = [MVYGPUImageTextureModel]()

        // 当前帧
        let currentIndex = renderIndex / frameCountOfPreTexture % textures.count
        let textureModel = textures[currentIndex]
        textureModel.transformMatrix = CATransform3DMakeScale(CGFloat(1.5 - Double(renderIndex % frameCountOfPreTexture) / Double(frameCountOfPreTexture) * 0.5), CGFloat(1.5 - Double(renderIndex % frameCountOfPreTexture) / Double(frameCountOfPreTexture) * 0.5), 1)
        textureModel.transparent = 1
        
        renderTexture.append(textureModel)
        
        return renderTexture
    }
    
    // 计算旋转同时缩小转场效果
    class func rotateAndZoomIn(textures: [MVYGPUImageTextureModel], renderIndex: Int, frameCountOfPreTexture: Int) -> [MVYGPUImageTextureModel] {
        
        var renderTexture = [MVYGPUImageTextureModel]()
        
        let processCount = frameCountOfPreTexture / 2;
        
        // 当前帧
        let currentIndex = renderIndex / frameCountOfPreTexture % textures.count
        let textureModel = textures[currentIndex]
        textureModel.transformMatrix = CATransform3DIdentity
        textureModel.transparent = 1
        renderTexture.append(textureModel)
        
        // 上一帧
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            let previousIndex = currentIndex - 1
            
            let textureModel2 = textures[previousIndex]
            textureModel2.transformMatrix = CATransform3DMakeScale(CGFloat(1.0 - Double(renderIndex % processCount) / Double(processCount)), CGFloat(1.0 - Double(renderIndex % processCount) / Double(processCount)), 0)
            textureModel2.transformMatrix = CATransform3DRotate(textureModel2.transformMatrix, CGFloat(Double(renderIndex % processCount) / Double(processCount) * 2 * Double.pi), 0, 0, 1)
            textureModel2.transparent = 1
            renderTexture.append(textureModel2)
        }
        
        return renderTexture
    }
    
    // 过渡
    class func transparent(textures: [MVYGPUImageTextureModel], renderIndex: Int, frameCountOfPreTexture: Int) -> [MVYGPUImageTextureModel] {
        
        var renderTexture = [MVYGPUImageTextureModel]()
        
        let processCount = frameCountOfPreTexture / 2;
        
        // 当前帧
        let currentIndex = renderIndex / frameCountOfPreTexture % textures.count
        let textureModel = textures[currentIndex]
        textureModel.transformMatrix = CATransform3DIdentity
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            textureModel.transparent = CGFloat(Double(renderIndex % frameCountOfPreTexture) / Double(processCount))
        } else {
            textureModel.transparent = 1
        }
        
        // 上一帧
        if renderIndex % frameCountOfPreTexture < processCount && currentIndex > 0 {
            let previousIndex = currentIndex - 1
            let textureModel2 = textures[previousIndex]
            textureModel2.transformMatrix = CATransform3DIdentity
            textureModel2.transparent = 1
            renderTexture.append(textureModel2)
        }
        
        renderTexture.append(textureModel)
        
        return renderTexture
    }
}
