//
//  AppStartup.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 23/01/2021.
//

import Foundation
import os

protocol AppStartupTask
{
    func completed()
}
    
class AppStartup: AppStartupTask
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "AppStartup")
    private let serialQueue = DispatchQueue(label: "parkuj.serialqueue.AppStartup")
    private let semaphore = DispatchSemaphore(value: 1)

    static let instance = AppStartup()
        
    init()
    {
    }

    internal func completed()
    {
        self.semaphore.signal()
    }

    typealias TaskHandler = (AppStartupTask) -> Void
    typealias FinishHandler = () -> Void

    private func execute(name: String, taskHandler: @escaping TaskHandler)
    {
        serialQueue.async
        {
            [weak self] in

            guard let this = self else
            {
                return
            }
            
            this.semaphore.wait()

            DispatchQueue.main.async
            {
                this.logger.debug("***")
                this.logger.debug("*** Startup task: \(name).. ***")
                this.logger.debug("***")

                taskHandler(this)
                
                this.logger.debug("---")
                this.logger.debug("--- Task: \(name) DONE ---")
                this.logger.debug("---")
            }
        }
    }

    func InitEmbeddedDataModel()
    {
        execute(name: "InitEmbeddedDataModel")
        {
            (task: AppStartupTask) in

            EmbeddedDataModel.instance.initialize
            {
                task.completed()
            }
        }
    }
    
    func InitUserDataModel()
    {
        execute(name: "InitUserDataModel")
        {
            (task: AppStartupTask) in
        
            UserDataModel.instance.initialize
            {
                task.completed()
            }
        }
    }
    
    func InitLocationManager()
    {
        execute(name: "InitLocationManager")
        {
            (task: AppStartupTask) in

            LocationManager.instance.initialize()
            LocationManager.instance.requestUserAuthorization(mode: .Limited)

            task.completed()
        }
    }

    func InitPhoneApp(handler: @escaping FinishHandler)
    {
        execute(name: "InitPhoneApp")
        {
            (task: AppStartupTask) in

            handler()

            task.completed()
        }
    }

    func UninitPhoneApp(handler: @escaping FinishHandler)
    {
        execute(name: "UninitPhoneApp")
        {
            (task: AppStartupTask) in

            handler()

            task.completed()
        }
    }

    func StopLocationManagerUpdates()
    {
        execute(name: "StopLocationManagerUpdates")
        {
            (task: AppStartupTask) in

            LocationManager.instance.setUpdates(updatingMode: .Disabled)

            task.completed()
        }
    }

    func StartLocationManagerUpdatesOnce()
    {
        execute(name: "StartLocationManagerUpdatesOnce")
        {
            (task: AppStartupTask) in

            LocationManager.instance.setUpdates(updatingMode: .Once)

            task.completed()
        }
    }

    func StartLocationManagerUpdatesContinuos()
    {
        execute(name: "StartLocationManagerUpdatesContinuos")
        {
            (task: AppStartupTask) in

            LocationManager.instance.setUpdates(updatingMode: .Continuos)

            task.completed()
        }
    }
}
