//
//  NewDiaryTableViewController.swift
//  Diary
//
//  Created by 牛苒 on 2018/2/23.
//  Copyright © 2018年 牛苒. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation
import Contacts

class NewDiaryTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate,CLLocationManagerDelegate {
    
    var diary: DiaryMO!
    var choosedWeatherButtonText = ""
    var noteBookName = ""
    var currentDate = Date()
    let locationManager = CLLocationManager()
    var userCurrentLocation = ""
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if let appDelegate = (UIApplication.shared.delegate as? AppDelegate) {
            let context = appDelegate.persistentContainer.viewContext
            diary = DiaryMO(context: context)
            let currentMaxId = UserDefaults.standard.integer(forKey: "maxDiaryId")
            UserDefaults.standard.set(currentMaxId + 1, forKey: "maxDiaryId")
            diary.id = String(currentMaxId + 1)
            diary.title = titleTextField.text
            diary.tag = "日记"
            diary.author = "匿名"
            diary.weather = self.choosedWeatherButtonText
            diary.location = self.userCurrentLocation
            diary.create = currentDate
            diary.update = currentDate
            diary.content = contentTextView.text
            diary.review = "0"
            diary.notebookid = String(UserDefaults.standard.integer(forKey: "defaultNoteBookId"))
            
            if let diaryImage = photoImageView.image {
                diary.image = UIImagePNGRepresentation(diaryImage)
            }
            
            print("Saving data to context")
            appDelegate.saveContext()
        }
        dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet var titleTextField: UITextField!
    
    @IBOutlet var photoImageView: UIImageView!
    
    @IBOutlet var contentTextView: UITextView!
    
    @IBOutlet weak var weatherButton: UIButton!
    
    @IBOutlet var dateLabel: UILabel!
    
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
        dateFormatter.dateFormat = "yyyy年MM月dd日 H:m:s"
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
        let userCLLocation = locations[0]
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(userCLLocation, completionHandler: { (placemarks, error) in
            if let error = error {
                self.locationButton.setTitle("获取位置失败，点击重新获取", for: UIControlState.normal)
                print(error)
                return
            }
            if let placemarks = placemarks {
                let placemarkPostalAddress = placemarks[0].postalAddress!
                
                let userLocation = UserLocation(latitude: userCLLocation.coordinate.latitude, longitude: userCLLocation.coordinate.longitude, altitude: userCLLocation.altitude, horizontalAccuracy: userCLLocation.horizontalAccuracy, verticalAccuracy: userCLLocation.verticalAccuracy, course: userCLLocation.course, speed: userCLLocation.speed, countryCode: placemarkPostalAddress.isoCountryCode, country: placemarkPostalAddress.country, state: placemarkPostalAddress.state, city: placemarkPostalAddress.city, subLocality: placemarkPostalAddress.subLocality, street: placemarkPostalAddress.street)
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
}
