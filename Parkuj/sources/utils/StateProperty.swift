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
    
    struct ObserverItem
    {
        let key: String
        let callback: Callback
    }

    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "StateProperty")

    private let name: String
    private let defaultValue: T

    private let calendar = Calendar.current
    private var lastUpdate: Date?
    
    private var observers: [ObserverItem] = []

    var value: T
    {
        didSet
        {
            //fire callback on value change
            notify()
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
        observers.removeAll()
    }
    
    func reset()
    {
        self.value = defaultValue
    }

    func notify()
    {
        let text_value = String(describing: self.value).uppercased()

        logger.debug("* StateProperty \(self.name) = \(text_value).")

        for item in observers
        {
            item.callback(self.value)
        }

        self.lastUpdate = Date()
    }

    var lastUpdateSeconds: TimeInterval?
    {
        if let date = lastUpdate
        {
            let now = Date()
            return now.timeIntervalSince(date)
        }
        else
        {
            return nil
        }
    }
    
    func add(parent: Any, callback: @escaping Callback)
    {
        let key = String(describing: type(of: parent))

        let filtered = observers.filter { $0.key == key }

        logger.debug("- StateProperty/ADD observer \(key) on \(self.name) [\(filtered.count)].")

        let item: ObserverItem = ObserverItem(key: key, callback: callback)

        observers.append(item)
    }
    
    func remove(parent: Any)
    {
        let key = String(describing: type(of: parent))

        let filtered = observers.filter { $0.key == key }

        logger.debug("- StateProperty/REMOVE observer \(key) on \(self.name) [\(filtered.count)].")

        observers.removeAll { $0.key == key }
    }
}
