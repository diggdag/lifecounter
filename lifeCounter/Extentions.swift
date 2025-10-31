//
//  Extentions.swift
//  lifeCounter
//
//  Created by 倉知諒 on 2021/08/17.
//  Copyright © 2021 kurachi. All rights reserved.
//

import UIKit

extension UITraitCollection {

    public static var isDarkMode: Bool {
        if #available(iOS 13, *), current.userInterfaceStyle == .dark {
            return true
        }
        return false
    }

}
extension Notification.Name {
    static let appDidBecomeActive = Notification.Name("appDidBecomeActive")
}
