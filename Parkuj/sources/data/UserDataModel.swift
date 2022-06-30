//
//  UserDataModel.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 29/11/2020.
//

import Foundation
import CoreLocation
import os

class UserDataModel
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "UserDataModel")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.UserDataModel")
 
    static let instance = UserDataModel()

    typealias InitCompleted = () -> Void

    private let userDatabase = UserDatabase()

    private init()
    {
    }

    func initialize(callback: @escaping InitCompleted)
    {
        if userDatabase.openUserDatabase() == false
        {
            return
        }
     
        serialQueue.sync
        {
            ///Load all static tables items here

            callback()
        }
    }

    func insertAddressPlacemark(placemark: AddressPlacemark)
    {
        userDatabase.insertAddressPlacemark(placemark: placemark)
    }
    
    func addressPlacemark(location_key: String) -> AddressPlacemark?
    {
        return userDatabase.getAddressPlacemark(location_key: location_key)
    }
}
