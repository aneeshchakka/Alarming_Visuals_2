//
//  RepeatOptionsViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Manuel Torralba on 10/17/23.
//

import UIKit

// Days of the week
public let daysOfTheWeek = [
    "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
]

class RepeatOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var repeatTableView: UITableView!
    let repeatOptionCellIdentifier = "repeatOptionCell"
    var prevVC: CreateEditAlarmViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "repeat.title".localized
        
        repeatTableView.delegate = self
        repeatTableView.dataSource = self
    }
    
    // Gets count of repeat cells
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return daysOfTheWeek.count
    }
    
    // Sets repeat cell contents
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: repeatOptionCellIdentifier, for: indexPath as IndexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = "repeat.\(daysOfTheWeek[row])".localized
        if ((prevVC?.repeatOptions[daysOfTheWeek[row]]) == true) {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    // We use check marks to signify which repeat option to use, this might changes to switches
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        prevVC?.saveRepeatOptions(option: tableView.cellForRow(at: indexPath)?.textLabel?.text ?? "")
        if tableView.cellForRow(at: indexPath)?.accessoryType == .checkmark {
            tableView.cellForRow(at: indexPath)?.accessoryType = .none
        } else {
            tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        }
        repeatTableView.deselectRow(at: indexPath, animated: true)
    }
}
