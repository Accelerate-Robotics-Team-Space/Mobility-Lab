// swiftlint:disable:this file_name
//  Copyright © 2026 Atlas LiftTech. All rights reserved.
//

import GRDB

final class Initial_20260203: Migration {

    // Combination of all existing migrations applied in order up to 'AltDbV10'.
    override func perform(on database: Database) throws {
        try database.create(table: "hospitalUnit", options: .ifNotExists) { table in
            table.column("facilityUnitId", .text).primaryKey(onConflict: .replace)
            table.column("facilityId", .text).notNull()
            table.column("departmentId", .text).notNull()
            table.column("name", .text)
            table.column("status", .text)
            table.column("lastModified", .date).notNull()
            table.column("lastModifiedBy", .text)
            table.column("serverLastModified", .date).notNull()
        }

        try database.create(table: "hospitalRoomBed", options: .ifNotExists) { table in
            table.column("id", .text).primaryKey(onConflict: .replace)
            table.column("facilityUnitId", .text)
                .notNull()
                .references("hospitalUnit", onDelete: .cascade)
            table.column("roomBedNumber", .text)
            table.column("status", .text)
            table.column("lastModified", .date).notNull()
            table.column("lastModifiedBy", .text)
            table.column("serverLastModified", .date).notNull()
        }

        try database.create(table: "altPatient", options: .ifNotExists) { table in
            table.column("patientId", .text).primaryKey(onConflict: .replace)
            table.column("hospitalRoomBedId", .text)
                .notNull()
                .references("hospitalRoomBed", onDelete: .cascade)
            table.column("heightIn", .integer).notNull()
            table.column("weightLbs", .integer).notNull()
            table.column("sex", .text).notNull()
            table.column("bmi", .double).notNull()
            table.column("createdAt", .date).notNull()
            table.column("isSynced", .boolean).notNull()
            table.column("props", .text).defaults(to: "").notNull()
            table.column("hasPaceMaker", .boolean).defaults(to: false).notNull()
            table.column("hasSternumSkinBroken", .boolean).defaults(to: false).notNull()
            table.column("altPatientId", .text).defaults(to: "")
            table.column("sensorLocation", .text).defaults(to: "")
        }

        try database.create(table: "altSession", options: .ifNotExists) { table in
            table.column("sessionId", .text).primaryKey(onConflict: .replace)
            table.column("patientId", .text)
                .notNull()
                .references("altPatient", onDelete: .cascade)
            table.column("turningProtocol", .integer).notNull()
            table.column("positionsToAvoid", .integer).notNull()
            table.column("hasEnded", .boolean).notNull()
        }

        try database.create(table: "revokedCertificate", options: .ifNotExists) { table in
            table.column("CertificateSerialNumber", .integer).primaryKey(onConflict: .ignore)
            table.column("RevokedOn", .text).notNull()
            table.column("RevokedBy", .text).notNull()
            table.column("Reason", .text).notNull()
        }

        try database.create(table: "altActivityLog", options: .ifNotExists) { table in
            table.autoIncrementedPrimaryKey("activityLogId")
            table.column("patientId", .text)
                .notNull()
                .references("altPatient", onDelete: .cascade)
            table.column("sessionId", .text)
                .notNull()
                .references("altSession", onDelete: .cascade)
            table.column("actualPositionStarted", .datetime).notNull()
            table.column("actualPositionEnded", .datetime).notNull()
            table.column("actualPosition", .text)
            table.column("startingTargetPosition", .text)
            table.column("startingTimeRemaining", .double)
            table.column("endingTimeRemaining", .double)
            table.column("hospitalRoomBedId", .text)
            table.column("mqttTopicStr", .text).notNull()
            table.column("isSynced", .boolean).notNull()
            table.column("isCurrent", .boolean).notNull()
            table.column("bmmMonitoringState", .text).defaults(to: "").notNull()
            table.column("bmmPauseReason", .text).defaults(to: "").notNull()
            table.column("isWrongPosition", .boolean).defaults(to: false).notNull()
            table.column("updateId", .text).defaults(to: "")
            table.column("headOfBedAngle", .integer)
            table.column("turnAngle", .integer)
            table.column("endingTargetPosition", .text)
        }

        try database.create(table: "bmmErrorLog", options: .ifNotExists) { table in
            table.autoIncrementedPrimaryKey("id")
            table.column("deviceUUID", .text).notNull()
            table.column("dateCreated", .datetime).notNull()
            table.column("error", .text).notNull()
            table.column("isSynced", .boolean).notNull()
        }

        try database.create(table: "consoleLogItem", options: .ifNotExists) { table in
            table.autoIncrementedPrimaryKey("id")
            table.column("message", .text).notNull()
            table.column("date", .datetime).notNull()
        }
    }
}
