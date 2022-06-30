//
//  EmbeddedDatabase.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 07/10/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation
import SQLite
import os

class EmbeddedDatabase: Database
{
    private let versionTable = VersionTable()
    private let placeTable = PlaceTable()

    override init()
    {
    }

    override func onCreateTables(connection: Connection)
    {
        //no creation, R/O database
    }

    func getAllPlaceItems() -> [PlaceItem]
    {
        var list: [PlaceItem] = []

        if let connection = sqlConnection
        {
            list = placeTable.selectAllRows(connection: connection)
        }

        return list
    }
    
    func getPlaceItem(item_id: String) -> PlaceItem?
    {
        var place_item: PlaceItem?

        if let connection = sqlConnection
        {
            place_item = placeTable.selectRow(connection: connection, item_id: item_id)
        }
        
        return place_item
    }
    
    func getAllVersionItems() -> [VersionItem]
    {
        var list: [VersionItem] = []

        if let connection = sqlConnection
        {
            list = versionTable.selectAllRows(connection: connection)
        }

        return list
    }
}
