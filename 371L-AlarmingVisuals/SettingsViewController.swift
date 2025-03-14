//
//  SettingsViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Aneesh Chakka on 10/12/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

public let settingsOptions = [
    "Dark Mode", "Spanish"
    ]

//extension String {
//    var localized: String{
//        return NSLocalizedString(self, tableName: nil, bundle: Bundle.main, value: "", comment: "")
//    }
//}

extension String {
    var localized: String {
        if let _ = UserDefaults.standard.string(forKey: "i18n_language") {} else {
            // we set a default, just in case
            UserDefaults.standard.set("en", forKey: "i18n_language")
            UserDefaults.standard.synchronize()
        }

        let lang = UserDefaults.standard.string(forKey: "i18n_language")

        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
        let bundle = Bundle(path: path!)

        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
    }
}

//extension String {
//    func localized(lang:String) -> String {
//        let path = Bundle.main.path(forResource: lang, ofType: "lproj")
//        let bundle = Bundle(path: path!)
//        
//        return NSLocalizedString(self, tableName: nil, bundle: bundle!, value: "", comment: "")
//    }
//}

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var settingsTable: UITableView!
    
    @IBOutlet weak var logoutButton: UIButton!
    
    let settingsCellIdentifier = "SettingsCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "settings.title".localized
        logoutButton.setTitle("settings.logout".localized, for: .normal)
        
        settingsTable.delegate = self
        settingsTable.dataSource = self
    }
    
    // Logout button press
    @IBAction func logoutButtonPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            self.performSegue(withIdentifier: "loggedOutSegue", sender: nil)
        } catch {
            print("Sign out error")
        }
    }
    
    // Returns count of setting options
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        settingsOptions.count
    }
    
    // Sets up each row of settings table view as a setting with a title and switch
    // THESE DO NOT ACTUALLY DO ANYTHING YET THOUGH
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: settingsCellIdentifier, for: indexPath as IndexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = "settings.\(settingsOptions[row])".localized
        let newSwitch = UISwitch()
        newSwitch.onTintColor = .systemBlue
        newSwitch.tag = row
        newSwitch.addTarget(self, action: #selector(switchChanged(mySwitch:)), for: UIControl.Event.valueChanged)
        cell.accessoryView = newSwitch
        getDocumentRef().getDocument { (document, error) in
          if let document = document, document.exists {
            let data = document.data()
              if row == 0 {
                  newSwitch.isOn = data?["darkMode"] as! Bool
              } else if row == 1 {
                  newSwitch.isOn = data?["spanish"] as! Bool
              }
          } else {
              print("Document does not exist")
          }
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
    
    // Called when switch is changed, DOES NOT DO ANYTHING YET
    @objc func switchChanged(mySwitch: UISwitch) {
        if mySwitch.tag == 0 {
            let appDelegate = self.view.window?.windowScene?.keyWindow
            appDelegate?.overrideUserInterfaceStyle = mySwitch.isOn ? .dark : .light
            let docRef = getDocumentRef()

            docRef.updateData([
                "darkMode": mySwitch.isOn
            ]) { err in
              if let err = err {
                print("Error updating document: \(err)")
              } else {
                print("Document successfully updated")
              }
            }
        } else {
            let docRef = getDocumentRef()

            docRef.updateData([
                "spanish": mySwitch.isOn
            ]) { err in
              if let err = err {
                print("Error updating document: \(err)")
              } else {
                print("Document successfully updated")
              }
            }
            if mySwitch.isOn {
                UserDefaults.standard.set("es", forKey: "i18n_language")
            } else {
                UserDefaults.standard.set("en", forKey: "i18n_language")
            }
            
            self.title = "settings.title".localized
            logoutButton.setTitle("settings.logout".localized, for: .normal)
            settingsTable.reloadData()
        }
    }
    
    func getDocumentRef() -> DocumentReference {
        let db = Firestore.firestore()
        let userID = (Auth.auth().currentUser?.uid)!
        print(userID)
        return db.collection("users").document(userID)
    }
}
