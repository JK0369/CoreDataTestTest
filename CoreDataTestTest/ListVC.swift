//
//  ListVC.swift
//  CoreDataTest
//
//  Created by 김종권 on 2020/05/19.
//  Copyright © 2020 imustang. All rights reserved.
//


// ListVC.swift
import UIKit
import CoreData
class ListVC: UITableViewController {
    lazy var list: [NSManagedObject] = {
        return self.fetch()
    }()
    
    // read the data
    func fetch() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Board")
        
        // sort
        let sort = NSSortDescriptor(key: "regdate", ascending: false)
        fetchRequest.sortDescriptors = [sort]
        
        let result = try! context.fetch(fetchRequest)
        return result
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.list.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // 해당하는 데이터 가져옴
        let record = self.list[indexPath.row]
        // list배열 내부 타입은 NSManagedObject이기 때문에 원하는 적절한 캐스팅이 필요함
        let title = record.value(forKey: "title") as? String
        let contents = record.value(forKey: "contents") as? String
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = contents
        
        return cell
    }
    
    // ListVC.swift
    func save(title: String, contents: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // 관리 객체 생성
        let object = NSEntityDescription.insertNewObject(forEntityName: "Board", into: context)
        object.setValue(title, forKey: "title")
        object.setValue(contents, forKey: "contents")
        object.setValue(Date(), forKey: "regdate")
        
        // Log엔터티에 들어갈 관리 객체 생성
        let logObject = NSEntityDescription.insertNewObject(forEntityName: "Log", into: context) as! LogMO
        logObject.regdate = Date()
        logObject.type = LogType.create.rawValue /// LogType은 직접 정의한 enum타입
        
        // 1:M관계이므로, 다수의 로그를 하나의 board객체에 연결
        // baord객체 하위의 log속성에 로그 객체를 추가
        (object as! BoardMO).addToLogs(logObject) /// board에서 log로
        /// 또는 logObject.board = (object as! BoardMO)
        
        // 영구 저장소에 commit후에 list프로퍼티에 추가
        do{
            try context.save()
            self.list.insert(object, at: 0)
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    func delete(obejct: NSManagedObject) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        context.delete(obejct)
        
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    func update(object: NSManagedObject, title: String, contents: String) -> Bool {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        object.setValue(title, forKey: "title")
        object.setValue(contents, forKey: "contents")
        object.setValue(Date(), forKey: "regdate")
        
        // Log엔터티 객체 생성
        let logObject = NSEntityDescription.insertNewObject(forEntityName: "Log", into: context) as! LogMO
        logObject.regdate = Date()
        logObject.type = LogType.edit.rawValue
        
        // board객체에 log추가
        (object as! BoardMO).addToLogs(logObject)
        
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    // ListVC.swift
    @objc func add(_ sender: Any) {
        let alert = UIAlertController(title: "게시글 등록", message: nil, preferredStyle: .alert)
        
        alert.addTextField() {$0.placeholder = "제목"}
        alert.addTextField() {$0.placeholder = "내용"}
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) {(_) in
            guard let title = alert.textFields?.first?.text, let contents = alert.textFields?.last?.text else {return}
            
            if self.save(title: title, contents: contents) == true {self.tableView.reloadData()}
        })
        self.present(alert, animated: false)
    }
    
    
    override func viewDidLoad() {
        let addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(add(_:)))
        self.navigationItem.rightBarButtonItem = addBtn
    }
    
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        let object = self.list[indexPath.row] /// NSManagedObject객체
        if self.delete(obejct: object) { /// DB에서 삭제
            self.list.remove(at: indexPath.row) /// 데이터 삭제
            self.tableView.deleteRows(at: [indexPath], with: .fade) /// 테이블 뷰에서 해당 행을 fade방법으로 제거
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let object = self.list[indexPath.row]
        let title = object.value(forKey: "title") as? String
        let contents = object.value(forKey: "contents") as? String
        let alert = UIAlertController(title: "게시글 수정", message: nil, preferredStyle: .alert)
        
        alert.addTextField() {$0.text = title}
        alert.addTextField() {$0.text = contents}
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default){(_) in
            guard let title = alert.textFields?.first?.text,
                let contents = alert.textFields?.last?.text else {return}
            
            if self.update(object: object, title: title, contents: contents) == true {
                
                let cell = self.tableView.cellForRow(at: indexPath)
                cell?.textLabel?.text = title
                cell?.detailTextLabel?.text = contents
                
                let firstIndexPath = IndexPath(item: 0, section: 0)
                self.tableView.moveRow(at: indexPath, to: firstIndexPath)
            }
        })
        
        self.present(alert, animated: false)
    }
    
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        
        print("클릭")
        let object = self.list[indexPath.row]
        let uvc = self.storyboard?.instantiateViewController(identifier: "LogVC") as! LogVC
        uvc.board = object as! BoardMO
        self.show(uvc, sender: self)
    }
}
