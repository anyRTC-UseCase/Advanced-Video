//
//  ARVideoSession.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit
import ARtcKit

class ARVideoSession: NSObject {
    var uid: String = "0"
    var hostingView: UIView!
    var canvas: ARtcVideoCanvas!
    
    init(uid: String) {
        self.uid = uid
        hostingView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        canvas = ARtcVideoCanvas()
        canvas.uid = uid
        canvas.view = hostingView
        canvas.renderMode = .hidden
    }
}

extension ARVideoSession {
    static func localSession() -> ARVideoSession {
        return ARVideoSession(uid: "0")
    }
}
