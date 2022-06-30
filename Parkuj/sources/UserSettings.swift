//
//  UserSettings.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 03/01/2021.
//

import Foundation
import os

struct UserSettings
{
    private static let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "UserSettings")

    private static var locationManagerUpdatingMode_KEY = "location_manager_updating_mode"
    
    ///LOCATION_MANAGER_UPDATING_MODE
    static var locationManagerUpdatingMode: LocationManager.UpdatingMode
    {
        set
        {
            let defaults = UserDefaults.standard
            defaults.set(newValue.rawValue, forKey: locationManagerUpdatingMode_KEY)
            
            logger.info("[SET] \(locationManagerUpdatingMode_KEY.uppercased()): \(newValue.rawValue.uppercased())")
        }
        get
        {
            let defaults = UserDefaults.standard
            if let string = defaults.string(forKey: locationManagerUpdatingMode_KEY)
            {
                if let value = LocationManager.UpdatingMode.init(rawValue: string)
                {
                    return value
                }
            }
            return LocationManager.UpdatingMode.Disabled
        }
    }
}
