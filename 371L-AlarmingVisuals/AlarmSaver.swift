//
//  AlarmSaver.swift
//  371L-AlarmingVisuals
//
//  Created by Daniel Jeng on 10/31/23.
//

import Foundation

protocol AlarmSaver {
    func addAlarm(alarm: Alarm)
    func editAlarm(alarm: Alarm)
}
