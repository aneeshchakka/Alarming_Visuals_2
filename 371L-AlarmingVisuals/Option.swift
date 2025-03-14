//
//  Option.swift
//  371L-AlarmingVisuals
//
//  Created by Manuel Torralba on 10/13/23.
//

import Foundation

// Used predominantly by the Alarm class
class Option{
    var optionLabel:String = ""
    var optionSelected:String = ""
        
    init(optionLabel: String, optionSelected: String){
        self.optionLabel = optionLabel
        self.optionSelected = optionSelected
    }
}
