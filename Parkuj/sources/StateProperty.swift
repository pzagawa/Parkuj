//
//  StateProperty.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 04/11/2020.
//

import Foundation
import os

///Property wrapper for holidng value with optional callback and logging.

class StateProperty<T>
{
    typealias Callback = (T) -> Void

    private let logger = Logger(subsystem: App.BUNDLE_ID, category: "StateProperty")

    private let name: String
    private let defaultValue: T
    
    public var callback: Callback? = nil
    
    var value: T
    {
        didSet
        {
            let text_value = String(describing: self.value).uppercased()

            logger.debug("* StateProperty \(self.name) = \(text_value).")
            
            if let ref = callback
            {
                ref(self.value)
            }
        }
    }

    init(_ name: String, defaultValue: T)
    {
        self.name = name
        self.defaultValue = defaultValue
        self.value = defaultValue
    }
    
    deinit
    {
        callback = nil
    }
    
    func reset()
    {
        self.value = defaultValue
    }
}
