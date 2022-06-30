//
//  CarPlaySceneDelegate.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 11/10/2020.
//

import Foundation
import CarPlay
import os

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "CarPlayApp")

    private let carPlayApp = CarPlayApp()
    
    private var interfaceController: CPInterfaceController?

    // CarPlay connected
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController)
    {
        logger.debug("* AppScene connect: \(interfaceController)")
        
        self.interfaceController = interfaceController
        
        carPlayApp.initialize(scene: templateApplicationScene)
        
        let view = carPlayApp.createTabBarView()
        
        if let controller = self.interfaceController
        {
            logger.debug("- setup interface controller: \(controller)")

            controller.setRootTemplate(view, animated: true)
            {
                [weak self] (success: Bool, error: Error?) in
                
                self?.logger.debug("setRootTemplate: \(success), error: \(error?.localizedDescription ?? "null")")

                ///WARNING: THIS CLOSURE IS NOT CALLED - bug?
            }
        }

        AppStartup.instance.InitLocationManager()
        AppStartup.instance.StartLocationManagerUpdatesOnce()
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController)
    {
        logger.debug("* AppScene disconnect: \(interfaceController)")

        carPlayApp.uninitialize()

        self.interfaceController = nil
    }
}
