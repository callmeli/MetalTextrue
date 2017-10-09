//
//  UIImage.swift
//  Demo
//
//  Created by mac on 2017/10/9.
//  Copyright © 2017年 com.cmcm. All rights reserved.
//

import Foundation
import UIKit
extension UIImage {
    class func scaleToSize(_ image: UIImage, size: CGSize)->UIImage {
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return scaledImage!
    }
}
