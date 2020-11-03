//
//  ViewController.swift
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

import UIKit

class ViewController: ARBaseViewController {

    @IBOutlet weak var channelTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else {
            return
        }
        
        if identifier == "RawMediaDataIdentifier",
            let mediaVc = segue.destination as? RawMediaDataMain {
            guard let channelName = channelTextField.text else {return}
            //resign channel text field
            channelTextField.resignFirstResponder()
            mediaVc.title = channelName
            mediaVc.configs = ["channelName":channelName]
        }
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if channelTextField.text?.count == 0 {
            self.showAlert(title: "Error", message: "Please enter channel name")
            return false
        }
        return true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
}

