//
//  SignUpViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Aneesh Chakka on 10/6/23.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var createLabel: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var signupErrorMessage: UILabel!
    
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        confirmPasswordTextField.delegate = self
        
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: "signedUpSegue", sender: nil)
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
                self.confirmPasswordTextField.text = nil
            }
        }
        
        createLabel.text = "signup.create".localized
        emailTextField.placeholder = "signup.email".localized
        passwordTextField.placeholder = "signup.password".localized
        confirmPasswordTextField.placeholder = "signup.retype".localized
        createButton.setTitle("signup.createButton".localized, for: .normal)
        backButton.setTitle("signup.back".localized, for: .normal)
    }
    
    // create account button click
    @IBAction func createAccountButtonPressed(_ sender: Any) {
        let userField = emailTextField.text!
        let passwordField = passwordTextField.text!
        
        if passwordField != confirmPasswordTextField.text! {
            signupErrorMessage.text = "signup.error".localized
        } else {
            Auth.auth().createUser(withEmail: userField, password: passwordField) {
                (authResult,error) in
                if let error = error as NSError? {
                    self.signupErrorMessage.text = "\(error.localizedDescription)"
                } else {
                    self.signupErrorMessage.text = ""
                    guard let userID = Auth.auth().currentUser?.uid else {
                        print("No user found")
                        return
                    }
                    print("creating account")
                    self.db.collection("users").document(userID).setData([
                      "darkMode": false,
                      "spanish": false,
                    ]) { err in
                      if let err = err {
                        print("Error writing document: \(err)")
                      } else {
                        print("Document successfully written!")
                      }
                    }
                    print("created document")
                }
            }
        }
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
