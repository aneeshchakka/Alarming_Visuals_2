//
//  ActiveAlarmViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Daniel Jeng on 10/16/23.
//

import UIKit

class ActiveAlarmViewController: UIViewController {
    @IBOutlet weak var alarmTitleLabel: UILabel!
    @IBOutlet weak var alarmTimeLabel: UILabel!
    
    var alarm:Alarm?
    var photoTarget:String = ""
    
    let cameraSegue:String = "toCameraSegue"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("************************")
        print("photoOptions = \(photoOptions)")
        print("************************")
        
        getPhotoTarget()
        
        //Start thread playing alarm sounds
//        start
    }
    
    override func viewWillAppear(_ animated: Bool) {
        alarmTitleLabel.text = alarm!.alarmName
        alarmTimeLabel.text = "activeAlarm.timeLabel".localized + alarm!.alarmTime
    }
    
    func getPhotoTarget(){
        var possibleTargets:[String] = []
        for key in alarm!.photoOptions.keys{
            if alarm!.photoOptions[key]!{
                possibleTargets.append(key)
            }
        }
        
        photoTarget  = possibleTargets[Int.random(in: 0..<possibleTargets.count)]
        print("photoTarget = \(photoTarget)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == cameraSegue,
            let nextVC = segue.destination as? CameraViewController {
            nextVC.photoTarget = self.photoTarget
            nextVC.alarm = self.alarm
        }
    }
}
