//
//  ImagesCollectionViewController.swift
//  Celo
//
//  Created by Santanu Karar on 26/12/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class ImagesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout
{
    // we'll reuse mosaicViewControllerDelegate to get object indexed items in galleryManager
    weak var delegate: MosaicViewControllerDelegate!
    weak var backgroundManager: BackgroundImageManager!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupUI()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupUI()
    {
        let leftButton =  UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(ImagesCollectionViewController.btn_clicked(_:)))
        self.navigationItem.setLeftBarButton(leftButton, animated: true)
        
        let rightButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ImagesCollectionViewController.btn_cancel(sender:)))
        self.navigationItem.setRightBarButton(rightButton, animated: true)
    }
    
    func btn_cancel(sender:UIBarButtonItem)
    {
        self.backgroundManager.backgroundImageWindowCancelled()
        self.dismiss(animated: true, completion: nil)
    }
    
    func btn_clicked(_ sender: UIBarButtonItem)
    {
        if delegate.getSelectionCount() != 3
        {
            let alert = UIAlertController(title: "", message: "You need to select 3 images to set background.", preferredStyle: UIAlertControllerStyle.alert)
            let doneAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
            alert.addAction(doneAction)
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
            self.dismiss(animated: true, completion: nil)
            
            var assets = [MosaicPhoto]()
            let selectionArr = delegate.getSelectionsArray();
            for (index, value) in selectionArr.enumerated()
            {
                if value
                {
                    print(index)
                    assets.append(delegate.photoBrowser(nil, photoAtIndex: index))
                }
            }
            
            // do things for background task
            OperationQueue.main.addOperation
            { () -> () in
                // send notification?
                self.backgroundManager.updateToBackground(assets)
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        // #warning Incomplete implementation, return the number of items
        return delegate.numberOfPhotosInPhotoBrowser(nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        return CGSize(width: collectionView.frame.size.width / 3.2, height: CGFloat(150))
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! MosaicCollectionViewCell
        cell.imagePath = delegate.photoBrowser(nil, photoAtIndex: indexPath.item)
        cell.addSelectedImage()
        
        if delegate.photoBrowser(nil, isPhotoSelectedAtIndex: indexPath.item)
        {
            cell.setDeleteKeySelected(true)
        }
        else
        {
            cell.setDeleteKeySelected(false)
        }
        
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        if delegate.photoBrowser(nil, isPhotoSelectedAtIndex: indexPath.item)
        {
            delegate.photoBrowser(nil, photoAtIndex: indexPath.item, selectedChanged: false)
        }
        else
        {
            delegate.photoBrowser(nil, photoAtIndex: indexPath.item, selectedChanged: true)
        }
        
        collectionView.reloadData()
    }

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
