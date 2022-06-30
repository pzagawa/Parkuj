//
//  ActionController.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 01/11/2020.
//

import Foundation
import Combine
import os

class ActionController: ObservableObject
{
    static let instance = ActionController()
    
    private let logger = Logger(subsystem: App.BUNDLE_ID, category: "ActionController")
   
    @Published var updatingMode: LocationManager.UpdatingMode = LocationManager.UpdatingMode.Disabled
    @Published var servicesState: LocationManager.ServicesState = LocationManager.ServicesState.NotDetermined
    @Published var authorizationStatus: LocationManager.AuthorizationStatus = LocationManager.AuthorizationStatus.NotDetermined
    @Published var fullAccuracy: Bool = false

    init()
    {
        logger.info("Creating..")
    }

    public func initialize()
    {
        logger.info("Initializing.")

        LocationManager.instance.updatingMode.callback =
        {
            [weak self] (value: LocationManager.UpdatingMode) in
            self?.updatingMode = value
        }

        LocationManager.instance.servicesState.callback =
        {
            [weak self] (value: LocationManager.ServicesState) in
            self?.servicesState = value
        }
        
        LocationManager.instance.authorizationStatus.callback =
        {
            [weak self] (value: LocationManager.AuthorizationStatus) in
            self?.authorizationStatus = value
        }

        LocationManager.instance.fullAccuracy.callback =
        {
            [weak self] (value: Bool) in
            self?.fullAccuracy = value
        }

        LocationManager.instance.requestAuthorization.callback =
        {
            [weak self] (value: LocationManager.AuthorizationStatus) in
            
            if (value == .NotDetermined)
            {
                self?.logger.info("[UI] Ask user to authorize location sharing")
            }

            if (value == .Denied)
            {
                self?.logger.info("[UI] Ask user to allow location sharing")
            }
        }
    }

    public func locationUpdates(enabled: Bool)
    {
        if (enabled)
        {
            if LocationManager.instance.isUpdating == false
            {
                LocationManager.instance.start()
            }
        }
        else
        {
            if LocationManager.instance.isUpdating == true
            {
                LocationManager.instance.stop()
            }
        }
    }
}
