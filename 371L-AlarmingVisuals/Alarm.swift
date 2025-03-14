//
//  Alarm.swift
//  371L-AlarmingVisuals
//
//  Created by Daniel Jeng on 10/11/23.
//

import Foundation

// Alarm class predominantly used by mainVC and create/edit_alarmVC
class Alarm {
    var id: String
    var alarmOn: Bool
    var alarmTime: String = ""
    var alarmName: String = ""
    var alarmSound: String = ""
    var isResolved: Bool
    
    // photoOptions and repeats will probably be redesigned
    var photoOptions: [String: Bool] = [:]
    var repeats: [String: Bool] = [:]
    
    init(id: String, alarmOn: Bool, alarmTime: String, alarmName: String, alarmSound: String, photoOptions: [String: Bool], repeats: [String: Bool], isResolved:Bool) {
        self.id = id
        self.alarmOn = alarmOn
        self.alarmTime = alarmTime
        self.alarmName = alarmName
        self.alarmSound = alarmSound
        self.photoOptions = photoOptions
        self.repeats = repeats
        self.isResolved = isResolved
    }
}
