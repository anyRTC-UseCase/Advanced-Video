//
//  ARChatMessageCell.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit

class ARChatMessageCell: UITableViewCell {

    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    func set(with message: ARMessage) {
        backgroundColor = UIColor.clear
        
        messageLabel.text = message.text
        colorView.backgroundColor = message.type.color()
    }
}
