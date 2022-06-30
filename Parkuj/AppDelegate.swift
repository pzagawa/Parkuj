//
//  AppDelegate.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 10/10/2020.
//

import UIKit
import os

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "AppDelegate")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        ///Starting app..
        logger.info("Starting app..")

        ///Check if location key exist in launch options map to signal restart for background location updates
        var restart_location_services = false
        
        if let launch_options = launchOptions
        {
            if (launch_options[UIApplication.LaunchOptionsKey.location] != nil)
            {
                restart_location_services = true
            }
        }

        if restart_location_services
        {
            ///Restart location services only
            logger.notice("* restarting location manager..")
            
            LocationManager.instance.restoreUpdatingMode()
        }
        else
        {
            ///Default initialization
            AppStartup.instance.InitEmbeddedDataModel()
            AppStartup.instance.InitUserDataModel()
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration
    {
        logger.info("App connects session: \(connectingSceneSession.role.rawValue)")
        
        var scene_configuration = "Default Configuration"
                
        if connectingSceneSession.role.rawValue == "CPTemplateApplicationSceneSessionRoleApplication"
        {
            scene_configuration = "CarPlay Configuration"
        }

        // Called when a new scene session is being created. Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: scene_configuration, sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>)
    {
        logger.info("App discards sessions: \(sceneSessions.count)")
        
        for session in sceneSessions
        {
            logger.info("- \(session.role.rawValue)")
        }

        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}
