//
//  PhotoOptionsViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Manuel Torralba on 10/13/23.
//

import UIKit

// Default photo options, will be updated
public let photoOptions = [
    "Microwave Oven", "Oven","Apple", "Toothbrush", "Banana","Egg","Frying Pan","Sink","Shoe","Window","Refrigerator","Table","Houseplant","Car","Truck","Wheel","Chair"
    ]


class PhotoOptionsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var photoOptionsTableView: UITableView!
    
    let photoOptionCellIdentifier = "photoOptionCell"
    
    var curPhotoOptions: [String:Bool] = [:]
    var prevVC: CreateEditAlarmViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "photo.title".localized
        
        photoOptionsTableView.delegate = self
        photoOptionsTableView.dataSource = self
    }
    
    // Gets count of photo options in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        photoOptions.count
    }
    
    // Sets cells of photo options within table view
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: photoOptionCellIdentifier, for: indexPath as IndexPath)
        
        let row = indexPath.row
        cell.textLabel?.text = "photo.\(photoOptions[row])".localized
        
        //Added switches to each cell, might get changed to checkmarks
        let newSwitch = UISwitch()
        newSwitch.onTintColor = .systemBlue
        newSwitch.tag = row
        newSwitch.addTarget(self, action: #selector(switchChanged(mySwitch:)), for: UIControl.Event.valueChanged)
        newSwitch.isOn = curPhotoOptions[photoOptions[row]] ?? false
        cell.accessoryView = newSwitch
        cell.selectionStyle = .none
        
        return cell
    }
    
    // Called when the switch changes on a cell, needs updated
    @objc func switchChanged(mySwitch: UISwitch) {
        print(photoOptions[mySwitch.tag])
        let option = photoOptions[mySwitch.tag]
        curPhotoOptions[option] = !curPhotoOptions[option]!
        prevVC?.savePhotoOptions(option: option)
    }
}
