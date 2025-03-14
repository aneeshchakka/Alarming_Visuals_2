//
//  GoogleVisionViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Daniel Jeng on 10/16/23.
//

import UIKit
import Dispatch
import SwiftyJSON

class GoogleVisionViewController: UIViewController {
    @IBOutlet weak var loadingLabel: UILabel!
    
    var prevViewController: CameraViewController?
    let session = URLSession.shared
    
    var photoTarget:String = ""
    var alarm:Alarm?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadingLabel.text = "google.loading".localized
        
        callGoogleVision()
        
    }
    
    // Placeholder for calling google vision api for now, just guesses to see if
    // the picture contains the correct photo option:)
    func callGoogleVision() {
        let userImage = prevViewController?.imageView.image
        
        let googleAPIKey = "AIzaSyCLq22IlIVQ6cO0S3RjDOBcnLYFgnbf5DY"
        
        var googleURL: URL {
                return URL(string: "https://vision.googleapis.com/v1/images:annotate?key=\(googleAPIKey)")!
            }
        
        // Base64 encode the image and create the request
        let binaryImageData = base64EncodeImage(userImage!)
        createRequest(with: binaryImageData, googleURL: googleURL)
    }
    
    func resizeImage(_ imageSize: CGSize, image: UIImage) -> Data {
        UIGraphicsBeginImageContext(imageSize)
        image.draw(in: CGRect(x: 0, y: 0, width: imageSize.width, height: imageSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        let resizedImage = newImage!.pngData()
        UIGraphicsEndImageContext()
        return resizedImage!
    }
    
    func base64EncodeImage(_ image: UIImage) -> String {
        var imagedata = image.pngData()
        
        // Resize the image if it exceeds the 2MB API limit
        if (imagedata!.count > 2097152) {
            let oldSize: CGSize = image.size
            let newSize: CGSize = CGSize(width: 800, height: oldSize.height / oldSize.width * 800)
            imagedata = resizeImage(newSize, image: image)
        }
        
        return imagedata!.base64EncodedString(options: .endLineWithCarriageReturn)
    }
    
    func createRequest(with imageBase64: String, googleURL: URL) {
        // Create our request URL
        var request = URLRequest(url: googleURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(Bundle.main.bundleIdentifier ?? "", forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        
        // Build our API request
        let jsonRequest = [
            "requests": [
                "image": [
                    "content": imageBase64
                ],
                "features": [
                    [
                        "type": "OBJECT_LOCALIZATION",
                        "maxResults": 10
                    ]   // TODO if we need more objects, try LABEL_DETECTION
                ]
            ]
        ]
        let jsonObject = JSON(jsonRequest)
        
        // Serialize the JSON
        guard let data = try? jsonObject.rawData() else {
            return
        }
        
        request.httpBody = data
        
        // Run the request on a background thread
        DispatchQueue.global().async { self.runRequestOnBackgroundThread(request) }
    }
    
    func runRequestOnBackgroundThread(_ request: URLRequest) {
        // run the request
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data, response, error) in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            
            self.analyzeResults(data)
        }
        
        task.resume()
    }
    
    func analyzeResults(_ dataToParse: Data) {
        
        // Update UI on the main thread
        DispatchQueue.main.async(execute: {
            
            // Use SwiftyJSON to parse results
            do {
                let json = try JSON(data: dataToParse)
                
                let errorObj: JSON = json["error"]
                
                
                // Check for errors
                if (errorObj.dictionaryValue != [:]) {
                    // TODO maybe a photo in the dark, try again please TODO
                    print("TODO ERROR ON LOADING API RESULT")
                    print("JSON JSON JSON JSON")
                    print(json)
                    print("JSON JSON JSON JSON")
                    print("ERROR")
                    print(errorObj)
                    print("ERROR")
                } else {
                    // Parse the response
                    print(json)
                    let responses: JSON = json["responses"][0]
                    
                    
                    // Get label annotations
                    let objectAnnotations: JSON = responses["localizedObjectAnnotations"]
                    let numObjects: Int = objectAnnotations.count
                    var objects: Array<String> = []
                    
                    if numObjects > 0 {
                        for index in 0..<numObjects {
                            var object = objectAnnotations[index]["name"].stringValue.lowercased()
                            //object += "=\(objectAnnotations[index]["score"].intValue * 100)"
                            objects.append(object)
                        }
                        
                        //self.loadingLabel.text = objects.joined(separator: ",")
                    } else {
                        self.loadingLabel.text = "google.noObjects".localized
                        self.sendBack()
                    }
                    
                    if objects.contains(self.photoTarget.lowercased()) {
                        self.loadingLabel.text = "google.congratulations".localized
                        self.alarm?.isResolved = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
                            self.performSegue(withIdentifier: "successSegue", sender: nil)
                        }
                        
                    } else {
                        self.loadingLabel.text = "google.tryAgain".localized
                        self.sendBack()
                    }
                }
            } catch {
                print("try JSON failed")
            }
        })
    }
    
    // Go back to the CameraViewController
    func sendBack(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
            self.prevViewController?.imageView.image = nil
            self.dismiss(animated: true) {
                self.prevViewController?.viewWillAppear(false)
            }
        }
    }
    
}
