//
//  ARVideoResolutionViewController.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit

struct ARVideoConfig {
    var width: Double
    var height: Double
    var frameRate: Int
    var bitrate: Int
    
    init(width: Double, height: Double, frameRate: Int, bitrate: Int) {
        self.width = width
        self.height = height
        self.bitrate = bitrate
        self.frameRate = frameRate
    }
}

protocol ARVideoResolutionVCDelegate: NSObjectProtocol {
    func videoResolutionSelected(_ config: ARVideoConfig)
    func vdeoResolutionCancelSelected()
}

class ARVideoResolutionViewController: UIViewController {

    @IBOutlet weak var widthTextField: UITextField!
    @IBOutlet weak var heightTextField: UITextField!
    @IBOutlet weak var frameRateTextField: UITextField!
    @IBOutlet weak var bitrateTextField: UITextField!
    
    weak var delegate: ARVideoResolutionVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        read()
    }

    @IBAction func doSurePressed(_ sender: UIButton) {
        let width = Double(widthTextField.text ?? "0")!
        let height = Double(heightTextField.text ?? "0")!
        let frameRate = Int(frameRateTextField.text ?? "0")!
        let bitrate = Int(bitrateTextField.text ?? "0")!
        
        let config = ARVideoConfig(width: width, height: height, frameRate: frameRate, bitrate: bitrate)
        
        delegate?.videoResolutionSelected(config)
        write()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doCancelPressed(_ sender: UIButton) {
        delegate?.vdeoResolutionCancelSelected()
        
        dismiss(animated: true, completion: nil)
    }
    
    func read() {
        widthTextField.text = ARDefaultValue.getStringValueFor(key: "widthTextField")
        heightTextField.text = ARDefaultValue.getStringValueFor(key: "heightTextField")
        frameRateTextField.text = ARDefaultValue.getStringValueFor(key: "frameRateTextField")
        bitrateTextField.text = ARDefaultValue.getStringValueFor(key: "bitrateTextField")
    }
    
    func write() {
        if let text = widthTextField.text, text.count > 0 {
            ARDefaultValue.setValue(text, key: "widthTextField")
        }
        
        if let text = heightTextField.text, text.count > 0 {
            ARDefaultValue.setValue(text, key: "heightTextField")
        }
        
        if let text = frameRateTextField.text, text.count > 0 {
            ARDefaultValue.setValue(text, key: "frameRateTextField")
        }
        
        if let text = bitrateTextField.text, text.count > 0 {
            ARDefaultValue.setValue(text, key: "bitrateTextField")
        }
    }
}
