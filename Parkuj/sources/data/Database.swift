//
//  Database.swift
//  Parkuj
//
//  Created by Piotr Zagawa on 29/11/2020.
//

import Foundation
import SQLite
import os

class Database
{
    private let logger = Logger(subsystem: AppData.BUNDLE_ID, category: "Database")

    private var readOnlyMode: Bool = false
    
    var sqlConnection: Connection?

    init()
    {
    }

    private var embeddedDatabasePath: String
    {
        if let path = Bundle.main.path(forResource: "mobile_database", ofType: "sqlite3")
        {
            logger.info("EMBD DB file \(path).")
            return path
        }
        else
        {
            logger.warning("EMBD DB: file not found.")
            return ""
        }
    }

    var userDatabasePath: String
    {
        let file_name = "user_database.sqlite3"

        let url_list = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
        
        if url_list.count > 0
        {
            if let url = url_list.first
            {
                let path = url.appendingPathComponent(file_name).path

                logger.info("USER DB file \(path).")
                return path;
            }
        }
        
        logger.warning("USER DB: file not found.")
        return ""
    }

    func openEmbeddedDatabase() -> Bool
    {
        return open(filename: embeddedDatabasePath, read_only: true)
    }

    func openUserDatabase() -> Bool
    {
        return open(filename: userDatabasePath, read_only: false)
    }

    private func open(filename: String, read_only: Bool) -> Bool
    {
        if isOpened
        {
            return true
        }
        
        self.readOnlyMode = read_only
        self.sqlConnection = try? Connection(filename, readonly: read_only)

        if isOpened
        {
            create()
            return true
        }

        logger.error("Open FAILED.")
        return false
    }
            
    var isOpened: Bool
    {
        return (self.sqlConnection != nil)
    }
    
    func create()
    {
        if readOnlyMode
        {
            return
        }

        logger.info("Creating tables..")
        
        if let connection = sqlConnection
        {
            onCreateTables(connection: connection)
        }
    }

    func onCreateTables(connection: Connection)
    {
        fatalError("onCreateTables - NEED OVERRIDE. \(connection.description)")
    }
}
