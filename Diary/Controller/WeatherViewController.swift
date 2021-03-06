//
//  WeatherViewController.swift
//  Diary
//
//  Created by 牛苒 on 2018/2/23.
//  Copyright © 2018年 牛苒. All rights reserved.
//

import UIKit

class WeatherViewController: UIViewController {
    
    @IBOutlet var backgroundImageView: UIImageView!
    
    @IBOutlet var weatherButtons: [UIButton]!
    
    var weather = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        backgroundImageView.image = UIImage(named: "weather-background")
        
        // Applying the blur effect
        let blurEffect = UIBlurEffect(style: .light)
        let bulrEffectView = UIVisualEffectView(effect: blurEffect)
        bulrEffectView.frame = view.bounds
        backgroundImageView.addSubview(bulrEffectView)
        
        let moveRightTransform = CGAffineTransform.init(translationX: 600, y: 0)
        
        // Make the button invisible
        for weatherButton in weatherButtons {
            if let buttonText = weatherButton.titleLabel?.text! {
                weatherButton.setImage(UIImage(named: buttonText.lowercased())?.imageResize(sizeChange: CGSize(width: 50.0, height: 50.0)), for: UIControlState.normal)
            }
            weatherButton.transform = moveRightTransform
            weatherButton.alpha = 0
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        for index in 0..<weatherButtons.count {
            UIView.animate(withDuration: 0.8, delay: 0.1 + Double(index) * 0.05, options: [], animations: {
                self.weatherButtons[index].alpha = 1.0
                self.weatherButtons[index].transform = .identity
            }, completion: nil)
        }
    }
}

extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}
