//
//  AppDelegate.swift
//  371L-AlarmingVisuals
//
//  Created by Aneesh Chakka on 10/6/23.
//

import UIKit
import CoreData
import FirebaseCore
import FirebaseFirestore
import UserNotifications
import AVFoundation
import CoreHaptics
import FirebaseAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var audioPlayer: AVAudioPlayer?
    var hapticEngine: CHHapticEngine?
    var alarm: Alarm?
    let soundQueue = DispatchQueue(label: "soundQueue", qos:.utility)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        
        return true
    }
    
    // One of the key methods for redirecting notifications to a specific view controller
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
    {
        return .portrait
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "_371L_AlarmingVisuals")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    // This method is called when user clicked on the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        let userInfo = response.notification.request.content.userInfo
        let isAlarmNotification:Bool = (userInfo["isAlarmNotification"] as? Bool)!
        let alarmID:String = (userInfo["alarmID"] as? String)!
        
        if isAlarmNotification{
            coordinateToCameraVC(alarmID: alarmID)
        }
        
        completionHandler()
    }
    
    
    private func coordinateToCameraVC(alarmID:String)
    {
        guard let window = UIApplication.shared.keyWindow else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let nextVC = storyboard.instantiateViewController(identifier: "activeAlarm") as ActiveAlarmViewController
        updateByUserPreferences()
        print("coordinateToCameraVC")
        
        self.alarm = getAlarm(alarmID: alarmID)
        self.alarm?.isResolved = false
        self.multithreadAlarmSound()
        
        nextVC.alarm = self.alarm
        
        window.rootViewController = nextVC
        window.makeKeyAndVisible()
    }
    
    private func getAlarm(alarmID: String) -> Alarm {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDAlarm")
        var fetchedResults:[NSManagedObject]? = nil

        // Filtering
        let predicate = NSPredicate(format: "id == \"\(alarmID)\"")
        request.predicate = predicate
        
        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
        } catch {
            print("Error occurred while retrieving data")
            abort()
        }
        let alarm = fetchedResults![0]
        
        return Alarm(id: alarmID, alarmOn: (alarm.value(forKey: "alarmOn") != nil), alarmTime: alarm.value(forKey: "alarmTime") as! String, alarmName: alarm.value(forKey: "alarmName") as! String, alarmSound: alarm.value(forKey: "alarmSound") as! String, photoOptions: alarm.value(forKey: "photoOptions") as! [String : Bool], repeats: alarm.value(forKey: "repeats") as! [String : Bool], isResolved: true)
    }
    
    private func updateByUserPreferences() {
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
                let appDelegate = UIApplication.shared.windows.first
                appDelegate?.overrideUserInterfaceStyle = data?["darkMode"] as! Bool ? .dark : .light                
            } else {
                print("Document does not exist")
            }
        }
    }
    
    private func multithreadAlarmSound() {
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
        } catch {
            print("There was an error creating the engine: \(error.localizedDescription)")
        }
        if let alarmSound = self.alarm?.alarmSound {
            soundQueue.async {
                self.playSound(sound: alarmSound)
            }
        }
    }
    
    private func playSound(sound: String) {
        guard let url = Bundle.main.url(forResource: "\(sound)", withExtension: "wav") else {
            print("Sound file not found.")
            return
        }
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.prepareToPlay()
            
            while !self.alarm!.isResolved {
                DispatchQueue.main.sync {
                    vibrate()
                    self.audioPlayer?.play()
                }
                sleep(2)
            }
        } catch {
            print("Could not play sound file.")
        }
    }
    
    // This will only work on iOS 13.0+, because otherwise
    // CoreHaptics does not work
    private func vibrate() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1)
        let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.6)

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try hapticEngine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern: \(error.localizedDescription).")
        }
    }
}

