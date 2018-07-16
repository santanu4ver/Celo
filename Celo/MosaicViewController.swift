//
//  MosaicViewController.swift
//  Celo
//
//  Created by Santanu Karar on 11/07/16.
//  Copyright © 2016 Santanu Karar. All rights reserved.
//

import UIKit
import VideoViewController

protocol MosaicViewControllerDelegate: class
{
    func numberOfPhotosInPhotoBrowser(_ photoBrowser: MosaicViewController?) -> Int
    func photoBrowser(_ photoBrowser: MosaicViewController!, photoAtIndex index: Int) -> MosaicPhoto!
    func photoBrowser(_ photoBrowser: MosaicViewController!, isPhotoSelectedAtIndex index: Int) -> Bool
    func photoBrowser(_ photoBrowser: MosaicViewController!, photoAtIndex index: Int, selectedChanged selected: Bool)
    func photoBrowserDidFinishModalPresentation(_ photoBrowser: MosaicViewController!)
    func photoBrowser(_ photoBrowser: MosaicViewController!, onEditActionButtonPressed value: String!, withClient client: AnyObject!)
    func photoBrowser(_ reOrderFrom:Int, reOrderTo:Int)
    func getGalleryItems() -> GalleryItems
    func getSelectionsArray() -> [Bool]
    func resetSelectedItems()
    func deleteSelectedItems(_ onCompletion:@escaping () -> Void)
    func orientationChanged(_ isLandscape: Bool)
    func cloudDriveOpens(_ isOpen: Bool)
    func getSelectionCount() -> Int32
    func oneDriveDisclaimerAccepted()
    func isConnectedToNetwork() -> Bool
}

