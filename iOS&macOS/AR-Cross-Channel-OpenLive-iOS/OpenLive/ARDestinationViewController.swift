//
//  ARDestinationViewController.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit

class ARDestinationViewController: UICollectionViewController {
    func updateLayout(_ layout: UICollectionViewFlowLayout) {
        collectionView?.setCollectionViewLayout(layout, animated: true)
    }
}

protocol ARDestinationViewDelegate: NSObjectProtocol {
    func destinationView(_ cell: ARDestinationView, willUpdate info: ARDestination)
}

class ARDestinationView: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var uidTextField: UITextField!
    @IBOutlet weak var tokenTextField: UITextField!
    @IBOutlet weak var channelTextField: UITextField!
    @IBOutlet weak var selectButton: UIButton!
    
    weak var delegate: ARDestinationViewDelegate?
    
    @IBAction func doSelectPressed(_ sender: UIButton) {
        sender.isSelected.toggle()
        let info = ARDestination(title: titleLabel.text!)
        info.uid = uidTextField.text ?? ""
        info.token = tokenTextField.text ?? ""
        info.channel = channelTextField.text ?? ""
        info.selected = sender.isSelected
        delegate?.destinationView(self, willUpdate: info)
    }
    
    func updateFrom(_ info: ARDestination) {
        titleLabel.text = info.title
        uidTextField.text = info.uid
        tokenTextField.text = info.token
        channelTextField.text = info.channel
        selectButton.isSelected = info.selected
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.adjustsFontSizeToFitWidth = true
        self.channelTextField.delegate = self
        self.tokenTextField.delegate = self
        self.uidTextField.delegate = self
    }
}

extension ARDestinationView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
        return true
    }
}

class ARDestination: NSObject {
    var title: String
    var uid: String = ""
    var token: String = ""
    var channel: String = ""
    var selected: Bool = false
    
    init(title: String) {
        self.title = title
    }
    
    func update(_ dic: [String: Any]) {
        if let title = dic["title"] as? String {
            self.title = title
        }
        
        if let uid = dic["uid"] as? String {
            self.uid = uid
        }
        
        if let token = dic["token"] as? String {
            self.token = token
        }
        
        if let channel = dic["channel"] as? String {
            self.channel = channel
        }
    }
    
    func dic() -> [String: Any] {
        return ["title": title, "uid": uid, "token": token, "channel": channel]
    }
    
    func isLegal() -> Bool {
        if selected == false {
            return true
        } else if selected == true && channel.count > 0 {
            return true
        } else {
            return false
        }
    }
    
    func isPrepareForMediaRelay() -> Bool {
        if selected == true, channel.count > 0 {
            return true
        } else {
            return false
        }
    }
}

