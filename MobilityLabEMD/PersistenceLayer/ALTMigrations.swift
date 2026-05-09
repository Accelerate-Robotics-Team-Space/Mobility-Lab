//
//  ALTMigrations.swift
//  MobilityLabEMD
//
//  Created by Nguyen Bui on 10/20/22.
//  Copyright © 2022 Atlas LiftTech. All rights reserved.
//

import GRDB

class ALTMigrations {
    static let shared = ALTMigrations()
    
    private init() {}
    
    var all: [String: (Database) throws -> Void] {
        var allMigrations: [String: (Database) throws -> Void] = [:]

        allMigrations["AltDbV1"] = { store in
            try store.create(table: "hospitalUnit") { table in
                table.column("facilityUnitId", .text)
                    .primaryKey(onConflict: .replace)
                table.column("facilityId", .text)
                    .notNull()
                table.column("departmentId", .text)
                    .notNull()
                table.column("name", .text)
                table.column("status", .text)
                table.column("lastModified", .date)
                    .notNull()
                table.column("lastModifiedBy", .text)
                table.column("serverLastModified", .date)
                    .notNull()
            }
            
            try store.create(table: "hospitalRoomBed") { table in
                table.column("id", .text)
                    .primaryKey(onConflict: .replace)
                table.column("facilityUnitId", .text)
                    .notNull()
                    .references("hospitalUnit", onDelete: .none)
                table.column("roomBedNumber", .text)
                table.column("status", .text)
                table.column("lastModified", .date)
                    .notNull()
                table.column("lastModifiedBy", .text)
                table.column("serverLastModified", .date)
                    .notNull()
            }
        }
        
        allMigrations["AltDbV2"] = { store in
            try store.create(table: "revokedCertificate") { table in
                table.column("CertificateSerialNumber", .integer)
                    .primaryKey(onConflict: .ignore)
                table.column("RevokedOn", .text)
                    .notNull()
                table.column("RevokedBy", .text)
                    .notNull()
                table.column("Reason", .text)
                    .notNull()
            }
        }
        
        allMigrations["AltDbV3"] = { store in
            try store.create(table: "ummErrorLog") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("deviceUUID", .text)
                    .notNull()
                table.column("dateCreated", .datetime)
                    .notNull()
                table.column("error", .text)
                    .notNull()
                table.column("isSynced", .boolean)
                    .notNull()
            }
        }

        allMigrations["AltDbV3.1"] = { store in
            try store.create(table: "consoleLogItem") { table in
                table.autoIncrementedPrimaryKey("id")
                table.column("message", .text)
                    .notNull()
                table.column("date", .datetime)
                    .notNull()
            }
        }

        return allMigrations
    }
}
