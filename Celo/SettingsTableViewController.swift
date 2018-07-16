//
//  ActionsTableViewController.swift
//  MosaicPhotoGallery
//
//  Created by Santanu Karar on 17/03/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(SwitchTableViewCell.self, forCellReuseIdentifier: "checkCell")
        
        // this will hide last seprator line in table view
        self.tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 1))
        self.tableView.isScrollEnabled = false
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        var cell: UITableViewCell
        
        cell = tableView.dequeueReusableCell(withIdentifier: "checkCell", for: indexPath)
        (cell as! SwitchTableViewCell).cellTitle.text = "Remove Original on Import"
        (cell as! SwitchTableViewCell).switchSelected = ConstantsVO.celoConfiguration.isRemoveAfterImport
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        //delegate.onMosaicActionSelected(collectionOfOption[(indexPath as NSIndexPath).row])
        dismiss(animated: true, completion: nil)
    }
}
