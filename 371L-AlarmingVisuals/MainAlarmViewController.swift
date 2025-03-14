//
//  MainAlarmViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Daniel Jeng on 10/11/23.
//

import UIKit
import UserNotifications
import CoreData
import Foundation
import FirebaseFirestore
import FirebaseAuth

let appDelegate = UIApplication.shared.delegate as! AppDelegate
// context points to the persistent container in appDelegate so we can update it
let context = appDelegate.persistentContainer.viewContext
let queue = DispatchQueue(label: "myQueue")

class MainAlarmViewController: UIViewController,  UITableViewDelegate, UITableViewDataSource, AlarmSaver {
    
    @IBOutlet weak var alarmTable: UITableView!
    @IBOutlet weak var plusSign: UIBarButtonItem!
    // Default alarms builtin, needs to be put into CoreData/UserDefaults
    var alarms: [Alarm] = []
    
    // Need two date formatters for 12 hour time (displaying)
    //                              24 hour time (notifications)
    var dateFormatter12 = DateFormatter()
    var dateFormatter24 = DateFormatter()
    
    let alarmItemIdentifier = "alarmItem"
    let createAlarmSegueIdentifier:String = "createAlarmSegue"
    let editAlarmSegueIdentifier:String = "editAlarmSegue"
    let gulagSegueIdentifier:String = "gulagSegue"
    
    var unresolvedAlarm:Alarm?
    var animatePlus = false {
        didSet {
            plusAnimation()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "main.title".localized
        // lowercase h is 12 hour time and optional 1 or 2 chars for hour, a is for am/pm/AM/PM
        dateFormatter12.dateFormat = "h:mm a"
        // uppercase H is 24 hour time and optional 1 or 2 chars for hour, doesn't need am/pm/AM/PM
        dateFormatter24.dateFormat = "H:mm"
        
        alarmTable.delegate = self
        alarmTable.dataSource = self
        
        // On load gotta check for permissions and set alarms that are set to on!
        
        alarms = retrieveAlarms()
        animatePlus = alarms.count == 0
        
        // Loop  through alarms and check for unresolved alarms and segue for those
        for alarm in alarms{
            if !alarm.isResolved{
                // Alert! Segue to gulag (ActiveAlarmViewController)
                unresolvedAlarm = alarm
                performSegue(withIdentifier: gulagSegueIdentifier, sender: nil)
            }
        }
        
        checkForPermission()
    }
    
    func getDocumentRef() -> DocumentReference {
        let db = Firestore.firestore()
        let userID = (Auth.auth().currentUser?.uid)!
        print(userID)
        return db.collection("users").document(userID)
    }
    
    func retrieveAlarms() -> [Alarm]{
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDAlarm")
        var fetchedResults:[NSManagedObject]? = nil
        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
        } catch {
            print("Error occurred while retrieving data")
            abort()
        }
        
        var alarmList: [Alarm] = []
        for alarm in fetchedResults! {
            alarmList.append(Alarm(id: alarm.value(forKey: "id") as! String, alarmOn: alarm.value(forKey: "alarmOn") as! Bool, alarmTime: alarm.value(forKey: "alarmTime") as! String, alarmName: alarm.value(forKey: "alarmName") as! String, alarmSound: alarm.value(forKey: "alarmSound") as! String, photoOptions: alarm.value(forKey: "photoOptions") as! [String : Bool], repeats: alarm.value(forKey: "repeats") as! [String : Bool], isResolved: alarm.value(forKey: "isResolved") as! Bool))
        }
        return alarmList
    }
    
