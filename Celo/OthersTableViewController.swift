//
//  OthersTableViewController.swift
//  Celo
//
//  Created by Santanu Karar on 18/01/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

enum OthersType:String
{
    case Doc = "doc"
    case RTF = "rtf"
    case TXT = "txt"
    case PDF = "pdf"
    case HTM = "htm"
    case HTML = "html"
}

class OthersTableViewController: UITableViewController
{
    static let NOTIFICATION_DETAILVIEW_CANCELLED = "NOTIFICATION_DETAILVIEW_CANCELLED"
    
    var snapshotView: UIImageView!
    var isOpeningDetails = false
    
    lazy var galleryManager: GalleryManager =
    {
        var gm = GalleryManager()
        return gm
    }()
    
    //--------------------------------------------------------------------------
    //
    //  METHODS
    //
    //--------------------------------------------------------------------------
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        self.tableView.emptyDataSetSource = self
        self.tableView.emptyDataSetDelegate = self

        configureHeaderAndFooter()
        loadOthersData()
        self.navigationController?.navigationBar.tintColor = UIColor.darkGray
        
        // to fix unexpected space between uiNavigationBar and
        // grouped tableView's first group

        NotificationCenter.default.addObserver(self, selector: #selector(OthersTableViewController.onDetailViewDismissed), name: NSNotification.Name(rawValue: OthersTableViewController.NOTIFICATION_DETAILVIEW_CANCELLED), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        if !isOpeningDetails
        {
            NotificationCenter.default.removeObserver(self)
            if snapshotView != nil
            {
                self.snapshotView.removeFromSuperview()
            }
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    func configureHeaderAndFooter()
    {
        self.tableView.tableHeaderView = UIView()
        self.tableView.tableFooterView = UIView()
    }
    
    func loadOthersData()
    {
        self.galleryManager.showProgress(self.view, withType: HUDType.HUDTypeLabel, withTitle: "Loading")
        DispatchQueue.main.async
        {
            self.galleryManager.getOthersItems { (hasUpdate) -> Void in
                self.galleryManager.endProgress()
                self.title = String(self.galleryManager.otherFiles.count) + " Document" + ((self.galleryManager.otherFiles.count > 1) ? "s" : "")
                self.tableView.reloadData()
            }
        }
    }
    
    func onDetailViewDismissed()
    {
        isOpeningDetails = false
    }
    
    fileprivate func changeUIIfBackgroundImage()
    {
        tableView.backgroundColor = UIColor.clear
        tableView.separatorColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.3)
    }

    
    //--------------------------------------------------------------------------
    //
    //  IMPLEMENTATION
    //  @UITableView
    //
    //--------------------------------------------------------------------------

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return self.galleryManager.otherFiles.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "othersCell", for: indexPath)
        let disclosure = UIImageView(image: UIImage(named: "expand"))
        cell.accessoryView = disclosure
        
        let rowItem = self.galleryManager.otherFiles[(indexPath as NSIndexPath).row]
        cell.imageView?.image = getExtensionIcon(rowItem)
        cell.textLabel?.text = rowItem
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        tableView.deselectRow(at: indexPath, animated: true)
        isOpeningDetails = true
        
