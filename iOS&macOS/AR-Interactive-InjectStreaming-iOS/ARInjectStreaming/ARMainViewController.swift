//
//  ARMainViewController.swift
//  ARInjectStreaming
//
//  Created by 余生丶 on 2020/10/15.
//

import UIKit
import ARtcKit

class ARMainViewController: UIViewController {
    
    @IBOutlet weak var roomNameTextField: UITextField!
    @IBOutlet weak var popoverSourceView: UIView!
       
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }
       
        switch segueId {

        case "mainToLive":
            roomNameTextField.resignFirstResponder()
            let liveVC = segue.destination as! ARLiveRoomViewController
            liveVC.roomName = roomNameTextField.text!
            if let value = sender as? NSNumber, let role = ARClientRole(rawValue: value.intValue) {
                liveVC.clientRole = role
            }
        default:
            break
        }
   }
    
    func showRoleSelection() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let broadcaster = UIAlertAction(title: "Broadcaster", style: .default) { [weak self] _ in
            self?.join(withRole: .broadcaster)
        }
        let audience = UIAlertAction(title: "Audience", style: .default) { [weak self] _ in
            self?.join(withRole: .audience)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        sheet.addAction(broadcaster)
        sheet.addAction(audience)
        sheet.addAction(cancel)
        sheet.popoverPresentationController?.sourceView = popoverSourceView
        sheet.popoverPresentationController?.permittedArrowDirections = .up
        present(sheet, animated: true, completion: nil)
    }
    
    func join(withRole role: ARClientRole) {
        performSegue(withIdentifier: "mainToLive", sender: NSNumber(value: role.rawValue as Int))
    }
}

extension ARMainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let string = textField.text , !string.isEmpty {
            showRoleSelection()
        }
        
        return true
    }
}
