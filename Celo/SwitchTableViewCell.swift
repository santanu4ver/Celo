//
//  SwitchTableViewCell.swift
//  Celo
//
//  Created by Santanu Karar on 07/10/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell
{
    let cellSwitch = UISwitch()
    let cellTitle = UILabel()

    var switchSelected: Bool
    {
        get
        {
            return cellSwitch.isOn
        }
        set
        {
            cellSwitch.setOn(newValue, animated: false)
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        cellSwitch.addTarget(self, action: #selector(onSwitchChange(_:)), for: .valueChanged)
        
        cellSwitch.translatesAutoresizingMaskIntoConstraints = false
        cellTitle.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(cellTitle)
        contentView.addSubview(cellSwitch)
        
        let viewsDict = [
            "cellTitle" : cellTitle,
            "cellSwitch" : cellSwitch,
            ] as [String : Any]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[cellSwitch]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[cellTitle]-|", options: [], metrics: nil, views: viewsDict))
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[cellTitle]-[cellSwitch]-|", options: [], metrics: nil, views: viewsDict))
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)
    }
    
    func onSwitchChange(_ sender: AnyObject)
    {
        ConstantsVO.celoConfiguration.isRemoveAfterImport = cellSwitch.isOn
        try! UIApplication.getManagedContext()?.save()
    }
}
