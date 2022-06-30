//
//  UserDatabase.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 29/11/2020.
//

import Foundation
import SQLite
import os

class UserDatabase: Database
{
    private let addressPlacemarkTable = AddressPlacemarkTable()

    override init()
    {
    }
    
    override func onCreateTables(connection: Connection)
    {
        addressPlacemarkTable.createTable(connection: connection)
    }
    
    func insertAddressPlacemark(placemark: AddressPlacemark)
    {
        if let connection = sqlConnection
        {
            addressPlacemarkTable.insertItem(connection: connection, item: placemark)
        }
    }

    func getAddressPlacemark(location_key: String) -> AddressPlacemark?
    {
        var placemark_item: AddressPlacemark?

        if let connection = sqlConnection
        {
            placemark_item = addressPlacemarkTable.selectRow(connection: connection, location_key: location_key)
        }
        
        return placemark_item
    }
}
