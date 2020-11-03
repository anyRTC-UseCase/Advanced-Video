//
//  ARChatMessageViewController.swift
//  OpenLive
//
//  Created by 余生丶 on 2020/10/16.
//

import UIKit

class ARChatMessageViewController: UIViewController {
    @IBOutlet weak var messageTableView: UITableView!
    
    fileprivate var messageList = [ARMessage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messageTableView.rowHeight = UITableView.automaticDimension
        messageTableView.estimatedRowHeight = 24
    }
    
    func append(chat text: String) {
        let message = ARMessage(text: text, type: .chat)
        append(message: message)
    }
    
    func append(alert text: String) {
        let message = ARMessage(text: text, type: .alert)
        append(message: message)
    }
}

private extension ARChatMessageViewController {
    func append(message: ARMessage) {
        messageList.append(message)
        
        var deleted: ARMessage?
        if messageList.count > 20 {
            deleted = messageList.removeFirst()
        }
        
        updateMessageTable(with: deleted)
    }
    
    func updateMessageTable(with deleted: ARMessage?) {
        guard let tableView = messageTableView else {
            return
        }
        
        let insertIndexPath = IndexPath(row: messageList.count - 1, section: 0)
        
        tableView.beginUpdates()
        if deleted != nil {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        }
        tableView.insertRows(at: [insertIndexPath], with: .none)
        tableView.endUpdates()
        
        tableView.scrollToRow(at: insertIndexPath, at: .bottom, animated: false)
    }
}

extension ARChatMessageViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "messageCell", for: indexPath) as! ARChatMessageCell
        let message = messageList[(indexPath as NSIndexPath).row]
        cell.set(with: message)
        return cell
    }
}

