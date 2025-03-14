//
//  ViewController.swift
//  371L-AlarmingVisuals
//
//  Created by Aneesh Chakka on 10/6/23.
//

import UIKit
import FirebaseAuth



class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var instructionLabel: UILabel!
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginErrorMessage: UILabel!
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeLabel.text = "login.welcome".localized
        instructionLabel.text = "login.instruction".localized
        
        emailTextField.placeholder = "login.email".localized
        passwordTextField.placeholder = "login.password".localized
        
        loginButton.setTitle("login.login".localized, for: .normal)
        signUpButton.setTitle("login.signup".localized, for: .normal)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        Auth.auth().addStateDidChangeListener() {
            (auth,user) in
            if user != nil {
                self.performSegue(withIdentifier: "loggedInSegue", sender: nil)
                self.emailTextField.text = nil
                self.passwordTextField.text = nil
            }
        }
        
    }
    
    @IBAction func loginButtonPressed(_ sender: Any) {
        let internalError = "An internal error has occurred, print and inspect the error details for more information."
        Auth.auth().signIn(withEmail: emailTextField.text!, password: passwordTextField.text!) {
            (authResult,error) in
            if let error = error as NSError? {
                if (error.localizedDescription == internalError) {
                    self.loginErrorMessage.text = "login.incorrect".localized
                } else {
                    self.loginErrorMessage.text = "\(error.localizedDescription)"
                }
            } else {
                self.loginErrorMessage.text = ""
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
