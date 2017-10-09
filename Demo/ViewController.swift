//
//  ViewController.swift
//  Demo
//
//  Created by mac on 2017/9/28.
//  Copyright © 2017年 com.cmcm. All rights reserved.
//

import UIKit
import QuartzCore
import MetalKit
class ViewController: UIViewController {
 
    var type: MTLTextureType!
    var texture: MTLTexture!
    var metalLayer: CAMetalLayer!
    var device:MTLDevice!
    var passDescriptor: MTLRenderPassDescriptor!
    var commandQueue: MTLCommandQueue!
    var vertexBuffer: MTLBuffer! = nil
//    1、原坐标
//    let vertexData:[Float] = [
//        //position      s, t
//        -1, -1, 0,  0, 0,
//        1, -1, 0,  1, 0,
//        1,  1, 0,  1, 1,
//        -1,  1, 0,  0, 1,
//        ]
//    2、解决倒置变换后的坐标
    let vertexData:[Float] = [
        //position      s, t
        -1, -1, 0,  0, 1,
        1, -1, 0,  1, 1,
        1,  1, 0,  1, 0,
        -1,  1, 0,  0, 0,
        ]
    let indices:[Int32] = [
        0, 1, 2,
        0, 2, 3
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        commandQueue = device.makeCommandQueue()
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        var drawableSize = self.view.bounds.size
        drawableSize.width *= self.view.contentScaleFactor
        drawableSize.height *= self.view.contentScaleFactor
        metalLayer?.drawableSize = drawableSize
        view.layer.addSublayer(metalLayer!)
        
//        1、转换坐标解决图片倒置
//        let loaded = loadIntoTextureWithDevice(device: device, name: "input", ext: "jpg")
//        if !loaded {
//            print("Failed to load texture")
//        }
//      2、直接修改st纹理坐标
        let image = UIImage(named: "input.jpg")?.cgImage
        let textureLoader = MTKTextureLoader(device: self.device)
        do {
           texture = try textureLoader.newTexture(cgImage: image!)
        } catch {
            print("Failed to load texture")
        }
 
        let libray = device.makeDefaultLibrary()
        let vertexShader = libray!.makeFunction(name: "texture_vertex")
        let fraShader = libray!.makeFunction(name: "texture_fragment")
        
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = vertexShader
        descriptor.fragmentFunction = fraShader
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        var pipeline:MTLRenderPipelineState! = nil
        do {
            try pipeline = device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            print("pipeline error")
        }
        
        let drawable = metalLayer.nextDrawable()
        passDescriptor =  MTLRenderPassDescriptor()
        passDescriptor.colorAttachments[0].texture = drawable?.texture
        passDescriptor.colorAttachments[0].loadAction = .clear
        passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 1.0)
      
        let indexBuffer = device!.makeBuffer(bytes: indices, length: indices.count * 4, options: MTLResourceOptions(rawValue: UInt(0)))
        indexBuffer!.label = "Indices"
        let count = vertexData.count * 4
        vertexBuffer = device?.makeBuffer(bytes: vertexData, length: count, options: MTLResourceOptions(rawValue: UInt(0)))
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderCommandEncoder = commandBuffer!.makeRenderCommandEncoder(descriptor: passDescriptor!)
        renderCommandEncoder?.setRenderPipelineState(pipeline)
        renderCommandEncoder!.setFragmentTexture(texture, index: 0)
        // 根据索引画图
        renderCommandEncoder!.setVertexBuffer(vertexBuffer!, offset: 0, index: 0)
        renderCommandEncoder!.drawIndexedPrimitives(type: .triangle, indexCount: indices.count, indexType: .uint32, indexBuffer: indexBuffer!, indexBufferOffset: 0)
        renderCommandEncoder!.endEncoding()
        // 保证新纹理会在绘制完成后立即出现
        commandBuffer!.present(drawable!)
        // 提交事务，把任务交给GPU
        commandBuffer!.commit()
    }
    
 
    // 在处理贴图上使用CGImage在CGContext上draw的方法来取得图像, 但是通过draw方法绘制的图像是上下颠倒的，可以通过UIImage的drawInRect函数，该函数内部能自动处理图片的正确方向，生成纹理
    func loadIntoTextureWithDevice(device: MTLDevice, name: String, ext: String) -> Bool {
        let path = Bundle.main.path(forResource: name, ofType: ext)
        if !(path != nil) {
            return false
        }
        let image = UIImage(contentsOfFile: path!)
        let width = (image?.cgImage)!.width
        let height = (image?.cgImage)!.height
        let dataSize = width * height * 4
        let data = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4 * width, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue);
        context?.draw((image?.cgImage)!, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        // 通过UIImage的drawInRect函数，该函数内部能自动处理图片的正确方向
        UIGraphicsPushContext(context!);
        image?.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let textDes = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: Int(width), height: Int(height), mipmapped: false)
        type = textDes.textureType
        texture = device.makeTexture(descriptor: textDes)
        if !(texture != nil) {
            return false
        }
        texture.replace(region: MTLRegionMake2D(0, 0, Int(width), Int(height)), mipmapLevel: 0, withBytes: context!.data!, bytesPerRow: width * 4)
        UIGraphicsPopContext()
        free(data)
        return true
    }
   
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    enum TextureError: Error {
        case UIImageCreationError
        case MTKTextureLoaderError
    }
    
    /*
     *  创建Metal纹理
     *  @param device 设备
     *  @param name   图片名称
     *  @retun MTLTexture 纹理
     */
    func makeTexture(device: MTLDevice, name: String) throws -> MTLTexture {
        guard let image = UIImage(named: name) else {
            throw TextureError.UIImageCreationError
        }
        // 处理后的图片是倒置，要先将其倒置过来才能显示出正图像, xiu将纹理坐标从左上角设置为(0,0)，这个
        let mirrorImage = UIImage(cgImage: (image.cgImage)!, scale: 1, orientation: UIImageOrientation.downMirrored)
        let scaledImage = UIImage.scaleToSize(mirrorImage, size: image.size)
        do {
            let textureLoader = MTKTextureLoader(device: device)
            // 异步加载
            // try textureLoader.newTexture(with: image.cgImage!, options: textureLoaderOption, completionHandler: { (<#MTLTexture?#>, <#Error?#>) in
            //
            //        })
            // 同步根据图片创建新的Metal纹理
            // Synchronously loads image data and creates a new Metal texturefrom a given bitmap image.
            return try textureLoader.newTexture(cgImage: scaledImage.cgImage!)
        }
    }
        
     
}

