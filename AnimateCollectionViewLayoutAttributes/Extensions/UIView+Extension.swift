//
//  UIView+Extension.swift
//  AnimateCollectionViewLayoutAttributes
//
//  Created by Mehrooz Khan on 02/02/2022.
//

import UIKit

let toolbarHeight: CGFloat = 100

extension UIView {
    static var aboveSafeArea: CGFloat {
        let (top, _) = getSafeAreaInsets()
        return top
    }
    
    static var belowSafeArea: CGFloat {
        let (_, bottom) = getSafeAreaInsets()
        return bottom
    }
    
    static var viewToolbarHeight: CGFloat  {
        return belowSafeArea + toolbarHeight
    }
    
    static func getSafeAreaInsets() -> (CGFloat, CGFloat)  {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.first
            let topPadding = window?.safeAreaInsets.top ?? 40
            let bottomPadding = window?.safeAreaInsets.bottom ?? 20
            return (topPadding, bottomPadding)
        }
        else {
            let window = UIApplication.shared.keyWindow
            let topPadding = window?.safeAreaInsets.top ?? 40
            let bottomPadding = window?.safeAreaInsets.bottom ?? 20
            return (topPadding,bottomPadding)
        }
    }
}
