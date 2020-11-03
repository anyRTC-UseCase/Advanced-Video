//
//  ARMainViewController.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit
import ARtcKit

let maxDestination = 4

class ARMainViewController: UIViewController {
    @IBOutlet weak var currentUidTextField: UITextField!
    @IBOutlet weak var currenChannelTextField: UITextField!
   
    @IBOutlet weak var sourceUidTextField: UITextField!
    @IBOutlet weak var sourceTokenTextField: UITextField!
    @IBOutlet weak var sourceChannelTextField: UITextField!
    
    var videoConfig: ARVideoConfig?
    
    weak var collectionView: UICollectionView?
    
    lazy var destinationList: [ARDestination] = {
        var list = [ARDestination]()
        
        for i in 0..<maxDestination {
            let item = ARDestination(title: "Destination \(i+1)")
            list.append(item)
        }
        
        return list
    }()
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueId = segue.identifier else {
            return
        }
        
        switch segueId {
        case "mainToLive":
            let liveVC = segue.destination as! ARLiveRoomViewController
            
            // Current
            liveVC.videoConfig = videoConfig
            
            if let currentUid = currentUidTextField.text {
                liveVC.currentUid = currentUid
                ARDefaultValue.setValue(currentUid, key: "currentUidTextField")
            } else {
                liveVC.currentUid = "0"
            }
            
            if let value = sender as? NSNumber, let role = ARClientRole(rawValue: value.intValue) {
                liveVC.clientRole = role
            }
            
            liveVC.currentChannel = currenChannelTextField.text!
            ARDefaultValue.setValue(liveVC.currentChannel as Any, key: "currenChannelTextField")
            
            // Source
            if let sourceToken = sourceTokenTextField.text,
                sourceToken.count > 0 {
                liveVC.sourceToken = sourceTokenTextField.text
                ARDefaultValue.setValue(sourceToken, key: "sourceTokenTextField")
            }
            
            if let sourceUid: String = sourceUidTextField.text,
                sourceUid.count > 0,
                let uid: String = sourceUid {
                liveVC.sourceUid = uid
                ARDefaultValue.setValue(sourceUid, key: "sourceUidTextField")
            }
            
            if let sourceChannel = sourceChannelTextField.text,
                sourceChannel.count > 0 {
                liveVC.sourceChannel = sourceChannel
                ARDefaultValue.setValue(sourceChannel, key: "sourceChannelTextField")
            }
            
            // Destinations
            liveVC.destinationList = destinationList
            
            var writeList = [[String: Any]]()
            
            for item in destinationList {
                let dic = item.dic()
                writeList.append(dic)
            }
            
            ARDefaultValue.setValue(writeList, key: "destinationList")
            
            liveVC.delegate = self
        case "mainToDestination":
            let destVC = segue.destination as! ARDestinationViewController
            destVC.collectionView?.dataSource = self
            destVC.updateLayout(updateCollectionView())
            self.collectionView = destVC.collectionView
        case "mainToVideoResolution":
            let resolutionVC = segue.destination as! ARVideoResolutionViewController
            resolutionVC.delegate = self
        default:
            break
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.endEditing(true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    override func viewDidLoad() {
        readFromARDefaultValue()
    }
    
    @IBAction func doJoinPressed(_ sender: UIButton) {
        if let channel = currenChannelTextField.text, channel.count <= 0 {
            alert("channel nil")
            return
        }
        
        if checkDestinationListIsLegal() {
            showRoleSelection()
        } else {
            alert("destination channel nil")
        }
    }
}

private extension ARMainViewController {
    func updateCollectionView() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        let screenWidth = UIScreen.main.bounds.width
        let width = (screenWidth - 48 - 32) * 0.5
        layout.itemSize = CGSize(width: width, height: 180)
        return layout
    }
    
    func readFromARDefaultValue() {
        currentUidTextField.text = ARDefaultValue.getStringValueFor(key: "currentUidTextField")
        currenChannelTextField.text = ARDefaultValue.getStringValueFor(key: "currenChannelTextField")
        
        sourceUidTextField.text = ARDefaultValue.getStringValueFor(key: "sourceUidTextField")
        sourceTokenTextField.text = ARDefaultValue.getStringValueFor(key: "sourceTokenTextField")
        sourceChannelTextField.text = ARDefaultValue.getStringValueFor(key: "sourceChannelTextField")
        
        // Destinations
        guard let list = ARDefaultValue.getDicListValueFor(key: "destinationList") else {
            return
        }
        
        for i in 0..<maxDestination {
            let dic = list[i]
            let item = destinationList[i]
            item.update(dic)
        }
    }
    
    func checkDestinationListIsLegal() -> Bool {
        var legal = true
        
        for item in destinationList {
            guard item.isLegal() == false else {
                continue
            }
            legal = false
            break
        }
        return legal
    }
    
    func showRoleSelection() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
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
        present(sheet, animated: true, completion: nil)
    }
    
    func alert(_ text: String) {
        let alert = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
}

private extension ARMainViewController {
    func join(withRole role: ARClientRole) {
        performSegue(withIdentifier: "mainToLive", sender: NSNumber(value: role.rawValue as Int))
    }
}

extension ARMainViewController: ARLiveRoomVCDelegate {
    func liveVCNeedClose(_ liveVC: ARLiveRoomViewController) {
        let _ = navigationController?.popViewController(animated: true)
    }
}

extension ARMainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return maxDestination
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DestinationView", for: indexPath) as! ARDestinationView
        cell.delegate = self
        let info = destinationList[indexPath.row]
        cell.updateFrom(info)
        return cell
    }
}

extension ARMainViewController: ARVideoResolutionVCDelegate {
    func videoResolutionSelected(_ config: ARVideoConfig) {
        self.videoConfig = config
    }
    
    func vdeoResolutionCancelSelected() {
        self.videoConfig = nil
    }
}

extension ARMainViewController: ARDestinationViewDelegate {
    func destinationView(_ cell: ARDestinationView, willUpdate info: ARDestination) {
        if let index = collectionView?.indexPath(for: cell) {
            destinationList[index.item] = info
        }
    }
}

extension ARMainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}

