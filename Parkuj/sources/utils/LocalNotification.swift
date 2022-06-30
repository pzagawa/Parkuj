//
//  LocalNotification.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 02/11/2020.
//

import Foundation
import UserNotifications
import os

class LocalNotification
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "LocalNotification")

    static let instance = LocalNotification()

    private var authorizationGranted: Bool = false

    private func requestAuthorization()
    {
        logger.debug("Requesting authorization..")

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        {
            [weak self] granted, error in

            if granted == true && error == nil
            {
                self?.authorizationGranted = true
                
                self?.logger.debug("- granted.")
            }
        }
    }
    
    func initialize()
    {
        logger.debug("Initializing..")

        UNUserNotificationCenter.current().getNotificationSettings
        {
            [weak self] settings in

            switch settings.authorizationStatus
            {
            case .notDetermined:
                self?.requestAuthorization()
            case .authorized, .provisional:
                self?.logger.debug("- authorized.")
            default:
                break
            }
        }
    }
    
    private func listScheduledNotifications()
    {
        UNUserNotificationCenter.current().getPendingNotificationRequests
        {
            notifications in
            for notification in notifications
            {
                self.logger.debug("- \(notification).")
            }
        }
    }
    
    func debugNotification(text: String)
    {        
        let content = UNMutableNotificationContent()
        content.title = "DEBUG"
        content.body = text
        content.categoryIdentifier = "test_debug"

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request)
    }
}
