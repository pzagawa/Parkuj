//
//  Utils.swift
//  ParkingManager
//
//  Created by Piotr Zagawa on 07/09/2020.
//  Copyright © 2020 Piotr Zagawa. All rights reserved.
//

import Foundation

extension FloatingPoint
{
    var deg2Rad: Self { self * .pi / 180 }
    var rad2Deg: Self { self * 180 / .pi }
}

class Timestamp
{
    static var dateFormatter: DateFormatter =
    {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
    
    static var text: String
    {
        return dateFormatter.string(from: Date())
    }
}

class Utils
{
    static func waitSeconds(seconds: Double)
    {
        let waitObject = DispatchSemaphore(value: 0)

        let time = DispatchTime.now() + seconds

        DispatchQueue.global().asyncAfter(deadline: time)
        {
            waitObject.signal()
        }

        waitObject.wait()
    }
}
