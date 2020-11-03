//
//  ARMessage.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        func transform(_ input: Int, offset: Int = 0) -> CGFloat {
            let value = (input >> offset) & 0xff
            return CGFloat(value) / 255
        }
        
        self.init(red: transform(hex, offset: 16),
                  green: transform(hex, offset: 8),
                  blue: transform(hex),
                  alpha: alpha)
    }
}

enum ARMessageType {
    case chat, alert
    
    func color() -> UIColor {
        switch self {
        case .chat: return UIColor(hex: 0x444444, alpha: 0.6)
        case .alert: return UIColor(hex: 0xff3c32, alpha: 0.6)
        }
    }
}

struct ARMessage {
    var text: String!
    var type: ARMessageType = .chat
    
    init(text: String, type: ARMessageType) {
        self.text = text
        self.type = type
    }
}