    func checkTableEmpty() {
        print("checkTableEmpty")
        if alarms.isEmpty {
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 0, y: 0, width: alarmTable.bounds.size.width, height: alarmTable.bounds.size.height))
            noDataLabel.text          = "main.none".localized
            let appDelegate = view.window?.windowScene?.keyWindow
            noDataLabel.textColor     = appDelegate?.traitCollection.userInterfaceStyle == .dark ?  UIColor.white : UIColor.gray
            noDataLabel.textAlignment = .center
            alarmTable.backgroundView  = noDataLabel
            alarmTable.separatorStyle  = .none
        } else {
            alarmTable.separatorStyle = .singleLine
            alarmTable.backgroundView = nil
        }
    }
    
    func addAlarm(alarm: Alarm) {
        alarms.append(alarm)
        // store a person object into Core Data
        let alarmObj = NSEntityDescription.insertNewObject(
            forEntityName: "CDAlarm",
            into: context)

        alarmObj.setValue(alarm.alarmName, forKey: "alarmName")
        alarmObj.setValue(alarm.alarmOn, forKey: "alarmOn")
        alarmObj.setValue(alarm.alarmTime, forKey: "alarmTime")
        alarmObj.setValue(alarm.alarmSound, forKey: "alarmSound")
        alarmObj.setValue(alarm.id, forKey: "id")
        alarmObj.setValue(alarm.photoOptions, forKey: "photoOptions")
        alarmObj.setValue(alarm.repeats, forKey: "repeats")
        alarmObj.setValue(alarm.isResolved, forKey: "isResolved")
        
        // commit the changes
        saveContext()
        checkTableEmpty()
        animatePlus = false
    }
    
    func editAlarm(alarm: Alarm) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDAlarm")
        request.predicate = NSPredicate(format: "id = %@", alarm.id)
        var fetchedResults:[NSManagedObject]! = nil

        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
            if fetchedResults.count > 0 {
                fetchedResults[0].setValue(alarm.alarmOn, forKey: "alarmOn")
                fetchedResults[0].setValue(alarm.alarmSound, forKey: "alarmSound")
                fetchedResults[0].setValue(alarm.alarmTime, forKey: "alarmTime")
                fetchedResults[0].setValue(alarm.alarmName, forKey: "alarmName")
                fetchedResults[0].setValue(alarm.photoOptions, forKey: "photoOptions")
                fetchedResults[0].setValue(alarm.repeats, forKey: "repeats")
                fetchedResults[0].setValue(alarm.isResolved, forKey: "isResolved")
            }
        } catch {
            print("Error occurred while retrieving data")
            abort()
        }
        // commit the changes
        saveContext()
        
    }
    
    func deleteAlarm(row: Int) {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDAlarm")
        var fetchedResults:[NSManagedObject]! = nil

        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]

            if fetchedResults.count > 0 {
                for result in fetchedResults {
                    if result.value(forKey: "id") as! String == alarms[row].id {
                        clearBulkOldAlarmNotifications(alarm: alarms[row])
                        context.delete(result)
                        saveContext()
                        break
                    }
                }
            }
            alarms.remove(at: row)
            checkTableEmpty()
            animatePlus = alarms.count == 0
        } catch {
            print("Error occurred while retrieving data")
            abort()
        }
    }
    
    // Saves to core data
    func saveContext () {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("unresolved error...")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getDocumentRef().getDocument { (document, error) in
          if let document = document, document.exists {
              let data = document.data()
              if data?["spanish"] as! Bool {
                  UserDefaults.standard.set("es", forKey: "i18n_language")
              } else {
                  UserDefaults.standard.set("en", forKey: "i18n_language")
              }
          } else {
              print("Document does not exist")
          }
        }
        
        updateByUserPreferences()
        alarmTable.reloadData()
        self.title = "main.title".localized
    }
    
    func updateByUserPreferences() {
        let db = Firestore.firestore()
        
        guard let userID = Auth.auth().currentUser?.uid else {
            print("No user found")
            return
        }
        let docRef = db.collection("users").document(userID)

        docRef.getDocument { (document, error) in
          if let document = document, document.exists {
            print("updateByUserPreferences")
            let data = document.data()
              let appDelegate = self.view.window?.windowScene?.keyWindow
            appDelegate?.overrideUserInterfaceStyle = data?["darkMode"] as! Bool ? .dark : .light
              
            self.checkTableEmpty()
          } else {
            print("Document does not exist")
          }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // This cell automatically is freed when not on screen (memory saving)
        let cell = alarmTable.dequeueReusableCell(withIdentifier: alarmItemIdentifier,
            for: indexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = alarms[row].alarmTime
        cell.detailTextLabel?.text = alarms[row].alarmName
        let newSwitch = UISwitch()
        newSwitch.onTintColor = .systemBlue
        newSwitch.isOn = alarms[row].alarmOn
        newSwitch.tag = row
        newSwitch.addTarget(self, action: #selector(switchChanged(mySwitch:)), for: UIControl.Event.valueChanged)
        cell.accessoryView = newSwitch
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let row = indexPath.row
            deleteAlarm(row: row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            saveContext()
        }
    }
    
    // Used for switches in rows of alarm table view
    // Updates alarm notifications
    //
    // nothing to see here ...
    @objc func switchChanged(mySwitch: UISwitch) {
        alarms[mySwitch.tag].alarmOn = mySwitch.isOn
        editAlarm(alarm: alarms[mySwitch.tag])
        checkForPermission()
    }

    // Primarily used for going to the Create/Edit Alarm VC
    // Has different options for both since editing an alarm requires loading in previous alarm info
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == editAlarmSegueIdentifier,
           let nextVC = segue.destination as? CreateEditAlarmViewController,
           let alarmIndex = alarmTable.indexPathForSelectedRow?.row
        {
            nextVC.delegate = self
            nextVC.alarmIndex = alarmIndex
            
            // Transfer current alarm state to next screen
            let alarm = alarms[alarmIndex]
            nextVC.alarmTime = alarm.alarmTime
            nextVC.alarmNameText = alarm.alarmName
            nextVC.repeatOptions = alarm.repeats
            nextVC.alarmSound = alarm.alarmSound
            nextVC.photoOptions = alarm.photoOptions
            nextVC.isResolved = alarm.isResolved
        } else if segue.identifier == createAlarmSegueIdentifier,
                 let nextVC = segue.destination as? CreateEditAlarmViewController{
            nextVC.delegate = self
            nextVC.alarmIndex = -1
        }else if segue.identifier == gulagSegueIdentifier,
                 let nextVC = segue.destination as? ActiveAlarmViewController{
            nextVC.alarm = unresolvedAlarm
        }
    }
    
    // Checks if user has given the app permissions for notifications and prompts if they haven't
    // Upon getting permissions, automatically dispatches all alarms that are on in the alarms list
    func checkForPermission(){
        print("Inside checkForPermission()")
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            
            switch settings.authorizationStatus{
            case .authorized:
                print("AUTHORIZED")
                self.dispatchAlarms()
            case .denied:
                print("DENIED")
                return
            case .notDetermined:
                print("NOT DETERMINED")
                center.requestAuthorization(options: [.alert, .sound]){
                    didAllow, error in
                    if didAllow {
                        self.dispatchAlarms()
                    }
                }
            default:
                return
            }
        }
    }
    
    func getIdentifier(alarm:Alarm) -> String{
        let alarmDate:Date = dateFormatter12.date(from: alarm.alarmTime)!
        let alarmTime24 = dateFormatter24.string(from: alarmDate)
        let identifier = "AlarmingVisuals \(alarmTime24)"
        return identifier
    }
    
    // Dispatch all alarms that are currently on
    func dispatchAlarms(){
        for alarm in alarms{
            if alarm.alarmOn{
                let alarmDate:Date = dateFormatter12.date(from: alarm.alarmTime)!
                let alarmTime24 = dateFormatter24.string(from: alarmDate)
                
                let timeParts = alarmTime24.split(separator: ":")
                dispatchNotification(alarm:alarm, body: alarm.alarmName, hour: Int(timeParts[0])!, minute: Int(timeParts[1])!)
            } else {
//                let alarmDate:Date = dateFormatter12.date(from: alarm.alarmTime)!
//                let alarmTime24 = dateFormatter24.string(from: alarmDate)
//                let identifier = "AlarmingVisuals \(alarmTime24)"
//                let identifier = getIdentifier(alarm: alarm)
                
                clearBulkOldAlarmNotifications(alarm:alarm)
            }
        }
    }
    
    // Dispatch alarm notification for given parameters
    func dispatchNotification(alarm:Alarm, body:String, hour:Int, minute:Int){
        let isDaily = false
        
        let notificationCenter = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = alarm.alarmName
        content.body = "Alarming Visuals"
        content.userInfo["isAlarmNotification"] = true
        content.userInfo["photoOptions"] = alarm.photoOptions
        content.userInfo["alarmID"] = alarm.id
        content.userInfo["alarmSound"] = alarm.alarmSound
        content.userInfo["alarmRepeatOptions"] = alarm.repeats
        content.userInfo["isResolved"] = alarm.isResolved
        content.userInfo["alarmName"] = alarm.alarmName
        content.userInfo["alarmTime"] = alarm.alarmTime
        
        //        content.sound = .defaultRingtone
        //        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "Note.wav"))
        
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: "\(alarm.alarmSound).wav"))
        
        let baseIdentifier = getIdentifier(alarm: alarm)
        print("set sound to **\(alarm.alarmSound).wav**")
        
        let calendar = Calendar.current
        var dateComponents = DateComponents(calendar:calendar, timeZone:TimeZone.current)
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        for i in stride(from:0, to:60, by:1) {
            dateComponents.second = i
            var trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: isDaily)
            
            let secondIdentifier = "\(baseIdentifier):\(i)"
            var request = UNNotificationRequest(identifier: secondIdentifier, content: content, trigger: trigger)
            
            clearOldAlarmNotification(identifier: secondIdentifier)
            notificationCenter.add(request)
            print("FINISHED ADD NOTIF - **\(secondIdentifier)**")
            
        }
    }
    
    func clearBulkOldAlarmNotifications(alarm:Alarm){
        let baseIdentifier = getIdentifier(alarm: alarm)
        for i in stride(from:0, to:60, by:1){
            let secondIdentifier = "\(baseIdentifier):\(i)"
            clearOldAlarmNotification(identifier: secondIdentifier)
        }
    }
    
    // Clear old notification under given identifier
    func clearOldAlarmNotification(identifier:String){
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        print("FINISHED REM NOTIF - **\(identifier)**")
    }
    
    func plusAnimation() {
        var queue = DispatchQueue(label: "myQueue", qos: .utility)
        let colorArray: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemMint, .systemGreen, .systemTeal, .systemBlue, .systemIndigo, .systemPurple, .systemPink]
        queue.async {
            while self.animatePlus {
                for color in colorArray {
                    DispatchQueue.main.sync {
                        UIView.animate(
                            withDuration: 0.2,
                            animations: {
                                self.plusSign.tintColor = color
                            }
                        )
                    }
                    usleep(60000)
                }
            }
            DispatchQueue.main.sync {
                UIView.animate(
                    withDuration: 0,
                    animations: {
                        self.plusSign.tintColor = .systemBlue
                    }
                )
            }
        }
    }
}
