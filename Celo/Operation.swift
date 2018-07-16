//
//  Operation.swift
//  VoteYourSpider
//
//  Created by Santanu Karar on 10/08/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//
//  http://szulctomasz.com/ios-second-try-to-nsoperation-and-long-running-tasks/
//

import Foundation

class Operation: Foundation.Operation
{
    fileprivate var startOnMainThread: Bool
    fileprivate var finishInMain: Bool
    
    // keep track of executing and finished states
    fileprivate var _executing = false
    fileprivate var _finished = false
    
    init(completionBlock: (() -> Void)? = nil, startOnMainThread: Bool = false, finishInMain: Bool = true)
    {
        self.startOnMainThread = startOnMainThread
        self.finishInMain = finishInMain
        super.init()
        self.completionBlock = completionBlock
        self.name = "custom"
    }
    
    override func start()
    {
        if isCancelled
        {
            finish()
            return
        }
        
        willChangeValue(forKey: "isExecuting")
        _executing = true
        didChangeValue(forKey: "isExecuting")
        
        // call main, maybe other subclasses will want use it?
        // we have to call it manually when overriding 'start'
        main()
    }
    
    override func main()
    {
        if isCancelled == true && _finished != false
        {
            finish()
            return
        }
        
        if finishInMain { finish() }
    }
    
    // if 'finishInMain' is set to 'false' you are responible to call
    // 'finish()' method when operation is about to finish.
    func finish()
    {
        // change isExecuting to `false` and isFinished to `true`.
        // taks will be considered finished.
        willChangeValue(forKey: "isExecuting")
        willChangeValue(forKey: "isFinished")
        _executing = false
        _finished = true
        didChangeValue(forKey: "isExecuting")
        didChangeValue(forKey: "isFinished")
    }
    
    override var isExecuting: Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    override func cancel()
    {
        super.cancel()
        finish()
    }
}
