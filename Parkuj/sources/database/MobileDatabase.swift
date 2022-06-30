//
//  MobileDatabase.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 07/10/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import SQLite
import os

class MobileDatabase
{
    private let logger = Logger(subsystem: App.BUNDLE_ID, category: "MobileDatabase")

    private var readOnlyMode: Bool = false
    private var dbConnection: Connection?
    private let versionTable = VersionTable()
    private let placeTable = PlaceTable()

    init()
    {
    }

    var embeddedDatabasePath: String
    {
        if let path = Bundle.main.path(forResource: "mobile_database", ofType: "sqlite3")
        {
            logger.info("File: \(path).")
            return path
        }
        else
        {
            logger.info("File not found.")
            return ""
        }
    }
    
    func openEmbeddedDatabase() -> Bool
    {
        return open(filename: embeddedDatabasePath, read_only: true)
    }

    func open(filename: String, read_only: Bool) -> Bool
    {
        if isOpened
        {
            return true
        }
        
        self.readOnlyMode = read_only
        self.dbConnection = try? Connection(filename, readonly: read_only)

        if isOpened
        {
            create()
            return true
        }

        logger.error("Open FAILED.")
        return false
    }
            
    var isOpened: Bool
    {
        return (self.dbConnection != nil)
    }
    
    func create()
    {
        if readOnlyMode
        {
            return
        }

        logger.info("Creating..")
        
        if let connection = dbConnection
        {
            placeTable.createTable(connection: connection)
        }
    }
    
    func insertItem(item: PlaceItem)
    {
        if let connection = dbConnection
        {
            placeTable.insertItem(connection: connection, item: item)
        }
    }
    
    func insertItems(items: [PlaceItem])
    {
        logger.info("Inserting rows: \(PlaceTable.Type.self)..")

        for item: PlaceItem in items
        {
            insertItem(item: item)
        }

        logger.info("Done. Inserted \(items.count) rows.")
    }

    func getAllPlaceItems() -> [PlaceItem]
    {
        var list: [PlaceItem] = []

        if let connection = dbConnection
        {
            logger.debug("Select all: PlaceItem...")

            list = placeTable.selectAllRows(connection: connection)
        }

        return list
    }
    
    func getPlaceItem(item_id: String) -> PlaceItem?
    {
        var place_item: PlaceItem?

        if let connection = dbConnection
        {
            logger.debug("Selecting PlaceItem: \(item_id)..")

            place_item = placeTable.selectRow(connection: connection, item_id: item_id)
        }
        
        return place_item
    }
    
    func getAllVersionItems() -> [VersionItem]
    {
        var list: [VersionItem] = []

        if let connection = dbConnection
        {
            logger.debug("Select all: VersionItem...")

            list = versionTable.selectAllRows(connection: connection)
        }

        return list
    }
}
