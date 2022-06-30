//
//  Navigator.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 08/12/2020.
//

import Foundation
import MapKit
import os

class Navigator
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "Navigator")

    private func launchOptions(targetPlace: TargetPlace) -> [String : Any]
    {
        let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]

//        let regionDistance:CLLocationDistance = 10000
//        let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
//
//        let options =
//        [
//            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
//            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
//        ]

        return options
    }

    private func openAppleMaps(scene: UIScene, targetPlace: TargetPlace) -> Bool
    {
        let options = launchOptions(targetPlace: targetPlace)

        targetPlace.mapItem.openInMaps(launchOptions: options, from: scene)
        {
            [weak self] (result: Bool) in

            self?.logger.debug("openAppleMaps: completed: \(result).")
        }

        return true
    }
    
    private func canOpenGoogleMaps() -> Bool
    {
        let scheme = "comgooglemaps://"
        
        if let google_maps_url = URL(string: scheme)
        {
            if UIApplication.shared.canOpenURL(google_maps_url)
            {
                return true
            }
        }
        
        return false
    }

    private func openGoogleMaps(targetPlace: TargetPlace) -> Bool
    {
        let coords: CLLocationCoordinate2D = targetPlace.location.coordinate

        let string = "comgooglemaps://?saddr=&daddr=\(coords.latitude),\(coords.longitude)&directionsmode=driving"

        if let url = URL(string: string)
        {
            let options: [UIApplication.OpenExternalURLOptionsKey : Any] = [:]

            UIApplication.shared.open(url, options: options)
            {
                [weak self] (result: Bool) in

                self?.logger.debug("openGoogleMaps: completed: \(result).")
            }
            
            return true
        }

        return false
    }

    public func openMap(scene: UIScene, targetPlace: TargetPlace) -> Bool
    {
        logger.info("openMap..")

        if canOpenGoogleMaps()
        {
            logger.info("- opening Google Maps..")

            return openGoogleMaps(targetPlace: targetPlace)
        }
        else
        {
            logger.info("- opening Apple Maps..")

            return openAppleMaps(scene: scene, targetPlace: targetPlace)
        }
    }
}
