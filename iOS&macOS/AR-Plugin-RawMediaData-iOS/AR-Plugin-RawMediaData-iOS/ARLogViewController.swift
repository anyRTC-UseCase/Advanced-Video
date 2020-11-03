//
//  ARLogViewController.swift
//  AR-Plugin-RawMediaData-iOS
//
//  Created by 余生丶 on 2020/10/22.
//

import UIKit

enum ARLogLevel {
    case info, warning, error
    
    var description: String {
        switch self {
        case .info:    return "Info"
        case .warning: return "Warning"
        case .error:   return "Error"
        }
    }
}

struct ARLogItem {
    var message:String
    var level: ARLogLevel
    var dateTime:Date
}

class ARLogUtils {
    static var logs:[ARLogItem] = []
    
    static func log(message: String, level: ARLogLevel) {
        ARLogUtils.logs.append(ARLogItem(message: message, level: level, dateTime: Date()))
        print("\(level.description): \(message)")
    }
    
    static func removeAll() {
        ARLogUtils.logs.removeAll()
    }
}

class ARLogViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension ARLogViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ARLogUtils.logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "logCell"
        var cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: cellIdentifier)
        }
        let logitem = ARLogUtils.logs[indexPath.row]
        cell?.textLabel?.font = UIFont.systemFont(ofSize: 12)
        cell?.textLabel?.numberOfLines = 0;
        cell?.textLabel?.lineBreakMode = .byWordWrapping;
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyy-MM-dd HH:mm:ss"
        cell?.textLabel?.text = "\(dateFormatterPrint.string(from: logitem.dateTime)) - \(logitem.level.description): \(logitem.message)"
        return cell!
    }
}
