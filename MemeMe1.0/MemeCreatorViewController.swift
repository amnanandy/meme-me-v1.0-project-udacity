//
//  ViewController.swift
//  MemeMe1.0
//
//  Created by Anna Mandy on 11/24/18.
//  Copyright © 2018 Anna. All rights reserved.
//

import UIKit

class MemeCreatorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UITextFieldDelegate {

    // MARK: IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var topTextYConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomTextYConstraint: NSLayoutConstraint!
    
    // MARK: UI Attributes
    
    let memeTextAttributes: [NSAttributedString.Key: Any] = [
        NSAttributedString.Key.strokeColor: UIColor.black,
        NSAttributedString.Key.foregroundColor: UIColor.white,
        NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
        NSAttributedString.Key.strokeWidth: -5.0
    ]

    //MARK: Meme Model
    
    struct Meme {
        var topText: String
        var bottomText: String
        var originalImage: UIImage
        var memedImage: UIImage
    }
    
    // MARK: UI View Controller Delegate Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        topText.delegate = self
        topText.defaultTextAttributes = memeTextAttributes
        bottomText.delegate = self
        bottomText.defaultTextAttributes = memeTextAttributes
        UISetupContent()
        
        // add gesture recognizer to provide user ability to dismiss keyboard by tapping outside of text field.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard(_:)))
        view.addGestureRecognizer(tapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        subscribeToKeyboardNotifications()
        subscribeToOrientationNotifications()
        UISetupButtons()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        unsubscribeFromKeyboardNotifications()
        unsubscribeFromOrientationNotifications()
    }
    
    // MARK: Text Field Delegate and Handling Methods
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textFieldDefaultTextHandler(true, textField)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textFieldDefaultTextHandler(false, textField)
    }
    
    /* Manage the default text in the top and bottom text fields.
       This provided two functions -
          1. clears the default text when the user begins editing.
          2. if the text field is left blank the default text is replaced, preventing the field from appearing invisible.
       The beginEditing param indicates if the text field has begun or ended editing.
       The textField param indicates which text field is being edited.
    */
    func textFieldDefaultTextHandler(_ beginEditing: Bool, _ textField: UITextField) {
        if (textField == topText) {
            if (textField.text == "TOP" && beginEditing) {
                textField.text = ""
            } else if (textField.text == "" && !beginEditing) {
                textField.text = "TOP"
            }
        }
        if (textField == bottomText) {
            if (textField.text == "BOTTOM" && beginEditing) {
                textField.text = ""
            } else if (textField.text == "" && !beginEditing) {
                textField.text = "BOTTOM"
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return true
    }
    
    // MARK: Image Picker Delegate Methods
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Device Orientation Handling
    
    func subscribeToOrientationNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleScreenRotation(_:)), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    func unsubscribeFromOrientationNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func handleScreenRotation(_ notification: Notification) {
        // update the textField constraints to prevent text covering the center of the image while in landscape.
        if UIDevice.current.orientation.isLandscape {
            topTextYConstraint.constant = 0
            bottomTextYConstraint.constant = 0
        } else {
            topTextYConstraint.constant = 35
            bottomTextYConstraint.constant = -35
        }
    }
    
    // MARK: Keyboard Notification Handling
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if (view.frame.origin.y == 0 && bottomText.isFirstResponder) {
            //adjust the frame to prevent keyboard from covering the bottom text field.
            view.frame.origin.y -= getKeyboardHeight(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        if (view.frame.origin.y != 0) {
            //if the frame is in an adjusted state, reset it to the default.
            view.frame.origin.y = 0
        }
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        topText.resignFirstResponder()
        bottomText.resignFirstResponder()
    }
    
    func getKeyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        
        return keyboardSize.cgRectValue.height
    }
    
    // MARK: Meme Image and Model Handling
    
    func saveMeme(_ memeImage: UIImage) {
        // Create the meme
        let meme = Meme(topText: topText.text!, bottomText: bottomText.text!, originalImage: imageView.image!, memedImage: memeImage)
        // Save the meme
        UIImageWriteToSavedPhotosAlbum(meme.memedImage, nil, nil, nil);
    }
    
    func generateMemedImage() -> UIImage {
        //hide toolbar and nav bar
        navBar.isHidden = true
        bottomToolbar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(view.frame.size)
        view.drawHierarchy(in: view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        //unhide toolbar and nav bar
        navBar.isHidden = false
        bottomToolbar.isHidden = false
        
        return memedImage
    }
    
    func selectImage(_ sourceType: UIImagePickerController.SourceType) {
        let selectCameraImage = UIImagePickerController()
        
        selectCameraImage.delegate = self
        selectCameraImage.sourceType = sourceType
        present(selectCameraImage, animated: true, completion: nil)
    }
    
    // MARK: IBActions
    
    @IBAction func selectAlbumPhoto(_ sender: Any) {
        selectImage(.photoLibrary)
    }
    
    @IBAction func selectCameraPhoto(_ sender: Any) {
        selectImage(.camera)
    }
    
    @IBAction func shareMeme(_ sender: Any) {
        let meme = generateMemedImage()
        let controller = UIActivityViewController(activityItems: [meme], applicationActivities: nil)
        
        controller.completionWithItemsHandler = { activity, success, items, error in
            if(success && (error == nil) && (activity != UIActivity.ActivityType.saveToCameraRoll)) {
                self.saveMeme(meme)
            }
        }
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func cancelMeme(_ sender: Any) {
        // reset the UI - clear the imageview and reset the text
        UISetupContent()
        UISetupButtons()
    }
    
    // MARK: UI Helper Methods
    
    func UISetupContent() {
        // set default text and image
        topText.text = "TOP"
        topText.textAlignment = NSTextAlignment.center
        bottomText.text = "BOTTOM"
        bottomText.textAlignment = NSTextAlignment.center
        imageView.image = nil
    }
    
    func UISetupButtons() {
        // set nav bar and toolbar button states
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        shareButton.isEnabled = (imageView.image != nil)
        cancelButton.isEnabled = (imageView.image != nil)
    }
}
