//
//  CreateEditAlarmViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Manuel Torralba on 10/13/23.
//

import UIKit
import AVFoundation
import SwiftUI

class CreateEditAlarmViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, PhotoOptionsSaver, RepeatOptionsSaver, SoundOptionsSaver, UITextFieldDelegate {
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var alarmName: UITextField!
    @IBOutlet weak var optionsTableView: UITableView!
    
    @IBOutlet weak var rightButton: UIBarButtonItem!
    
    var dateFormatter12 = DateFormatter()
    var dateFormatter24 = DateFormatter()
    
    var delegate: MainAlarmViewController?
    
    var alarmIndex = -1
    
    // Default alarm values
    var alarmTime:String = "5:30 AM"
    var alarmNameText:String = ""
    var repeatOptions:[String:Bool] = ["Monday": true, "Tuesday": true, "Wednesday": true, "Thursday": true, "Friday": true, "Saturday": true, "Sunday": true]
    var alarmSound:String = "Rattle"
    var photoOptions:[String:Bool] = [
        "Microwave Oven": true, "Oven": true,"Apple": true, "Toothbrush": true, "Banana": true,"Egg": true,"Frying Pan": true,"Sink": true,"Shoe": true,"Window": true,"Refrigerator": true,"Table": true,"Houseplant": true,"Car": true,"Truck": true,"Wheel": true,"Chair": true
    ]
    var isResolved:Bool = true

    let optionCellIdentifier = "optionCell"
    
    var options = ["Repeat", "Sound", "Photos"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter12.dateFormat = "h:mm a"
        dateFormatter24.dateFormat = "H:mm"
        
        self.title = "create.title".localized
        nameLabel.text = "create.nameLabel".localized
        alarmName.text = alarmNameText
        alarmName.placeholder = "create.placeholder".localized
        
        timePicker.date = dateFormatter12.date(from: alarmTime)!
        alarmName.delegate = self
        optionsTableView.delegate = self
        optionsTableView.dataSource = self
    }
    
    // Gets count for table view of options
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func viewWillAppear(_ animated: Bool) {
        optionsTableView.reloadData()
    }
    
    // Sets the rows for table view of options
    // Does not currently go to the proper options pages, please use buttons instead for viewing those pages
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = optionsTableView.dequeueReusableCell(withIdentifier: optionCellIdentifier,
            for: indexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = "create.\(options[row])".localized
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        
        if options[row] == "Repeat" {
            var days = ""
            for day in repeatOptions {
                if day.1 == true {
                    if days == "" {
                        days = days + "repeat.\(day.0)".localized
                    } else {
                        days = days + ", " + "repeat.\(day.0)".localized
                    }
                }
            }
            cell.detailTextLabel?.text = days
        } else if options[row] == "Sound" {
            cell.detailTextLabel?.text = alarmSound
        } else if options[row] == "Photos" {
            var photoOptionsString = ""
            for option in photoOptions {
                if option.1 == true {
                    if photoOptionsString == "" {
                        photoOptionsString = photoOptionsString + "photo.\(option.0)".localized
                    } else {
                        photoOptionsString = photoOptionsString + ", " + "photo.\(option.0)".localized
                    }
                }
            }
            cell.detailTextLabel?.text = photoOptionsString
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = indexPath.row
        if options[row] == "Repeat" {
            performSegue(withIdentifier: "repeatOptionsSegue", sender: self)
        } else if options[row] == "Sound" {
            performSegue(withIdentifier: "soundOptionsSegue", sender: self)
        } else if options[row] == "Photos" {
            performSegue(withIdentifier: "photoOptionsSegue", sender: self)
        }
        optionsTableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "soundOptionsSegue",
            let nextVC = segue.destination as? SoundOptionsViewController {
            nextVC.prevVC = self
        } else if segue.identifier == "photoOptionsSegue",
            let nextVC = segue.destination as? PhotoOptionsViewController {
            nextVC.curPhotoOptions = photoOptions
            nextVC.prevVC = self
        } else if segue.identifier == "repeatOptionsSegue",
            let nextVC = segue.destination as? RepeatOptionsViewController {
            nextVC.prevVC = self
        }
    }
    
    func savePhotoOptions(option: String) {
        photoOptions[option] = !photoOptions[option]!
    }
    
    func saveSoundOptions(sound: String) {
        alarmSound = sound
        print("saving sound: \(sound)")
    }
    
    func saveRepeatOptions(option: String) {
        let map = [
            "domingo":"Sunday",
            "lunes":"Monday",
            "martes":"Tuesday",
            "miercoles":"Wednesday",
            "jueves":"Thursday",
            "viernes":"Friday",
            "sabado":"Saturday",
            "Sunday":"Sunday",
            "Monday":"Monday",
            "Tuesday":"Tuesday",
            "Wednesday":"Wednesday",
            "Thursday":"Thursday",
            "Friday":"Friday",
            "Saturday":"Saturday"
        ]
        repeatOptions[map[option]!] = !repeatOptions[map[option]!]!
    }
    
    // Save button click
    // Used extensively for distinguishing the difference between Create/Edit View controller and how that is handled
    @IBAction func saveClick(_ sender: Any) {
        
        if thereIsNoPhotoOption() {
            let alertVC  = UIAlertController(title: "create.invalid".localized, message:
                                                "create.select".localized, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertVC.addAction(okAction)
            present(alertVC, animated: true)
        } else {
            //let systemSoundID: SystemSoundID = 1016
            //AudioServicesPlaySystemSound(systemSoundID)
            //        AudioServicesPlay
            if alarmIndex == -1 {
                // Grabs info from this page and saves it
                delegate?.addAlarm(alarm: Alarm(id: NSUUID().uuidString, alarmOn: true, alarmTime: dateFormatter12.string(from: timePicker.date), alarmName: alarmName.text!, alarmSound: alarmSound, photoOptions: photoOptions, repeats: repeatOptions, isResolved: isResolved))
                
                // Update alarm notifs
                (self.delegate!).checkForPermission()
                
                self.navigationController?.popViewController(animated: true)
            } else {
                // Updates existing alarm in alarmList in mainVC
                
                // First gets the identifier used when that alarm was originally made as to be able to clear the old notification request
                // that is still in queue
                let alarmDate:Date = dateFormatter12.date(from: (self.delegate!).alarms[alarmIndex].alarmTime)!
                let alarmTime24 = dateFormatter24.string(from: alarmDate)
                let identifier = "AlarmingVisuals \(alarmTime24)"
                
                // Update old alarm
                let alarm = (self.delegate!).alarms[alarmIndex]
                alarm.alarmName = alarmName.text!
                alarm.alarmTime = dateFormatter12.string(from: timePicker.date)
                alarm.alarmSound = alarmSound
                alarm.photoOptions = photoOptions
                alarm.repeats = repeatOptions
                alarm.isResolved = isResolved
                delegate?.editAlarm(alarm: alarm)
                
                // Get rid of old, outdated alarm
                (self.delegate!).clearBulkOldAlarmNotifications(alarm:alarm)
                
                // Make new alarm notifs
                (self.delegate!).checkForPermission()
                
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    // Check if atleast 1 Photo Option is selected
    // TODO clean up :)
    func thereIsNoPhotoOption() -> Bool {
        let cell = optionsTableView.cellForRow(at: IndexPath(row: 2, section: 0))!
        return cell.detailTextLabel!.text!.isEmpty
    }
    
    // Called when 'return' key pressed
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
