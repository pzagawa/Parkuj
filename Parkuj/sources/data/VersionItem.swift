//
//  VersionItem.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 07/10/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import CryptoKit
import CoreLocation
import SQLite
import os

struct VersionItemFields
{
    let id      = Expression<Int>("id")
    let name    = Expression<String>("name")
    let version = Expression<Int>("version")
    let time    = Expression<String>("time")
}

// #MARK: VersionItem
struct VersionItem: CustomStringConvertible, Equatable
{
    static let fields = VersionItemFields()
    
    let id: Int
    let name: String
    let version: Int
    let time: String

    // #MARK: SQLite ROW INIT
    init(row: Row)
    {
        self.id = row[VersionItem.fields.id]
        self.name = row[VersionItem.fields.name]
        self.version = row[VersionItem.fields.version]
        self.time = row[VersionItem.fields.time]
    }

    var description: String
    {
        return "\(name): \(version). [\(time)]."
    }

    static func ==(lhs: VersionItem, rhs: VersionItem) -> Bool
    {
        if (lhs.id == rhs.id)
        {
            if (lhs.name == rhs.name)
            {
                return true
            }
        }
    
        return false
    }
}

// #MARK: VersionTable
struct VersionTable
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "VersionTable")

    let table = Table("version")
    
    func selectAllRows(connection: Connection) -> [VersionItem]
    {
        var items: [VersionItem] = []
        
        do
        {
            let rows = try connection.prepare(table)

            for row: Row in rows
            {
                let poi_item = VersionItem(row: row)
                items.append(poi_item)
            }
        }
        catch let error
        {
            logger.error("Table select all rows ERROR: \(error.localizedDescription)")
        }
        
        return items
    }
}
