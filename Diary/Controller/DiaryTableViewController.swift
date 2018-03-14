//
//  DiaryTableViewController.swift
//  Diary
//
//  Created by 牛苒 on 2018/2/21.
//  Copyright © 2018年 牛苒. All rights reserved.
//

import UIKit
import CoreData
import CloudKit

class DiaryTableViewController: UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UIViewControllerPreviewingDelegate {
    
    var authView = UIView()
    var searchController: UISearchController?
    
    var searchResults: [DiaryMO] = []
    var notebook: NotebookMO!
    
    let monthArray = ["Jan.", "Feb.", "Mar.", "Apr.", "May.", "June.", "July.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]
    let weekArray = ["Sun.", "Mon.", "Tues.", "Wed.", "Thur.", "Fri.", "Sat."]
    
    var slideOutTransition = SlideOutTransitionAnimator()
    var activityController: UIActivityViewController? = nil
    
    @IBOutlet var emptyDiaryView: UIView!
    @IBOutlet var navTitle: UINavigationItem!
    
    @IBAction func unwindToHome(segue: UIStoryboardSegue) {
        dismiss(animated: true, completion: nil)
    }
    
    var fetchResultController: NSFetchedResultsController<DiaryMO>!
    var fetchNoteResultController: NSFetchedResultsController<NotebookMO>!
    var diaries:[DiaryMO] = []
    var notebooks:[NotebookMO] = []
    
    // Screen height.
    public var screenHeight: CGFloat {
        return UIScreen.main.bounds.height
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.forceTouchCapability == .available {
            registerForPreviewing(with: self, sourceView: view)
        }

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.hidesBarsOnSwipe = false
//
//        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
//        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)]
        
        // SearchBar
        searchController = UISearchController(searchResultsController: nil)
//        self.navigationItem.searchController = searchController
        tableView.tableHeaderView = searchController?.searchBar
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        
        searchController?.searchBar.placeholder = "Search from tags, title, content..."
        searchController?.searchBar.barTintColor = .white
        searchController?.searchBar.backgroundImage = UIImage()
        searchController?.searchBar.tintColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        
        // Prepare the empty view
        tableView.backgroundView = emptyDiaryView
        tableView.backgroundView?.isHidden = true
        tableView.tableFooterView = UIView()
        // Pull to refresh control
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("diary viewwillappear")
        if UserDefaults.standard.bool(forKey: "isOpenFaceID"){
            if UserDefaults.standard.bool(forKey: "isShouldAuth") {
                performSegue(withIdentifier: "showAuth", sender: self)
            }
        }
        
        navigationController?.hidesBarsOnSwipe = false
        if UserDefaults.standard.bool(forKey: "hasViewedWalkthrough") {
            // Fetch data from data store - Notebook
            let fetchNoteRequest: NSFetchRequest<NotebookMO> = NotebookMO.fetchRequest()
            let sortNoteDescriptor = NSSortDescriptor(key: "update", ascending: false)
            fetchNoteRequest.sortDescriptors = [sortNoteDescriptor]
            
            fetchNoteRequest.predicate = NSPredicate(format: "id == %d", UserDefaults.standard.integer(forKey: "defaultNoteBookId"))
            
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                fetchNoteResultController = NSFetchedResultsController(fetchRequest: fetchNoteRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                fetchNoteResultController.delegate = self
                
                do {
                    try fetchNoteResultController.performFetch()
                    if let fetchedObjects = fetchNoteResultController.fetchedObjects {
                        notebooks = fetchedObjects
                    }
                } catch {
                    print(error)
                }
            }
            
            if let navTitleString = notebooks[0].name {
                navTitle.title = navTitleString
            }
            
            // Fetch data from data store - Diary
            let fetchRequest: NSFetchRequest<DiaryMO> = DiaryMO.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "update", ascending: false)
            fetchRequest.sortDescriptors = [sortDescriptor]
            
            fetchRequest.predicate = NSPredicate(format: "notebookid == %d", UserDefaults.standard.integer(forKey: "defaultNoteBookId"))
            
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
                fetchResultController.delegate = self
                
                do {
                    try fetchResultController.performFetch()
                    if let fetchedObjects = fetchResultController.fetchedObjects {
                        diaries = fetchedObjects
                    }
                } catch {
                    print(error)
                }
            }
            self.tableView.reloadData()
        } else {
            // user first into the App, init the notebook with the "Diary" book
            UserDefaults.standard.set(1, forKey: "defaultNoteBookId")
            UserDefaults.standard.set(1, forKey: "maxNoteBookId")
            UserDefaults.standard.set(0, forKey: "maxDiaryId")
            UserDefaults.standard.set(Date.init(), forKey: "iCloudSync")
            UserDefaults.standard.set(false, forKey: "isOpenNotify")
            UserDefaults.standard.set(false, forKey: "isOpenFaceID")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat =  "HH:mm"
            dateFormatter.timeZone = TimeZone.current
            if let date = dateFormatter.date(from: "19:30") {
                print("date1:\(date)")
                UserDefaults.standard.set(date, forKey: "notifyEverydayTime")
            }
            let initTags:[String] = ["日记", "工作", "学习", "旅游", "生活", "备忘", "美食"]
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                notebook = NotebookMO(context: appDelegate.persistentContainer.viewContext)
                notebook.id = "1"
                notebook.name = "Diary"
                notebook.comment = "my diary"
                let currentDate = Date.init()
                notebook.create = currentDate
                notebook.update = currentDate
                if let notebookCoverImage = UIImage(named: "weather-background") {
                    notebook.coverimage = UIImagePNGRepresentation(notebookCoverImage)
                }
                
                for index in 0..<initTags.count {
                    let tagMO = TagMO(context: appDelegate.persistentContainer.viewContext)
                    tagMO.name = initTags[index]
                }
                
                print("Saving data to context")
                appDelegate.saveContext()
            }
            
