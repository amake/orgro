//
//  SceneDelegate.swift
//  Runner
//
//  Created by Aaron Madlon-Kay on 2026/08/29.
//


import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
    //  Workaround for iPadOS 26 window control collision
    //  https://github.com/flutter/flutter/issues/170461#issuecomment-4444200166
    @available(iOS 26.0, *)
    override func preferredWindowingControlStyle(for windowScene: UIWindowScene) -> UIWindowScene.WindowingControlStyle {
        return .minimal
    }
}
