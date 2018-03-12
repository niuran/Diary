//
//  NewDiaryTableViewController.swift
//  Diary
//
//  Created by 牛苒 on 2018/2/23.
//  Copyright © 2018年 牛苒. All rights reserved.
//

import UIKit
import CloudKit
import CoreData
import MapKit
import CoreLocation
import Contacts

class NewDiaryTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate,CLLocationManagerDelegate {
    
    var diary: DiaryMO!
    var choosedWeatherButtonText = ""
    var choosedTags = ""
    var noteBookName = ""
    var currentDate = Date()
    let locationManager = CLLocationManager()
    var userCurrentLocation = ""
    var recordName = ""
    var userCLLocation = CLLocation()
    var isSetPhoto = false
    
    var defaults = UserDefaults(suiteName: "group.com.niuran.diary")!
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if !isSetPhoto && titleTextField.text == "" && (contentTextView.text == "" || contentTextView.text == "write some thing today...") {
            let alertController = UIAlertController(title: "不能创建一片空的日记",
                                                    message: nil, preferredStyle: .alert)
            //显示提示框
            self.present(alertController, animated: true, completion: nil)
            //两秒钟后自动消失
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                self.presentedViewController?.dismiss(animated: false, completion: nil)
            }
        } else {
        
            // Prepare data
            let currentMaxId = UserDefaults.standard.integer(forKey: "maxDiaryId")
            UserDefaults.standard.set(currentMaxId + 1, forKey: "maxDiaryId")
            let dataId = String(currentMaxId + 1)
            var isUpToCloud = false
            
            // Save to iCloud
            let record = CKRecord(recordType: "Diary")
            self.recordName = record.recordID.recordName
            record.setValue(dataId, forKey: "id")
            record.setValue(titleTextField.text, forKey: "title")
            if tagButton.titleLabel?.text == "tag" {
                record.setValue("", forKey: "tag")
            } else {
                record.setValue(tagButton.titleLabel?.text, forKey: "tag")
            }
            record.setValue(self.choosedWeatherButtonText, forKey: "weather")
            record.setValue(self.userCLLocation, forKey: "location")
            record.setValue(currentDate, forKey: "createdAt")
            record.setValue(currentDate, forKey: "modifiedAt")
            UserDefaults.standard.set(currentDate, forKey: "iCloudSync")
            record.setValue(contentTextView.text, forKey: "content")
            record.setValue("0", forKey: "review")
            record.setValue(String(UserDefaults.standard.integer(forKey: "defaultNoteBookId")), forKey: "notebookid")
            
            if isSetPhoto {
                let diaryImage = photoImageView.image!
                // Resize the image
                let imageData = UIImagePNGRepresentation(diaryImage)!
                let originalImage = UIImage(data: imageData)!
                let scalingFator = (originalImage.size.width > 1024) ? 1024 / originalImage.size.width : 1.0
                let scaledImage = UIImage(data: imageData, scale: scalingFator)!
                
                // Write the image to the local file for temporary use
                let imageFilePath = NSTemporaryDirectory() + titleTextField.text!
                let imageFileURL = URL(fileURLWithPath: imageFilePath)
                try? UIImageJPEGRepresentation(scaledImage, 0.8)?.write(to: imageFileURL)
                
                // Create image asset for upload
                let imageAsset = CKAsset(fileURL: imageFileURL)
                
                record.setValue(imageAsset, forKey: "image")
                
                let privateDatabase = CKContainer.default().privateCloudDatabase
                privateDatabase.save(record, completionHandler: { (record, error) in
                    if let error = error {
                        // Insert error handling
                        isUpToCloud = false
                        self.recordName = ""
                        print("NewDiary SaveToCloudError: \(error.localizedDescription)")
                        return
                    }
                    // Insert successfully saved record code
                    isUpToCloud = true
                    print("Saving data to iCloud")
                    try? FileManager.default.removeItem(at: imageFileURL)
                })
            } else {
                let privateDatabase = CKContainer.default().privateCloudDatabase
                privateDatabase.save(record, completionHandler: { (record, error) in
                    if let error = error {
                        // Insert error handling
                        isUpToCloud = false
                        print("NewDiary SaveToCloudError: \(error.localizedDescription)")
                        self.recordName = ""
                        return
                    }
                    // Insert successfully saved record code
                    isUpToCloud = true
                    print("Saving data to iCloud")
                })
            }
            
            // Save to CoreData
            if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
                let context = appDelegate.persistentContainer.viewContext
                diary = DiaryMO(context: context)
                
                diary.id = dataId
                diary.recordName = self.recordName
                diary.isUpToCloud = isUpToCloud
                diary.title = titleTextField.text
                diary.tag = tagButton.titleLabel?.text
                diary.weather = self.choosedWeatherButtonText
                diary.location = self.userCurrentLocation
                diary.create = currentDate
                diary.update = currentDate
                diary.content = contentTextView.text
                diary.review = "0"
                diary.notebookid = String(UserDefaults.standard.integer(forKey: "defaultNoteBookId"))
                
                if isSetPhoto {
                    if let diaryImage = photoImageView.image {
                        diary.image = UIImagePNGRepresentation(diaryImage)
                    }
                }
                
                defaults.setValue(diary.title, forKey: "title")
                defaults.setValue(diary.content, forKey: "content")
                
                print("Saving data to context")
                appDelegate.saveContext()
            }
            
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBOutlet var titleTextField: UITextField!
    
    @IBOutlet var photoImageView: UIImageView!
    
    @IBOutlet var contentTextView: UITextView!
    
    @IBOutlet weak var weatherButton: UIButton!
    
    @IBOutlet var dateLabel: UILabel!
    
    @IBOutlet weak var tagButton: UIButton!
    
    @IBOutlet var locationImageView: UIImageView!
    
    @IBOutlet weak var locationButton: UIButton!
    
    @IBAction func locationButtonTapped(_ sender: Any) {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        } else {
            locationButton.setTitle("请开启地理位置权限", for: UIControlState.normal)
        }
    }
    
    @IBAction func chooseWeather(segue: UIStoryboardSegue) {
        if let choosedWeather = segue.identifier {
            self.weatherButton.imageView?.image = UIImage(named: choosedWeather)
            self.choosedWeatherButtonText = choosedWeather
        }
    }
    
    @IBAction func closeWeather(segue: UIStoryboardSegue) {
        //self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeTags(segue: UIStoryboardSegue) {
        
    }
    
    @IBAction func chooseTag(segue: UIStoryboardSegue) {
        if let source = segue.source as? TagsTableViewController {
            if source.choosedTags.count > 0 {
                var tagString = ""
                for tag in source.choosedTags {
                    tagString = tagString + tag + " "
                }
                tagString.remove(at: tagString.index(before: tagString.endIndex))
                tagButton.setTitle(tagString, for: UIControlState.normal)
            } else {
                tagButton.setTitle("tag", for: UIControlState.normal)
            }
            
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        
        tableView.separatorStyle = .none
        contentTextView.delegate = self

        // Configure navigation bar appearance
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(red: 231.0/255.0, green: 76.0/255.0, blue: 60.0/255.0, alpha: 1.0)]
        
        currentDate = Date.init()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current
        let dateString = dateFormatter.string(from: currentDate)
        dateLabel.text = dateString
        
        self.choosedWeatherButtonText = "sunny"
        
        // Prepare to get user's location
        locationImageView.image = UIImage(named: "map")
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        } else {
            locationButton.setTitle("请开启地理位置权限", for: UIControlState.normal)
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView)
    {
        if (textView.text == "write some thing today...")
        {
            textView.text = ""
            textView.textColor = .black
        }
        textView.becomeFirstResponder() //Optional
    }
    
    func textViewDidEndEditing(_ textView: UITextView)
    {
        if textView.text == ""
        {
            textView.text = "write some thing today..."
            textView.textColor = .lightGray
        }
        textView.resignFirstResponder()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            let photoSourceRequestController = UIAlertController(title: "", message: "请选择照片来源", preferredStyle: .actionSheet)
            let cameraAction = UIAlertAction(title: "照相", style: .default, handler: { (action) in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .camera
                    
                    self.present(imagePicker, animated: true, completion: nil)
                }
            })
            
            let photoLibraryAction = UIAlertAction(title: "相册", style: .default, handler: { (action) in
                if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.allowsEditing = false
                    imagePicker.sourceType = .photoLibrary
                    
                    self.present(imagePicker, animated: true, completion: nil)
                }
            })
            
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            
            photoSourceRequestController.addAction(cameraAction)
            photoSourceRequestController.addAction(photoLibraryAction)
            photoSourceRequestController.addAction(cancelAction)
            
            present(photoSourceRequestController, animated: true, completion: nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userCLLocation = locations[0]
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(userCLLocation, completionHandler: { (placemarks, error) in
            if let error = error {
                self.locationButton.setTitle("获取位置失败，点击重新获取", for: UIControlState.normal)
                print(error)
                return
            }
            if let placemarks = placemarks {
                let placemarkPostalAddress = placemarks[0].postalAddress!
                
                let userLocation = UserLocation(latitude: self.userCLLocation.coordinate.latitude, longitude: self.userCLLocation.coordinate.longitude, altitude: self.userCLLocation.altitude, horizontalAccuracy: self.userCLLocation.horizontalAccuracy, verticalAccuracy: self.userCLLocation.verticalAccuracy, course: self.userCLLocation.course, speed: self.userCLLocation.speed, countryCode: placemarkPostalAddress.isoCountryCode, country: placemarkPostalAddress.country, state: placemarkPostalAddress.state, city: placemarkPostalAddress.city, subLocality: placemarkPostalAddress.subLocality, street: placemarkPostalAddress.street)
                let jsonEncoder = JSONEncoder()
                do {
                    let jsonData = try jsonEncoder.encode(userLocation)
                    self.userCurrentLocation = String(data: jsonData, encoding: .utf8)!
                }
                catch {
                    print(error)
                }
                let locationString = placemarkPostalAddress.city + placemarkPostalAddress.subLocality + placemarkPostalAddress.street
                //print("buttonString: \(locationString)")
                self.locationButton.setTitle(locationString, for: UIControlState.normal)
            }
        })
        manager.stopUpdatingLocation()
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            photoImageView.image = selectedImage
            self.isSetPhoto = true
            photoImageView.contentMode = .scaleToFill
            photoImageView.clipsToBounds = true
        }
        
        let leadingConstraint = NSLayoutConstraint(item: photoImageView, attribute: .leading, relatedBy: .equal, toItem: photoImageView.superview, attribute: .leading, multiplier: 1, constant: 0)
        leadingConstraint.isActive = true
        
        let trailingConstraint = NSLayoutConstraint(item: photoImageView, attribute: .trailing, relatedBy: .equal, toItem: photoImageView.superview, attribute: .trailing, multiplier: 1, constant: 0)
        trailingConstraint.isActive = true
        
        let topConstraint = NSLayoutConstraint(item: photoImageView, attribute: .top, relatedBy: .equal, toItem: photoImageView.superview, attribute: .top, multiplier: 1, constant: 0)
        topConstraint.isActive = true
        
        let bottomConstraint = NSLayoutConstraint(item: photoImageView, attribute: .bottom, relatedBy: .equal, toItem: photoImageView.superview, attribute: .bottom, multiplier: 1, constant: 0)
        bottomConstraint.isActive = true
        
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTags" {
            let destination = segue.destination as! TagsTableViewController
            let tagButtonString = self.tagButton.titleLabel?.text ?? "tag"
            if tagButtonString != "tag" {
                let tagArray = tagButtonString.components(separatedBy: " ")
                destination.chooseTagsInit = tagArray
            }
        }
    }
}