        let details = UIStoryboard.otherDetailsViewController() as! OtherDetailsViewController
        details.documentPath = self.galleryManager.otherFiles[(indexPath as NSIndexPath).row]
        details.documentTitle = self.galleryManager.otherFiles[(indexPath as NSIndexPath).row]
        present(details, animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            var isSuccess = true
            do
            {
                try FileManager.default.removeItem(atPath: ConstantsVO.othersPath.path + "/" + self.galleryManager.otherFiles[(indexPath as NSIndexPath).row])
            }
            catch
            {
                print(error)
                isSuccess = false
            }
            
            if isSuccess
            {
                self.galleryManager.otherFiles.remove(at: (indexPath as NSIndexPath).row)
                tableView.deleteRows(at: [indexPath], with: .fade)
                self.title = String(self.galleryManager.otherFiles.count) + " Document" + ((self.galleryManager.otherFiles.count > 1) ? "s" : "")
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        (view as! UITableViewHeaderFooterView).textLabel?.textColor = ConstantsVO.celoConfiguration.hasBackgroundImage ? UIColor.lightGray : UIColor(red: 0.427451, green: 0.427451, blue: 0.447059, alpha: 1)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        if ConstantsVO.celoConfiguration.hasBackgroundImage
        {
            cell.textLabel?.textColor = UIColor.white
            cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        }
        else
        {
            cell.textLabel?.textColor = UIColor.black
            cell.backgroundColor = UIColor(red: 255, green: 255, blue: 255, alpha: 0.8)
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat
    {
        return 0
    }
    
    func getExtensionIcon(_ path:String) -> UIImage
    {
        let ext = NSURL(fileURLWithPath: path).pathExtension?.lowercased()
        if (ext == OthersType.Doc.rawValue) || (ext == OthersType.PDF.rawValue) || (ext == OthersType.RTF.rawValue) || (ext == OthersType.TXT.rawValue)
        {
            return UIImage(named: ext!)!
        }
        else if (ext == OthersType.HTM.rawValue) || (ext == OthersType.HTML.rawValue)
        {
            return UIImage(named: "htm")!
        }
        
        return UIImage(named: "unknown")!
    }
    
    
    
    //--------------------------------------------------------------------------
    //
    //  IMPLEMENTATION
    //  @UIScrollView
    //
    //--------------------------------------------------------------------------

    override func scrollViewDidScroll(_ scrollView: UIScrollView)
    {
        if let navBar = self.navigationController?.navigationBar , (scrollView == self.tableView)
        {
            // makes the imageview alpha change
            if snapshotView != nil && ConstantsVO.celoConfiguration.hasBackgroundImage
            {
                if (scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= navBar.frame.height)
                {
                    self.snapshotView.alpha = (scrollView.contentOffset.y / navBar.frame.height)
                }
                else if (scrollView.contentOffset.y > navBar.frame.height)
                {
                    self.snapshotView.alpha = 1
                }
            }
            // makes the uiview background color alpha change
            else if !ConstantsVO.celoConfiguration.hasBackgroundImage
            {
                if (scrollView.contentOffset.y >= 0 && scrollView.contentOffset.y <= navBar.frame.height)
                {
                    navBar.backgroundColor = UIColor(red: 0.937255, green: 0.937255, blue: 0.956863, alpha: (scrollView.contentOffset.y / navBar.frame.height))
                }
                else if (scrollView.contentOffset.y > navBar.frame.height)
                {
                    navBar.backgroundColor = UIColor(red: 0.937255, green: 0.937255, blue: 0.956863, alpha: 1)
                }
            }
        }
    }
}


//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @DZNEmptyDataSet
//
//--------------------------------------------------------------------------

extension OthersTableViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate
{
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        return NSAttributedString(string: "Import Documents by iTunes")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString!
    {
        return NSAttributedString(string: "Connect your device and open iTunes. Select Celo in File Sharing secion. Drag-n-drop fils to Celo Documents. Click Add.. When added tap Reload Data button below")
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage!
    {
        return UIImage(named: "othersBG")
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString!
    {
        return NSAttributedString(string: "Reload Data")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor!
    {
        return ConstantsVO.celoConfiguration.hasBackgroundImage ? UIColor.clear : UIColor(red: 0.937255, green: 0.937255, blue: 0.956863, alpha: 1)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat
    {
        return 0.0
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat
    {
        return 0.0
    }
    
    func emptyDataSetShouldDisplay(_ scrollView: UIScrollView!) -> Bool
    {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool
    {
        return true
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return false
    }
    
    func emptyDataSetShouldAnimateImageView(_ scrollView: UIScrollView!) -> Bool
    {
        return false
    }
    
    func emptyDataSet(_ scrollView: UIScrollView!, didTap button: UIButton!)
    {
        loadOthersData()
    }
}


extension OthersTableViewController:CeloSectionViewController
{
    func dispose()
    {
        if isOpeningDetails
        {
            isOpeningDetails = false
            NotificationCenter.default.removeObserver(self);
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
}
