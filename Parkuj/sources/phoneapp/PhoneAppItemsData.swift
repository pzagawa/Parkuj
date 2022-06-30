//
//  PhoneAppItemsData.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 08/03/2021.
//

import Foundation
import os

// #MARK: PhoneAppItemsData class

class PhoneAppItemsData
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "PhoneAppItemsData")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.PhoneAppItemsData")

    private var targetPlaces: [TargetPlace] = []

    func reset()
    {
        serialQueue.sync
        {
            targetPlaces = []
            
            logger.notice("reset target places.")
        }
    }
    
    func set(targetPlaces: [TargetPlace])
    {
        serialQueue.sync
        {
            self.targetPlaces = targetPlaces
                        
            logger.notice("set Target Places: \(targetPlaces.count). Hash: \(targetPlaces.hashValue).")
        }
    }

    public var hashValue: Int
    {
        return targetPlaces.hashValue
    }

    var isEmpty: Bool
    {
        var result: Bool = false
        
        serialQueue.sync
        {
            result = targetPlaces.isEmpty
        }
        
        return result
    }
    
    var itemsCount: Int
    {
        var result: Int = 0
        
        serialQueue.sync
        {
            result = targetPlaces.count
        }
        
        return result
    }
    
    var itemsCopy: [TargetPlace]
    {
        var result: [TargetPlace] = []
        
        serialQueue.sync
        {
            result = targetPlaces
        }

        return result
    }
    
    var spanItems: [TargetPlaces.SpanTargetPlaces]
    {
        var result: [TargetPlaces.SpanTargetPlaces] = []

        serialQueue.sync
        {
            result = TargetPlaces.span(targetPlaces: targetPlaces, minCount: 1)
        }
        
        return result
    }
    
    func itemByIndex(itemIndex: Int) -> TargetPlace?
    {
        if itemIndex < 0
        {
            return nil
        }
        
        if itemIndex > (targetPlaces.count - 1)
        {
            return nil
        }

        var result: TargetPlace?

        serialQueue.sync
        {
            result = targetPlaces[itemIndex]
        }

        return result
    }
    
    func debugLog()
    {
        logger.notice("*** Places: \(self.itemsCount) ***")
        
        serialQueue.sync
        {
            for item in targetPlaces
            {
                logger.notice("- \(item.description)")
            }
        }

        logger.notice("*** END ***")
    }
}
