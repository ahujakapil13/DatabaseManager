//
//  DatabaseManager.swift
//  XMLParsingDemo
//
//  Created by Mac mini on 16/09/16.
//  Copyright © 2016 SIPL. All rights reserved.
//

import Foundation

class DatabaseManager: NSObject {
    
    static let sharedInstance = DatabaseManager()
    
    var db: OpaquePointer? = nil
    var counter = 0
    
    func openDatabase() -> OpaquePointer? {
        
        if db == nil {
            let bundlePath = Bundle.main.bundlePath
            let part1DbPath = bundlePath + "/Database.sql"
            
            if sqlite3_open(part1DbPath, &db) == SQLITE_OK {
                print("Successfully opened connection to database at \(part1DbPath)")
                
                let tableDetail:NSArray = query(["name"], FROM: "sqlite_master", WHERE: "type='table' AND name='FileDetails'")
                
                if tableDetail.count != 3 {
                    createTable("FileDetails", Fields: "ID INTEGER PRIMARY KEY AUTOINCREMENT,serial_number TEXT NOT NULL UNIQUE,registration_number TEXT,transaction_date TEXT NOT NULL")
                }
                
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("Unable to open database. Verify that you created the directory described " +
                    "in the Getting Started section. Error: \(errorMessage)")
            }
        }
        return db!
    }
    
    func createTable(_ TableName: String, Fields: String) -> Bool {
        var success: Bool = false
        
        if db != nil {
            
            let createTableString = "CREATE TABLE \(TableName)(\(Fields));"
            // 1
            var createTableStatement: OpaquePointer? = nil
            // 2
            if sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK {
                // 3
                if sqlite3_step(createTableStatement) == SQLITE_DONE {
                    print("\(TableName) table created.")
                    success = true
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print("\(TableName) table could not be created. Error: \(errorMessage)")
                    success = false
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("CREATE TABLE statement could not be prepared. Error: \(errorMessage)")
                success = false
            }
            // 4
            sqlite3_finalize(createTableStatement)
        }else{
            
        }
        
        
        return success
    }
    
    func insert(_ TableName: String, ColumnsAndValues: NSDictionary) {
        
        if openDatabase() != nil {
            counter = 0
            let columns = ColumnsAndValues.allKeys
            
            var columnsStr = ""
            var valuesStr = ""
            
            for (index, columnKey) in columns.enumerated() {
                
                if index == (columns.count-1) {
                    columnsStr = columnsStr + (columnKey as! String)
                    valuesStr = valuesStr + "'\(ColumnsAndValues.object(forKey: columnKey)!)'"
                }else{
                    columnsStr = columnsStr + "\(columnKey),"
                    valuesStr = valuesStr + "'\(ColumnsAndValues.object(forKey: columnKey)!)',"
                }
            }
            
            let insertStatementString = "INSERT INTO \(TableName) (\(columnsStr)) VALUES (\(valuesStr));"
            var insertStatement: OpaquePointer? = nil
            
            // 1
            if sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK {
                
                // 4
                if sqlite3_step(insertStatement) == SQLITE_DONE {
                    print("Successfully inserted row.")
                } else {
                    let errorMessage = String(cString: sqlite3_errmsg(db))
                    print("Could not insert row. Error: \(errorMessage)")
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("INSERT statement could not be prepared. Error: \(errorMessage)")
            }
            // 5
            sqlite3_finalize(insertStatement)
        }else{
            openDatabase()
            counter = counter + 1
            if counter >= 5 {
                print("Error in connecting to Database.")
                return
            }/*else{
                insert(TableName, ColumnsAndValues: ColumnsAndValues)
            }*/
        }
    }
    
    func query(_ SELECT: [NSString], FROM: String, WHERE: String) -> NSMutableArray {
        
        let resultArry: NSMutableArray = NSMutableArray()
        
        if openDatabase() != nil {
            counter = 0
            
            var selectStr: String = ""
            for (index, name) in SELECT.enumerated() {
                if index == (SELECT.count-1) {
                    selectStr = selectStr + (name as String)
                }else{
                    selectStr = selectStr + "\(name),"
                }
            }
            
            var queryStatementString = "SELECT \(selectStr) FROM \(FROM);"
            
            if WHERE != "" {
                queryStatementString = queryStatementString + " WHERE \(WHERE)"
            }
            
            var queryStatement: OpaquePointer? = nil
            // 1
            if sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK {
                // 2
                
                while (sqlite3_step(queryStatement) == SQLITE_ROW) {
                    let resutDict = NSMutableDictionary()
                    
                    for i in 0 ..< sqlite3_data_count(queryStatement) {
                        
                        let queryResultCol = sqlite3_column_text(queryStatement, i)
                        let value = String(cString: queryResultCol!)
//                      let value = String(cString: UnsafePointer<CChar>(queryResultCol!))
                        let name = sqlite3_column_name(queryStatement, i)
                        let key = String(cString: UnsafePointer<CChar>(name!))
                        
                        resutDict.setObject(value, forKey: key as NSCopying)
                    }
                    
                    resultArry.add(resutDict)
                }
            } else {
                let errorMessage = String(cString: sqlite3_errmsg(db))
                print("SELECT statement could not be prepared. Error: \(errorMessage)")
            }
            
            // 6
            sqlite3_finalize(queryStatement)
            
        }else{
            openDatabase()
            counter = counter + 1
            if counter >= 5 {
                print("Error in connecting to Database.")
                resultArry.add("Error in connecting to Database.")
                return resultArry
            }
        }
        
        return resultArry
    }
    
    func update() {
        let updateStatementString = "UPDATE Contact SET Name = 'Chris' WHERE Id = 1;"
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementString, -1, &updateStatement, nil) == SQLITE_OK {
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                print("Successfully updated row.")
            } else {
                print("Could not update row.")
            }
        } else {
            print("UPDATE statement could not be prepared")
        }
        sqlite3_finalize(updateStatement)
    }
    
    func delete() {
        let deleteStatementStirng = "DELETE FROM Contact WHERE Id = 1;"
        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }
        
        sqlite3_finalize(deleteStatement)
    }
    
    func closeDB() {
        sqlite3_close(db)
    }
    
}
