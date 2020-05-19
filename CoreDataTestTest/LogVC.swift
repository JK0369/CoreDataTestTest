//
//  LogVC.swift
//  CoreDataTest
//
//  Created by 김종권 on 2020/05/19.
//  Copyright © 2020 imustang. All rights reserved.
//


import UIKit
import CoreData

// LogVC.swift
class LogVC: UITableViewController {
    var board: BoardMO!
    
    lazy var list: [LogMO]! = {
        return self.board.logs?.array as! [LogMO]
    }()
    
    override func viewDidLoad() {
        self.navigationItem.title = self.board.title
    }
}

// table view delegate
extension LogVC {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = self.list[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "logcell")!
        cell.textLabel?.text = "\(row.regdate!)에 \(row.type.toLogType())되었습니다." /// toLogType은 extension Int16으로 따로 문자열 정보가 나오게끔 정의한 것
        cell.textLabel?.font = .systemFont(ofSize: 12)
        
        return cell
    }
    
}

public enum LogType: Int16 {
    case create = 0
    case edit = 1
    case delete = 2
}

extension Int16 {
    func toLogType() -> String {
        switch self {
        case 0: return "생성"
        case 1: return "수정"
        case 2: return "삭제"
        default: return ""
        }
    }
}