            let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
            if let walkthroughViewController = storyboard.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
                present(walkthroughViewController, animated: true, completion: nil)
            }
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for changeType: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type(of: (anObject as! NSObject)) == type(of: DiaryMO()) {
            switch changeType {
            case .insert:
                if let newIndexPath = newIndexPath {
                    tableView.insertRows(at: [newIndexPath], with: .fade)
                }
            case .delete:
                if let indexPath = indexPath {
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
            case .update:
                if let indexPath = indexPath {
                    tableView.reloadRows(at: [indexPath], with: .fade)
                }
            default:
                tableView.reloadData()
            }
            
            if let fetchedObjects = controller.fetchedObjects {
                diaries = fetchedObjects as! [DiaryMO]
            }
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if diaries.count > 0 {
            tableView.backgroundView?.isHidden = true
//            tableView.separatorStyle = .singleLine
            searchController?.searchBar.isHidden = false
        } else {
            tableView.backgroundView?.isHidden = false
//            tableView.separatorStyle = .none
            searchController?.searchBar.isHidden = true
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if (searchController?.isActive)! {
            return searchResults.count
        } else {
            return diaries.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! DiaryTableViewCell

        let diary = (searchController?.isActive)! ? searchResults[indexPath.row] : diaries[indexPath.row]
        
        // Configure the cell...
        
        cell.titleLabel.text = diary.title
        if let diaryImage = diary.image {
            cell.thumbnailImageView.image = UIImage(data: diaryImage)
            cell.contentLabel.isHidden = true
            if cell.contentLargeUILabel.frame.width > 100 {
                cell.contentLargeUILabel.isHidden = false
                cell.contentLargeUILabel.text = diary.content!
            }
        } else {
            cell.thumbnailImageView.image = UIImage()
            if cell.contentLargeUILabel.frame.width > 100 {
                cell.contentLabel.isHidden = true
                cell.contentLargeUILabel.isHidden = false
                cell.contentLargeUILabel.text = diary.content!
            } else {
                cell.contentLargeUILabel.isHidden = true
                cell.contentLabel.isHidden = false
                cell.contentLabel.text = diary.content!
            }
        }
        cell.weatherImageView.image = UIImage(named: diary.weather!)
        
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        cell.weekLabel.text = weekArray[Calendar.current.component(.weekday, from: diary.create!) - 1]
        
        cell.monthLabel.text = monthArray[Calendar.current.component(.month, from: diary.create!) - 1]
        dateFormatter.dateFormat = "d"
        cell.dayLabel.text = dateFormatter.string(from: diary.create!)
        cell.dateLabel.text = getFriendlyTime(date: diary.update!)
        cell.tagLabel.text = diary.tag
        return cell
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Delete the row from the data source
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: { (action, sourceView, completionHandler) in
            // Fetch and delete the record from the iCloud
            let diary = self.diaries[indexPath.row]
            let privateDatabase = CKContainer.default().privateCloudDatabase
            print("recordName: \(diary.recordName!)")
            if let recordName = diary.recordName {
                let recordID = CKRecordID(recordName: recordName)
                privateDatabase.fetch(withRecordID: recordID, completionHandler: { (record, error) in
                    if let error = error {
                        // Error handling for failed fetch from public database
                        print("DetailView updateRecordToCloud():\(error.localizedDescription)")
                    }
                    if let record = record {
                        privateDatabase.delete(withRecordID: record.recordID, completionHandler: { (recordID, error) in
                            // Error handling for failed delete to private database
                            if let error = error {
                                print(error.localizedDescription)
                            }
                        })
                    }
                })
                
            }
            
            // delete in database
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                let diaryToDelete = self.fetchResultController.object(at: indexPath)
                context.delete(diaryToDelete)
                
                appDelegate.saveContext()
            }
            
            completionHandler(true)
        })
        
        let shareAction = UIContextualAction(style: .normal, title: "Share", handler: { (action, sourceView, completionHandler) in
            let defaultTitle = self.diaries[indexPath.row].title!
            let defaultContent = self.diaries[indexPath.row].content!
            
            if let imageToShare = UIImage(data: self.diaries[indexPath.row].image!) {
                self.activityController = UIActivityViewController(activityItems: [defaultTitle, imageToShare, defaultContent], applicationActivities: nil)
            } else {
                self.activityController = UIActivityViewController(activityItems: [defaultTitle, defaultContent], applicationActivities: nil)
            }
            
//            if let popoverController = activityController.popoverPresentationController {
//                if let cell = tableView.cellForRow(at: indexPath) {
//                    popoverController.sourceView = cell
//                    popoverController.sourceRect = cell.bounds
//                }
//            }
            
            self.present(self.activityController!, animated: true, completion: nil)

            self.activityController?.completionWithItemsHandler = {
                (activity, success, items, error) in
                if success {
                    switch activity!._rawValue {
                    case "com.apple.UIKit.activity.SaveToCameraRoll":
                        let alertController = UIAlertController(title: "成功保存到相册!",
                                                                message: nil, preferredStyle: .alert)
                        //显示提示框
                        self.present(alertController, animated: true, completion: nil)
                        //两秒钟后自动消失
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                            self.presentedViewController?.dismiss(animated: false, completion: nil)
                        }
//                        print("成功保存到相册！")
                    case "com.apple.UIKit.activity.CopyToPasteboard":
//                        print("成功复制到剪贴板！")
                        let alertController = UIAlertController(title: "成功复制到剪贴板!",
                                                                message: nil, preferredStyle: .alert)
                        //显示提示框
                        self.present(alertController, animated: true, completion: nil)
                        //两秒钟后自动消失
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                            self.presentedViewController?.dismiss(animated: false, completion: nil)
                        }
                    default:
                        break
                    }
                }
            }
            completionHandler(true)
            
        })
        
        deleteAction.backgroundColor = UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)
        deleteAction.image = UIImage(named: "delete")
        
        shareAction.backgroundColor = UIColor(red: 254.0/255.0, green: 149.0/255.0, blue: 38.0/255.0, alpha: 1.0)
        shareAction.image = UIImage(named: "share")
        
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, shareAction])
        
        return swipeConfiguration
        
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if (searchController?.isActive)! {
            return false
        } else {
            return true
        }
    }


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let destinationController = segue.destination as! DetailViewController
                //print(diaries[indexPath.row].description)
                destinationController.diary = (searchController?.isActive)! ? searchResults[indexPath.row] : diaries[indexPath.row]
