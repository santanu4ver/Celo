//
//  ConstantsVO.swift
//  VoteYourSpider
//
//  Created by Santanu Karar on 07/08/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import Foundation

var _keyboardHeight: CGFloat!
var _actIndicator: UIActivityIndicatorView!
var _celoConfiguration: CeloConfiguration!

class ConstantsVO: NSObject
{
    static let USER_LOGIN_SUCCESS = "USER_LOGIN_SUCCESS"
    static let USER_LOGIN_CANCELLED = "USER_LOGIN_CANCELLED"
    static let BACKGROUND_CHANGED = "BACKGROUND_CHANGED"
    static let USER_HELP_CANCELLED = "USER_HELP_CANCELLED"
    static let OPENING_HELP_REQUESTED = "OPENING_HELP_REQUESTED"
    static let deviceScreenHeight = UIScreen.main.bounds.height

    static var celoPath: URL!
    static var thumbPath: URL!
    static var othersPath: URL!
    static var isBackgrounImage = false
    static var isInLoginState = false
    static var isImportWindowOpened = false
    static var isLoginFormOpen = false
    static var isLandscape = false
    static var isLoggedInAsGuest = false
    static var isAppTurnToComa = false
    static var isUserHelpAchieved = UserDefaults.standard.bool(forKey: "isUserHelpAchieved")
    static var isUserImportedForFirstTime = UserDefaults.standard.bool(forKey: "isUserImportedForFirstTime")
    static var isUserAcceptedClouodDisclaimer = UserDefaults.standard.bool(forKey: "isUserAcceptedClouodDisclaimer")
    static var backgroundImageExtensions:[String] = UserDefaults.standard.array(forKey: "backgroundImageExtensions") as! [String]
    static var uiEdgeInsetsTop: CGFloat = 0

    class var keyboardHeight: CGFloat!
    {
        set
        {
            _keyboardHeight = newValue
        }
        get
        {
            return _keyboardHeight
        }
    }
    class var activityIndicator: UIActivityIndicatorView!
    {
        set
        {
            _actIndicator = newValue
        }
        get
        {
            return _actIndicator
        }
    }
    class var celoConfiguration: CeloConfiguration!
    {
        set
        {
            _celoConfiguration = newValue
        }
        get
        {
        return _celoConfiguration
        }
    }
}
