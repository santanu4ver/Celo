//
//  ActionsTableViewController.swift
//  MosaicPhotoGallery
//
//  Created by Santanu Karar on 17/03/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit

protocol ActionsTableViewControllerDelegate: class
{
    func onMosaicActionSelected(_ value:MosaicActions)
}

enum MosaicActions: String
{
    case Slideshow = "Slideshow", ReOrder = "Re-Order", MoveToTrash = "Move to Trash", ImportFromLibrary = "Import From Library", ImportFromGallery = "Import From Gallery"
    
    static var arrayForMosaicGallery: [MosaicActions]
    {
        let items = [MosaicActions.Slideshow, MosaicActions.ReOrder, MosaicActions.MoveToTrash]
        return items
    }
    
    static var arrayForBackgroundImage: [MosaicActions]
    {
        let items = [MosaicActions.ImportFromLibrary, MosaicActions.ImportFromGallery]
        return items
    }
}

class ActionsTableViewController: UITableViewController
{
    weak var delegate: ActionsTableViewControllerDelegate!
    
    var collectionOfOption: [MosaicActions]!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "optionsCell")
        
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
        return collectionOfOption.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionsCell", for: indexPath) as UITableViewCell
        cell.textLabel?.text = collectionOfOption[(indexPath as NSIndexPath).row].rawValue

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        // delete imagecache objc code
        //[[FICImageCache sharedImageCache] deleteImageForEntity:[_photos objectAtIndex:(int)itemNew] withFormatName:_imageFormatName];
        delegate.onMosaicActionSelected(collectionOfOption[(indexPath as NSIndexPath).row])
        dismiss(animated: true, completion: nil)
    }
}
