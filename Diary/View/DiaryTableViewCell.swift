//
//  DiaryTableViewCell.swift
//  Diary
//
//  Created by 牛苒 on 2018/2/21.
//  Copyright © 2018年 牛苒. All rights reserved.
//

import UIKit

class DiaryTableViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var thumbnailImageView: UIImageView! {
        didSet {
            thumbnailImageView.layer.cornerRadius = 5.0
            thumbnailImageView.clipsToBounds = true
        }
    }
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var tagLabel: UILabel! {
        didSet {
            tagLabel.layer.cornerRadius = 5.0
            tagLabel.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var weekLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
