//
//  ARPopView.swift
//  ARInjectStreaming
//
//  Created by 余生丶 on 2020/10/15.
//

import UIKit

@objc protocol ARPopViewDelegate: NSObjectProtocol {
    func popViewButtonDidPressed(_ popView: ARPopView)
    
    @objc optional func popViewDidRemoved(_ popView: ARPopView)
}

class ARPopView: UIView {

    @IBOutlet weak var inputTextField: UITextField!
    @IBOutlet weak var popViewButton: UIButton!
    
    weak var delegate: ARPopViewDelegate?
    
    static func newPopViewWith(buttonTitle: String, placeholder: String) -> ARPopView? {
        let nibView = Bundle.main.loadNibNamed("ARPopView", owner: nil, options: nil)
        if let view = nibView?.first as? ARPopView {
            let attDic = NSMutableDictionary()
            attDic[NSAttributedString.Key.foregroundColor] = UIColor.lightGray
            let attPlaceholder = NSAttributedString(string: placeholder, attributes: attDic as? [NSAttributedString.Key : Any])
            view.inputTextField.attributedPlaceholder = attPlaceholder
            view.popViewButton.setTitle(buttonTitle, for: .normal)
            return view
        }
        return nil
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func doCancelButton(_ sender: UIButton) {
        if delegate != nil {
            delegate?.popViewDidRemoved?(self)
        }
        self.removeFromSuperview()
    }
    
    @IBAction func doPopViewButtonPressed(_ sender: UIButton) {
        if delegate != nil {
            delegate?.popViewButtonDidPressed(self)
        }
    }
}
