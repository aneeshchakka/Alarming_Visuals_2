//
//  SoundOptionsViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Manuel Torralba on 10/13/23.
//

import UIKit
import AVFAudio

// Default sound options, will be updated later
public let soundOptions = [
    "Note", "Rattle", "Rebound"
    ]

class SoundOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var soundOptionsTableView: UITableView!
    
    let soundOptionCellIdentifier = "soundOptionCell"
    var prevVC: CreateEditAlarmViewController?
    var audioPlayer: AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        soundOptionsTableView.delegate = self
        soundOptionsTableView.dataSource = self
    }
    
    // Gets count of sound options in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        soundOptions.count
    }
    
    // Sets cells of sound options within table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: soundOptionCellIdentifier, for: indexPath as IndexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = soundOptions[row]
        if prevVC?.alarmSound == soundOptions[row] {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    // We use check marks to signify which sound option to use, this might changes to switches
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("changing")
        let sound = tableView.cellForRow(at: indexPath)?.textLabel?.text ?? ""
        playSound(sound: sound)
        prevVC?.saveSoundOptions(sound: sound)
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        if tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func playSound(sound: String) {
        guard let url = Bundle.main.url(forResource: "\(sound)", withExtension: "wav") else {
            print("Sound file not found.")
            return
        }
        do {
            self.audioPlayer = try AVAudioPlayer(contentsOf: url)
            self.audioPlayer?.prepareToPlay()
            self.audioPlayer?.play()
        } catch {
            print("Could not play sound file.")
        }
    }
}
