//
//  OtherDetailsViewController.swift
//  Celo
//
//  Created by Santanu Karar on 06/11/15.
//  Copyright © 2015 Santanu Karar. All rights reserved.
//

import UIKit
import WebKit

class OtherDetailsViewController: UIViewController
{
    @IBOutlet weak var bbTop: UIToolbar!
    
    var documentTitle:String!
    var documentPath:String!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        setupUI()
        
        //let path = NSBundle.mainBundle().pathForResource("D", ofType: "doc")
        /*let wkWebView = WKWebView(frame: CGRectMake(0, bbTop.frame.origin.y + bbTop.frame.height, view.frame.width, view.frame.height))
        wkWebView.loadRequest(NSURLRequest(URL: NSURL(fileURLWithPath: ConstantsVO.othersPath.path! + "/" + documentPath)))
        view.insertSubview(wkWebView, atIndex: 0)*/
        
        // NOTE: WKWebView doesn't works in lower iOS devices thus UIWebView
        let uiWebView = UIWebView(frame: CGRect(x: 0, y: bbTop.frame.origin.y + bbTop.frame.height, width: view.frame.width, height: view.frame.height))
        uiWebView.loadRequest(URLRequest(url: URL(fileURLWithPath: ConstantsVO.othersPath.path + "/" + documentPath)))
        uiWebView.scalesPageToFit = true
        uiWebView.autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        view.insertSubview(uiWebView, at: 0)
        
        // add constraints
        /*wkWebView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraint(NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: bbTop.frame.origin.y + bbTop.frame.height))
        self.view.addConstraint(NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
        self.view.addConstraint(NSLayoutConstraint(item: wkWebView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))*/
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func setupUI()
    {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = documentTitle
        label.sizeToFit()
        
        let toolBarTitle = UIBarButtonItem(customView: label)
        let toolBarDone = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(OtherDetailsViewController.onDone(_:)))
        toolBarDone.tintColor = UIColor(red: 239.0/255.0, green: 40.0/255.0, blue: 44.0/255.0, alpha: 1.0)

        bbTop.items = [toolBarTitle, UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil), toolBarDone]
    }

    @IBAction func onDone(_ sender: AnyObject)
    {
        NotificationCenter.default.post(name: Notification.Name(rawValue: OthersTableViewController.NOTIFICATION_DETAILVIEW_CANCELLED), object: nil)
        dismiss(animated: true, completion: nil)
    }
}