class MosaicViewController: UIViewController, UIGestureRecognizerDelegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: MosaicViewControllerDelegate!
    
    lazy var bbDelete: UIBarButtonItem! =
    {   [unowned self] in
        
        var button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.trash, target: self, action: #selector(MosaicViewController.onDeleteButtonPressed))
        button.tintColor = UIColor.darkGray
        return button
    }()
    lazy var bbDone: UIBarButtonItem! =
    {   [unowned self] in
        
        var button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(MosaicViewController.onDoneButtonPressed))
        button.tintColor = UIColor.lightGray
        return button
    }()
    lazy var bbActions: UIBarButtonItem! =
    {   [unowned self] in
        
        var button = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.action, target: self, action: #selector(MosaicViewController.onActionPressed(_:)))
        button.tintColor = UIColor.darkGray
        return button
    }()
    
    let imageFormatName = FICDPhotoSquareImage16BitBGRFormatName
    
    var callbackCount = 0
    var isDraggable = false
    var isDeleteMode = false
    var isStatusBarHidden = false
    
    fileprivate var _isNavBarIsHiding:Bool = false
    fileprivate var _lpg:UILongPressGestureRecognizer!
    fileprivate var _lpgVideoView:UILongPressGestureRecognizer!
    fileprivate var _tgVideoView:UITapGestureRecognizer!
    fileprivate var _selfRemoved = false
    fileprivate var _videoCloseButton:UIButton!
    fileprivate var _videoViewController:VideoViewController!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        // hide nav and status bar after delay
        hideBarsAfterDelay()
        // add gesture to show navbar
        addOrRemoveLongPressGesture(true)
        
        self.navigationItem.rightBarButtonItems = [bbActions]
        self.navigationController?.navigationBar.tintColor = UIColor.darkGray
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        // this condition ensured the method called by back button press only
        if self.isMovingFromParentViewController
        {
            _selfRemoved = true
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation
    {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool
    {
        return isStatusBarHidden
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        // this condition ensured the method called by back button press only
        if self.isMovingFromParentViewController
        {
            isStatusBarHidden = false
            UIView.animate(withDuration: 0.25) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            }
            delegate.photoBrowserDidFinishModalPresentation(nil)
            delegate = nil
        }
    }
    
    func addOrRemoveLongPressGesture(_ value:Bool)
    {
        if (value)
        {
            _lpg = UILongPressGestureRecognizer(target: self, action: #selector(MosaicViewController.handleLongPressToShowNavbar(_:)))
            _lpg.delegate = self
            _lpg.minimumPressDuration = 1.0
            _lpg.numberOfTouchesRequired = 1
            ((UIApplication.shared.delegate?.window)!)!.addGestureRecognizer(_lpg)
        }
        else
        {
            ((UIApplication.shared.delegate?.window)!)!.removeGestureRecognizer(_lpg)
        }
    }
    
    func hideBarsAfterDelay()
    {
        guard !_isNavBarIsHiding else
        {
            return
        }
        
        let delay = 2 * Double(NSEC_PER_SEC)
        let time = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC)
        _isNavBarIsHiding = true
        DispatchQueue.main.asyncAfter(deadline: time)
        {
            guard !self._selfRemoved else
            {
                return
            }
            
            let appFrame = UIScreen.main.bounds
            self.isStatusBarHidden = true
            UIView.animate(withDuration: 0.25) { () -> Void in
                self.setNeedsStatusBarAppearanceUpdate()
            }
            UIView.animate(withDuration: 0.30, animations: { () -> Void in
                
                self.navigationController!.navigationBar.frame = self.navigationController!.navigationBar.bounds;
                self.view.frame = CGRect(x: 0, y: 0, width: appFrame.size.width, height: appFrame.size.height);
                
                }, completion: { (success) -> Void in
                
                    self.perform(#selector(MosaicViewController.showHideNavBarOnly(_:)), with: true, afterDelay: 0.5)
                    self._isNavBarIsHiding = false
            })
        }
    }
    
    func showHideNavBarOnly(_ hide:Bool)
    {
        self.navigationController?.setNavigationBarHidden(hide, animated: true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        if (self.navigationController?.isNavigationBarHidden == false && !isDraggable && !isDeleteMode)
        {
            self.showHideNavBarOnly(true)
        }
    }
    
    func handleLongPressToShowNavbar(_ sender:UILongPressGestureRecognizer)
    {
        showHideNavBarOnly(false)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension MosaicViewController: UIPopoverPresentationControllerDelegate
{
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
}

extension MosaicViewController: UICollectionViewDelegate, UICollectionViewDataSource
{
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return delegate.numberOfPhotosInPhotoBrowser(nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! MosaicCollectionViewCell
        cell.imagePath = delegate.photoBrowser(nil, photoAtIndex: indexPath.item)
        cell.addSelectedImage()
        
        if isDeleteMode
        {
            if delegate.photoBrowser(nil, isPhotoSelectedAtIndex: indexPath.item)
            {
                cell.setDeleteKeySelected(true)
            }
            else
            {
                cell.setDeleteKeySelected(false)
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        guard isDraggable == false else
        {
            return
        }
        
        if isDeleteMode
        {
            if delegate.photoBrowser(nil, isPhotoSelectedAtIndex: indexPath.item)
            {
                delegate.photoBrowser(nil, photoAtIndex: indexPath.item, selectedChanged: false)
            }
            else
            {
                delegate.photoBrowser(nil, photoAtIndex: indexPath.item, selectedChanged: true)
            }
            
            // update view
            collectionView.reloadData()
        }
        else
        {
            let mosaicPhoto = delegate.photoBrowser(nil, photoAtIndex: indexPath.item)
            if mosaicPhoto?.type == PHAssetMediaType.image
            {
                //let cell = collectionView.cellForItemAtIndexPath(indexPath) as! MosaicCollectionViewCell
                //FullScreenSharedDisplay.getInstance.photosTableViewCell(cell, didSelectPhoto: cell.imagePath, withImageView: cell.mosaicImageView)
                
                let ctr = FullScreenSlideshowViewController()
                ctr.initialPage = (indexPath as NSIndexPath).row + 1
                ctr.inputs = delegate.getGalleryItems()
                self.present(ctr, animated: false, completion: nil)
            }
            else if mosaicPhoto?.type == PHAssetMediaType.video
            {
                // we're not going to work in the codes of the video
                // controller api, instead we keep using it as it is downloaded
                // with pod. We shall add our close handler from outside
                _videoCloseButton  = UIButton(type: .custom)
                _videoCloseButton.setImage(UIImage(named: "close"), for: .normal)
                _videoCloseButton.alpha = 0.7
                _videoCloseButton.addTarget(self, action: #selector(removeVideoView), for: UIControlEvents.touchUpInside)
                
                _videoViewController = VideoViewController(videoURL: (mosaicPhoto?.sourceVideoURL)!)
                DispatchQueue.main.async(execute:
                {
                    self.present(self._videoViewController, animated: true, completion: nil)
                    
                    self._videoViewController.view.addSubview(self._videoCloseButton)
                    
                    self._videoCloseButton.translatesAutoresizingMaskIntoConstraints = false
                    self._videoCloseButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
                    self._videoCloseButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
                    self._videoCloseButton.rightAnchor.constraint(equalTo: self._videoViewController.view.rightAnchor, constant: 16).isActive = true
                    self._videoCloseButton.topAnchor.constraint(equalTo: self._videoViewController.view.topAnchor, constant: 10).isActive = true
                    
                    // once added hide the close button after couple of seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.hideCloseButton(true)
                    }
                })
            }
        }
    }
    
    func hideCloseButton(_ isHide:Bool)
    {
        UIView.animate(withDuration: 0.5, delay: 0.5, options: .curveEaseOut, animations: {
            self._videoCloseButton.alpha = isHide ? 0.0 : 0.7
            }, completion: { finished in
            
                if isHide
                {
                    // long press gesture to return the cross sign
                    self._lpgVideoView = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPressVideoWindow(_:)))
                    self._videoViewController.view.addGestureRecognizer(self._lpgVideoView)
                }
                else
                {
                    // tap gesture to hide the cross sign
                    self._tgVideoView = UITapGestureRecognizer(target: self, action: #selector(self.handleTapPressVideoWindow(_:)))
                    self._videoViewController.view.addGestureRecognizer(self._tgVideoView)
                }
        })
    }
    
    func handleLongPressVideoWindow(_ sender:UILongPressGestureRecognizer)
    {
        self._videoViewController.view.removeGestureRecognizer(self._lpgVideoView)
        hideCloseButton(false)
    }
    
    func handleTapPressVideoWindow(_ sender:UITapGestureRecognizer)
    {
        self._videoViewController.view.removeGestureRecognizer(self._tgVideoView)
        hideCloseButton(true)
    }
    
    func removeVideoView(_ isAnimated:Bool=true)
    {
        if (self._lpgVideoView != nil)
        {
            self._videoViewController.view.removeGestureRecognizer(self._lpgVideoView)
        }
        if (self._tgVideoView != nil)
        {
            self._videoViewController.view.removeGestureRecognizer(self._tgVideoView)
        }
        
        self._videoViewController.pause() // this is not the right solution but the API do not provides any other way to dispose the player - reported an issue to the developer's git
        self.dismiss(animated: isAnimated, completion: { (finished) -> Void in
            self._videoViewController = nil
            self._videoCloseButton = nil
        })
    }
}

extension MosaicViewController: RACollectionViewDelegateReorderableTripletLayout, RACollectionViewReorderableTripletLayoutDataSource
{
    func sectionSpacing(for collectionView: UICollectionView!) -> CGFloat
    {
        return 7.0
    }
    
    func minimumInteritemSpacing(for collectionView: UICollectionView!) -> CGFloat
    {
        return 7.0
    }
    
    func minimumLineSpacing(for collectionView: UICollectionView!) -> CGFloat
    {
        return 7.0
    }
    
    func insets(for collectionView: UICollectionView!) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    }
    
    func collectionView(_ collectionView: UICollectionView!, sizeForLargeItemsInSection section: Int) -> CGSize
    {
        return CGSize.zero
    }
    
    func autoScrollTrigerEdgeInsets(_ collectionView: UICollectionView!) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 50.0, left: 0, bottom: 50.0, right: 0)
    }
    
    func autoScrollTrigerPadding(_ collectionView: UICollectionView!) -> UIEdgeInsets
    {
        return UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
    }
    
    func reorderingItemAlpha(_ collectionview: UICollectionView!) -> CGFloat
    {
        return 0.3
    }
    
    func collectionView(_ collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout!, didEndDraggingItemAt indexPath: IndexPath!)
    {
        self.collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView!, itemAt fromIndexPath: IndexPath!, didMoveTo toIndexPath: IndexPath!)
    {
        delegate.photoBrowser(fromIndexPath.item, reOrderTo: toIndexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView!, itemAt fromIndexPath: IndexPath!, canMoveTo toIndexPath: IndexPath!) -> Bool
    {
        return isDraggable
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool
    {
        return isDraggable
    }
}

extension MosaicViewController: ActionsTableViewControllerDelegate
{
    @IBAction func onActionPressed(_ sender: AnyObject)
    {
        let menuController = ActionsTableViewController()
        menuController.collectionOfOption = MosaicActions.arrayForMosaicGallery
        menuController.delegate = self
        menuController.modalPresentationStyle = UIModalPresentationStyle.popover
        menuController.preferredContentSize = CGSize(width: 200, height: 132)
        
        let popoverMenuViewController = menuController.popoverPresentationController
        popoverMenuViewController?.permittedArrowDirections = UIPopoverArrowDirection.any
        popoverMenuViewController?.delegate = self
        popoverMenuViewController?.barButtonItem = sender as? UIBarButtonItem
        present(menuController, animated: true, completion: nil)
    }
    
    func onMosaicActionSelected(_ value: MosaicActions)
    {
        switch value
        {
        case MosaicActions.Slideshow:
            print("Slideshow")
        case MosaicActions.ReOrder:
            initReOrderUI()
        default:
            initDeleteUI()
        }
    }
    
    func initReOrderUI()
    {
        self.navigationItem.setRightBarButtonItems([bbDone], animated: true)
        self.addOrRemoveLongPressGesture(false)
        isDraggable = true
    }
    
    func initDeleteUI()
    {
        self.navigationItem.setRightBarButtonItems([bbDone, bbDelete], animated: true)
        self.addOrRemoveLongPressGesture(false)
        self.isDeleteMode = true
    }
    
    func onDoneButtonPressed()
    {
        if isDeleteMode
        {
            self.isDeleteMode = false
            delegate.resetSelectedItems()
            self.collectionView.reloadData()
        }
        else if isDraggable
        {
            self.isDraggable = false
        }
        
        DispatchQueue.main.async
        {
            self.navigationItem.setRightBarButtonItems([self.bbActions], animated: true)
            self.addOrRemoveLongPressGesture(true)
        }
    }
    
    func onDeleteButtonPressed()
    {
        collectionView.performBatchUpdates({ () -> Void in
            
            var paths = [IndexPath]()
            let selectionArray = self.delegate.getSelectionsArray()
            for (index, value) in selectionArray.enumerated() where value
            {
                paths.append(IndexPath(row: index, section: 0))
            }
            
            // do not proceed if there's none selected items
            if paths.count == 0
            {
                return
            }
            
            self.delegate.deleteSelectedItems({
                () -> Void in
                
                DispatchQueue.main.async
                {
                    Thread.detachNewThreadSelector(#selector(GalleryManager.resetSelectedItems), toTarget: self.delegate, with: nil)
                    self.collectionView.deleteItems(at: paths)
                    self.collectionView.reloadData()
                }
                
            })
            
            }) { (complete) -> Void in
        }
    }
}

extension MosaicViewController:CeloSectionViewController
{
    func dispose() {
        DispatchQueue.main.async
        {
            if (self._videoViewController != nil)
            {
                self.removeVideoView(false)
            }
            _ = self.navigationController?.popViewController(animated: false)
        }
    }
}
