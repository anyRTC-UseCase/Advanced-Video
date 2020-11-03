//
//  ARBaseViewController.swift
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

import UIKit

class ARBaseViewController: UIViewController {
    var configs: [String:Any] = [:]
    override func viewDidLoad() {
        ARLogUtils.removeAll()
    }
    
    @objc func showLog() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "LogViewController")
        self.present(newViewController, animated: true, completion: nil)
    }
    
    func showAlert(title: String? = nil, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func getAudioLabel(uid:UInt, isLocal:Bool) -> String {
        return "AUDIO ONLY\n\(isLocal ? "Local" : "Remote")\n\(uid)"
    }
}
