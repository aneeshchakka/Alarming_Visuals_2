//
//  CameraViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Daniel Jeng on 10/13/23.
//
import UIKit
import AVFoundation
class CameraViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var photoOptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var takePictureButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var tryAgainButton: UIButton!
    
    var imageViewLabel = UILabel()
    var photoTarget:String = ""
    var alarm:Alarm?
    
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        photoOptionLabel.text = "camera.take".localized + "\(photoTarget)!"
        
        imageViewLabel.text = "camera.noImage".localized
        imageViewLabel.textAlignment = .center
        imageView.addSubview(imageViewLabel)
        imageViewLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageViewLabel.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            imageViewLabel.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
            imageViewLabel.widthAnchor.constraint(equalTo: imageView.widthAnchor)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if imageView.image != nil {
            // No image, show "Take Picture" button
            submitButton.isHidden = false
            submitButton.setTitle("camera.submit".localized, for: .normal)
            tryAgainButton.isHidden = false
            takePictureButton.isHidden = true
            imageViewLabel.isHidden = true
            takePictureButton.setTitle("camera.tryAgain".localized, for: .normal)
            imageView.backgroundColor = .black
        } else {
            // Image taken, show "Submit" and "Try Again" buttons
            submitButton.isHidden = true
            tryAgainButton.isHidden = true
            takePictureButton.isHidden = false
            imageViewLabel.isHidden = false
            takePictureButton.setTitle("camera.takePicture".localized, for: .normal)
            imageView.backgroundColor = .lightGray        }
        print("END viewWillAppear()")
    }
    
    // Launches imagePicker
    @IBAction func takePictureOnClick(_ sender: UIButton) {
        if UIImagePickerController.availableCaptureModes(for: .rear) != nil {
            // There is a rear camera available, check camera auth status
            switch AVCaptureDevice.authorizationStatus(for: .video) {
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video) {
                        (accessGranted) in
                        guard accessGranted == true else { return }
                    }
                case .authorized:
                    // We have authorization, now do stuff
                    picker.delegate = self
                    picker.sourceType = .camera
                    picker.cameraCaptureMode = .photo
                    present(picker, animated: true)
                    break
                default:
                    // Not authorized (answer is no)
                let alertVC  = UIAlertController(title: "camera.allowCamera".localized, message:
                                                    "camera.allowCameraMessage".localized, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default)
                    alertVC.addAction(okAction)
                    present(alertVC, animated: true)
                    return
            }
        } else {
            // There is no rear camera
            let alertVC  = UIAlertController(title: "camera.noCamera".localized, message:
                                                "camera.noCameraMessage".localized, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default)
            alertVC.addAction(okAction)
            present(alertVC, animated: true)
        }
    }
    
    @IBAction func tryAgainOnClick(_ sender: UIButton) {
        takePictureOnClick(sender)
    }
    
    // Cancel button for imagePicker
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // Upon successfully getting an image from picker save it and dismiss picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.image = image
    }
    
    // Used for GoogleVisionController, giving it a pointer to this view controller under prevViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "GoogleVisionSegue",
            let nextVC = segue.destination as? GoogleVisionViewController {
            print("segueing")
            nextVC.prevViewController = self
            nextVC.photoTarget = self.photoTarget
            nextVC.alarm = self.alarm
        }
    }
}