//                destinationController.navigationController?.navigationItem = navTitle
                destinationController.hidesBottomBarWhenPushed = true
            }
        }
        
        if segue.identifier == "showNotebook" {
            let toViewController = segue.destination
            toViewController.transitioningDelegate = slideOutTransition
        }
    }
    
    // MARK: - SearchController
    func filterContent(for searchText: String) {
        searchResults = diaries.filter({ (diary) -> Bool in
            if let title = diary.title, let tag = diary.tag, let content = diary.content {
                let isMatch = title.localizedCaseInsensitiveContains(searchText) || tag.localizedCaseInsensitiveContains(searchText) || content.localizedCaseInsensitiveContains(searchText)
                return isMatch
            }
            
            return false
        })
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchText = searchController.searchBar.text {
            filterContent(for: searchText)
            tableView.reloadData()
        }
    }
    
    // MARK: - 3D Touch
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return nil
        }
        
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return nil
        }
        
        guard let detailViewController = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as? DetailViewController else {
            return nil
        }
        
        let selectedDiary = diaries[indexPath.row]
        detailViewController.diary = selectedDiary
        detailViewController.preferredContentSize = CGSize(width: 0.0, height: screenHeight - 200)
        previewingContext.sourceRect = cell.frame
        return detailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func getFriendlyTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        var dateFormatString = ""
        
        let timeInterval = Int(round(date.timeIntervalSince1970))
        let currentInterval = Int(round(Date.init().timeIntervalSince1970))
        let diff = currentInterval - timeInterval
        if diff / (3600 * 24 * 365) >= 1 {
            dateFormatString = "yyyy年"
        } else {
            if diff / (3600 * 24) >= 7 {
                dateFormatString = "HH:mm"
            } else {
                if diff / 3600 >= 24 {
                    dateFormatString = "HH:mm"
                } else {
                    if diff / 3600 >= 1 {
                        return String(diff / (3600)) + "小时前"
                    } else {
                        if diff / 60 >= 1 {
                            return String(diff / (60)) + "分钟前"
                        } else {
                            return "刚刚"
                        }
                        
                    }
                }
            }
        }
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func getFriendlyDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        var dateFormatString = ""
        
        let timeInterval = Int(round(date.timeIntervalSince1970))
        let currentInterval = Int(round(Date.init().timeIntervalSince1970))
        let diff = currentInterval - timeInterval
        if diff / (3600 * 24 * 365) >= 1 {
            dateFormatString = "yyyy年MM月dd日"
        } else {
            if diff / (3600 * 24) >= 7 {
                dateFormatString = "MM月dd日"
            } else {
                if diff / 3600 >= 24 {
                    return String(diff / (3600 * 24)) + "天前"
                } else {
                    if diff / 3600 >= 1 {
                        return String(diff / (3600)) + "小时前"
                    } else {
                        if diff / 60 >= 1 {
                            return String(diff / (60)) + "分钟前"
                        } else {
                            return "刚刚"
                        }
                        
                    }
                }
            }
        }
        dateFormatter.dateFormat = dateFormatString
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}

extension UIDevice {
    var iPhoneX: Bool {
        return UIScreen.main.nativeBounds.height == 2436
    }
}
