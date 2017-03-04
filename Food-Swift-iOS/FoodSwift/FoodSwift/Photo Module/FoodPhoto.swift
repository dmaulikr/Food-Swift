//
//  FoodPhoto.swift
//  FoodSwift
//
//  Created by NiM on 3/4/2560 BE.
//  Copyright © 2560 tryswift. All rights reserved.
//

import Foundation
import UIKit
import FirebaseStorage
import FirebaseDatabase

class FoodPhoto : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    static let defaultInstance = FoodPhoto();
    
    typealias FoodPhotoImageSelectedListenerBlock = (UIImage?, NSError?) -> Void
    typealias FoodPhotoImageUploadListenerBlock = (URL?, Error?) -> Void
    typealias FoodPhotoImagePostFinishBlock = () -> Void
    
    private var foodSelectedCompletion:FoodPhotoImageSelectedListenerBlock?
    private var foodImagePostCompletion:FoodPhotoImagePostFinishBlock?
    private let foodRootRef = FIRDatabase.database().reference()

    class func imagePickerViewController(completion:@escaping FoodPhotoImageSelectedListenerBlock) -> UIImagePickerController {
        let imagePickerController = UIImagePickerController();
        imagePickerController.delegate = FoodPhoto.defaultInstance;
        imagePickerController.allowsEditing = true;
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePickerController.sourceType = .camera;
        } else {
            imagePickerController.sourceType = .photoLibrary;
        }
        
        FoodPhoto.defaultInstance.foodSelectedCompletion = completion;
        
        return imagePickerController;
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        if let completion = self.foodSelectedCompletion {
            completion(nil, NSError(domain: "FoodSwift", code: 0, userInfo: [NSLocalizedDescriptionKey : "Photo is not selected."]));
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let completion = self.foodSelectedCompletion {
            completion(info[UIImagePickerControllerEditedImage] as? UIImage, nil);
        }
    }
    
    class func uploadImage(image:UIImage, completion:@escaping FoodPhotoImageUploadListenerBlock) {
        let storageRef = FIRStorage.storage().reference(forURL:"gs://foodswift-fa506.appspot.com")
        let imageName = Int64(ceil((NSDate().timeIntervalSince1970)*1000));
        let imagesRef = storageRef.child("foodswift_\(imageName).png");

        if let imageData = UIImagePNGRepresentation(image) {
            let _ = imagesRef.put(imageData, metadata: nil, completion: { (metaData0, error) in
                if (error != nil) {
                    // Uh-oh, an error occurred!
                    completion(nil, error!);
                } else {
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    if let metaData = metaData0 {
                        if let downloadURL = metaData.downloadURL() {
                            completion(downloadURL, nil);
                        } else {
                            completion(nil, nil);
                        }
                    } else {
                        completion(nil, nil);
                    }
                }
            })
        }
    }
    
    class func addNewPost(imageURL:URL, location:AnyObject, placeName:String, userID:String, completion:FoodPhotoImagePostFinishBlock? = nil) {
        FoodPhoto.defaultInstance.foodImagePostCompletion = completion;
        
        let ref = FoodPhoto.defaultInstance.foodRootRef.child("food").childByAutoId()
        ref.setValue(
            [
            "g" : "w8rpojks10e",
            "imageURL" : imageURL.absoluteString,
            "l" : [ 35.6937489, 139.7687731 ],
            "place" : placeName,
            "user" : userID,
            "rate" : 0
            ]
        )
        
        ref.observeSingleEvent(of: .childAdded, with: { (snapshot) in
            if let completion = FoodPhoto.defaultInstance.foodImagePostCompletion {
                completion();
            }
        })
    }
}