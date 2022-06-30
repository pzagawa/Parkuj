//
//  DelayTimer.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 05/12/2020.
//

import Foundation
import os

class DelayTimer
{
    //params: userData
    typealias Callback = (Any?) -> Void
    
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "DelayTimer")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.DelayTimer")

    let timeInterval: DispatchTimeInterval
    var callback: Callback?
    
    private var taskItems: [Task] = []
    
    init(timeInterval: DispatchTimeInterval)
    {
        self.timeInterval = timeInterval
        self.callback = nil
    }

    struct Task
    {
        typealias Callback = (Int) -> Void
        
        let index: Int
        let timeInterval: DispatchTimeInterval
        let userData: Any?
        let callback: Callback

        init(index: Int, timeInterval: DispatchTimeInterval, userData: Any?, callback: @escaping Callback)
        {
            self.index = index
            self.timeInterval = timeInterval
            self.userData = userData
            self.callback = callback
        }
    
        func start()
        {
            let delay_time = DispatchTime.now() + timeInterval
        
            DispatchQueue.main.asyncAfter(deadline: delay_time)
            {
                callback(self.index)
            }
        }
    }

    func execute(userData: Any? = nil)
    {
        self.serialQueue.sync
        {
            [weak self] in
            self?.executeInternal(userData: userData)
        }
    }

    private func executeInternal(userData: Any?)
    {
        let index = self.taskItems.count

        let task = Task(index: index, timeInterval: timeInterval, userData: userData)
        {
            [weak self] (index: Int) in

            self?.processTask(index: index)
        }

        self.taskItems.append(task)
    
        task.start()
    }
    
    private func isTaskLast(index: Int) -> Bool
    {
        if let last_item = self.taskItems.last
        {
            return (last_item.index == index)
        }
        
        return false
    }
    
    private func processTask(index: Int)
    {
        self.serialQueue.sync
        {
            [weak self] in

            guard let this = self else
            {
                return
            }

            if let task_item = this.taskItems.last
            {
                let is_last_item = (task_item.index == index)
                
                if is_last_item
                {
                    if let callback = this.callback
                    {
                        callback(task_item.userData)
                    }

                    this.taskItems.removeAll()
                }
            }
        }
    }
}
