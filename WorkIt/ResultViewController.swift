//
//  ResultViewController.swift
//  WorkIt
//
//  Created by Aaryaman Saini on 05/04/21.
//

import UIKit
import CoreML
import Vision
import AVFoundation

class ResultViewController: UIViewController {
    
    //MARK: - Outlets
    @IBOutlet weak var pickAVideoButton: UIButton!
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    //MARK: - Variables
    let myModel = MyWorkoutImageClassifier_1().model
    
    var videoURL: URL? = nil
    var frames: [UIImage] = []
    var predictions: [VNClassificationObservation] = []
    var generator: AVAssetImageGenerator!
    var video: AVAsset? = nil
    var bestPrediction: VNClassificationObservation? = nil
    
    //MARK: - ViewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    //MARK: - Setup ML Model
    lazy var classificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: MyWorkoutImageClassifier_1().model)
            let request = VNCoreMLRequest(model: model, completionHandler: { [weak self] request, error in
                self?.processClassifications(for: request, error: error)
            })
            request.imageCropAndScaleOption = .centerCrop
            return request
        } catch {
            fatalError("Failed to load Vision ML model: \(error)")
        }
    }()
    
    //MARK: - Perform Requests
    func updateClassifications(for image: UIImage) {
        predictionLabel.text = "Classifying..."
        
        let orientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue))
        guard let ciImage = CIImage(image: image) else { fatalError("Unable to create \(CIImage.self) from \(image).") }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation!)
            do {
                try handler.perform([self.classificationRequest])
            } catch {
                //print("Failed to perform classification.\n\(error.localizedDescription)")
                return
            }
        }
    }
    
    //MARK: - Process Classification
    func processClassifications(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            guard let results = request.results else {
                self.predictionLabel.text = "Unable to classify image.\n\(error!.localizedDescription)"
                return
            }
            let classifications = results as! [VNClassificationObservation]
            if classifications.isEmpty {
                self.predictionLabel.text = "Nothing recognized."
            } else {
                //print(classifications[1])
                self.predictions.append(classifications[0])
                self.bestPrediction = self.evaluateLastPredictions()
                self.predictionLabel.text = self.bestPrediction?.identifier
                
            }
        }
    }
    
    func evaluateLastPredictions() -> VNClassificationObservation? {
        
        var result: [VNClassificationObservation : Int] = [:]
        if predictions.count > 5 {
            predictions.remove(at: 0)
        }
        for prediction in predictions {
            if result[prediction] == nil {
                result[prediction] = 0
            } else {
                result[prediction]! += 1
            }
        }
        //print(predictions)
        var bestResult: Int = result[predictions[0]] ?? 0
        for value in result.keys {
            if result[value]! >= bestResult {
                bestResult = result[value]!
            }
        }
        var bestValue: VNClassificationObservation = predictions[0]
        for value in result.keys {
            if result[value] == bestResult {
                bestValue = value
            }
        }
        return bestValue
    }
    
    @IBAction func pickPressed(_ sender: UIButton) {
        presentVideoPicker(sourceType: .savedPhotosAlbum)
    }
    
    func presentVideoPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.mediaTypes = ["public.movie"]
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    //MARK: - Functions for video to frames
    func getFramesFromVideo(videoUrl: URL, step: Int = 1) {
        let asset: AVAsset = AVAsset(url: videoUrl)
        let duration: Float64 = CMTimeGetSeconds(asset.duration)
        generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        frames = []
        for index: Int in 0 ..< Int(duration) {
            self.getFrame(fromTime:Float64(index))
        }
        generator = nil
    }

    private func getFrame(fromTime: Float64) {
        let time:CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale:600)
        let image:CGImage
        do {
           try image = generator.copyCGImage(at: time, actualTime:nil)
            //print("Added frame")
        } catch {
            //print("Error")
           return
        }
        //print("Added frame")
        frames.append(UIImage(cgImage:image))
    }
  

}


extension ResultViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        videoURL = info[.mediaURL] as? URL
        print(videoURL!)
        if videoURL != nil {
            getFramesFromVideo(videoUrl: videoURL! as URL)
            for frame in frames {
                updateClassifications(for: frame)
            }
        } else {
            predictionLabel.text = "Invalid video selected"
        }
        self.dismiss(animated: true, completion: nil)
    }
 
}
