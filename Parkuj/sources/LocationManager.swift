//
//  LocationManager.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 21/10/2020.
//

import Foundation
import CoreLocation
import MapKit
import os

class LocationManager: NSObject, CLLocationManagerDelegate
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "LocationManager")

    static let instance = LocationManager()

    enum UpdatingMode: String
    {
        case Once; case Continuos; case Disabled;
    }
    
    enum ServicesState: String
    {
        case NotDetermined; case Enabled; case Disabled;
    }
    
    enum AuthorizationStatus: String
    {
        case NotDetermined; case Authorized; case Denied;
    }

    enum AuthorizationMode: String
    {
        case Limited; case Full;
    }

    //manager state properties
    var updatingMode = StateProperty<UpdatingMode>("UpdatingMode", defaultValue: .Disabled)
    var servicesState = StateProperty<ServicesState>("ServicesState", defaultValue: .NotDetermined)
    var authorizationStatus = StateProperty<AuthorizationStatus>("AuthorizationStatus", defaultValue: .NotDetermined)
    var fullAccuracy = StateProperty<Bool>("FullAccuracy", defaultValue: false)
    
    //property for callback asking user in UI to allow location sharing
    var userAuthorization = StateProperty<AuthorizationStatus>("UserAuthorization", defaultValue: .NotDetermined)

    //incoming location callback
    var incomingLocation = StateProperty<CLLocation>("IncomingLocation", defaultValue: CLLocation())

    private var locationManager: CLLocationManager?
    private let locationData = LocationData()
    
    public func initialize()
    {
        logger.info("Initializing..")
        
        reset()

        //monitor updating mode property
        updatingMode.add(parent: self)
        {
            (value: LocationManager.UpdatingMode) in
            
            //save last value to user settings
            UserSettings.locationManagerUpdatingMode = value
        }
    }
    
    private func close()
    {
        if let manager = locationManager
        {
            manager.stopUpdatingLocation()
            manager.delegate = nil
        }
    }
    
    private func reset()
    {
        logger.debug("Starting LocationManager..")

        close()
        
        updatingMode.value = .Disabled

        locationManager = CLLocationManager()

        if let manager = locationManager
        {
            manager.delegate = self

            manager.activityType = CLActivityType.automotiveNavigation
            manager.desiredAccuracy = kCLLocationAccuracyBest
            manager.distanceFilter = kCLDistanceFilterNone
            manager.allowsBackgroundLocationUpdates = true
            manager.showsBackgroundLocationIndicator = true
            manager.pausesLocationUpdatesAutomatically = false
        }
    
        logger.debug("Location manager started.")
    }

    func restoreUpdatingMode()
    {
        reset()
        
        logger.debug("Restoring updating mode..")

        let updating_mode = UserSettings.locationManagerUpdatingMode

        logger.debug("- \(updating_mode.rawValue)")

        setUpdates(updatingMode: updating_mode)
    }

    var isUpdating: Bool
    {
        return (updatingMode.value != .Disabled)
    }
    
    var isAuthorized: Bool
    {
        if let manager = locationManager
        {
            let status = manager.authorizationStatus

            if (status == .authorizedAlways || status == .authorizedWhenInUse)
            {
                return true
            }
        }
        
        return false
    }

    var isServicesEnabled: Bool
    {
        return (CLLocationManager.locationServicesEnabled())
    }

    var lastLocation: CLLocation?
    {
        //check if there is location in buffer
        if let location = locationData.lastLocation
        {
            return location
        }
        else
        {
            if let system_location = CLLocationManager().location
            {
                let back_date = Date().addingTimeInterval(-30)
                
                if system_location.timestamp > back_date
                {
                    logger.info("no stored location, getting system location..")

                    return system_location
                }
            }
        }
        
        return nil
    }
    
    var lastMapItem: MKMapItem?
    {
        return locationData.lastMapItem
    }

    private func updateServicesState()
    {
        if (CLLocationManager.locationServicesEnabled())
        {
            servicesState.value = .Enabled
        }
        else
        {
            servicesState.value = .Disabled
        }
    }
    
    func requestUserAuthorization(mode: AuthorizationMode)
    {
        logger.info("Checking authorization..")

        updateServicesState()
        
        if servicesState.value == .Disabled
        {
            logger.error("* services disabled.")
            return
        }
        
        if let manager = locationManager
        {
            let status = manager.authorizationStatus

            if (status == .denied || status == .restricted)
            {
                logger.error("* denied / restricted.")

                userAuthorization.value = .Denied
                
                return
            }

            //ask user for LIMITED permission
            if mode == .Limited
            {
                if (status == .notDetermined || status == .authorizedWhenInUse)
                {
                    logger.info("* requesting user authorization: \(mode.rawValue)..")
                    manager.requestWhenInUseAuthorization()
                    userAuthorization.value = .NotDetermined
                    return
                }
            }

            //ask user for FULL permission
            if mode == .Full
            {
                if (status == .notDetermined || status == .authorizedWhenInUse)
                {
                    logger.info("* requesting user authorization: \(mode.rawValue)..")
                    manager.requestAlwaysAuthorization()
                    userAuthorization.value = .NotDetermined
                    return
                }
            }
        }
        else
        {
            logger.error("* failed. Manager not initialized.")
        }
    }
    
    private func updateRecentOnce(location: CLLocation)
    {
        updatingMode.value = .Once

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25)
        {
            [weak self] in
            self?.incomingLocation.value = location
            self?.updatingMode.value = .Disabled
        }
    }

    // MARK: SET UPDATES

    func setUpdates(updatingMode: UpdatingMode)
    {
        //check manager
        if locationManager == nil
        {
            logger.error("setUpdates: manager not initialized.")
            return
        }

        ///STOP UPDATES
        if updatingMode == .Disabled
        {
            stopUpdates()
            return
        }

        //check services
        updateServicesState()
        
        if servicesState.value == .Disabled
        {
            logger.error("setUpdates: services disabled.")
            return
        }

        //check authorization status
        if isAuthorized == false
        {
            logger.error("setUpdates: not authorized.")
            return
        }

        ///START UPDATES ONCE
        if updatingMode == .Once
        {
            //check if last location recent
            if let last_update_seconds = locationData.lastUpdateSeconds
            {
                if (last_update_seconds < 15)
                {
                    if let location = locationData.lastLocation
                    {
                        updateRecentOnce(location: location)
                        return
                    }
                }
            }

            startUpdatesOnce()
            return
        }

        ///START UPDATES CONTINUOS
        if updatingMode == .Continuos
        {
            startUpdatesContinuos()
            return
        }
    }
    
    private func startUpdatesOnce()
    {
        if updatingMode.value == .Once
        {
            return
        }
    
        if let manager = locationManager
        {
            if isAuthorized
            {
                //get last location first on app init
                if let last_location = manager.location
                {
                    updateLocation(manager: manager, locations: [last_location])
                }
            
                //set updates
                updatingMode.value = .Once
                
                locationData.reset()
                
                manager.requestLocation()
            }
            else
            {
                logger.error("startUpdatesOnce: failed authorization: \(self.authorizationStatusText).")
            }
        }
    }

    private func startUpdatesContinuos()
    {
        if updatingMode.value == .Continuos
        {
            return
        }

        if let manager = locationManager
        {
            if isAuthorized
            {
                updatingMode.value = .Continuos
                
                locationData.reset()

                manager.startUpdatingLocation()
            }
            else
            {
                logger.error("startUpdatesContinuos: failed authorization: \(self.authorizationStatusText).")
            }
        }
    }
    
    private func stopUpdates()
    {
        if updatingMode.value == .Disabled
        {
            return
        }

        if let manager = locationManager
        {
            manager.stopUpdatingLocation()
         
            updatingMode.value = .Disabled
        }
    }
    
    var authorizationStatusText: String
    {
        guard let manager = locationManager else
        {
            return "<manager_not_initialized>"
        }
    
        switch manager.authorizationStatus
        {
        case .notDetermined:
            return "notDetermined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .authorizedAlways:
            return "authorizedAlways"
        case .authorizedWhenInUse:
            return "authorizedWhenInUse"
        @unknown default:
            return "<invalid>"
        }
    }
    
    var accuracyAuthorizationText: String
    {
        guard let manager = locationManager else
        {
            return "<manager_not_initialized>"
        }

        switch manager.accuracyAuthorization
        {
        case .fullAccuracy:
            return "fullAccuracy"
        case .reducedAccuracy:
            return "reducedAccuracy"
        @unknown default:
            return "<invalid>"
        }
    }
    
    // MARK: CL DELEGATE
    
    //Always called, when the user’s action results in an authorization status change, and when your app creates an instance of CLLocationManager
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager)
    {
        logger.debug("DidChangeAuthorization. Status: \(self.authorizationStatusText). Accuracy: \(self.accuracyAuthorizationText).")

        fullAccuracy.value = (manager.accuracyAuthorization == .fullAccuracy)
        
        let status = manager.authorizationStatus

        //disabled
        if (status == .denied || status == .restricted)
        {
            authorizationStatus.value = .Denied
            updatingMode.value = .Disabled
        }

        //not determined
        if (status == .notDetermined)
        {
            authorizationStatus.value = .NotDetermined
            updatingMode.value = .Disabled
        }

        //authorized
        if (status == .authorizedAlways || status == .authorizedWhenInUse)
        {
            authorizationStatus.value = .Authorized
            userAuthorization.value = .Authorized

            AppStartup.instance.StartLocationManagerUpdatesOnce()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        updateLocation(manager: manager, locations: locations)
    }

    private func updateLocation(manager: CLLocationManager, locations: [CLLocation])
    {
        let added_count = locationData.update(locations: locations)
        
        if added_count > 0
        {
            if let location = locationData.lastLocation
            {
                incomingLocation.value = location

                if updatingMode.value == .Once
                {
                    updatingMode.value = .Disabled
                }
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        logger.debug("* DidFailWithError. Error: \(error.localizedDescription).")

        if let cl_error = error as? CLError
        {
            //access to location or ranging has been denied by the user
            if cl_error.code == CLError.Code.denied
            {
                updatingMode.value = .Disabled
            }

            //authorization request not presented to user
            if cl_error.code == CLError.Code.promptDeclined
            {
                updatingMode.value = .Disabled
            }
            
            //location is currently unknown, but CL will keep trying
            if cl_error.code == CLError.Code.locationUnknown
            {
                //handle location reading error
            }

            //general, network-related error
            if cl_error.code == CLError.Code.network
            {
                //handle network error
            }
        }
    }
}
