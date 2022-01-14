//
//  GameOverViewController.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

import Alamofire
import Sucrose
import UIKit

protocol GameOverViewNavigationDelegate: AnyObject {
    func didPressExit(gameOverViewController: GameOverViewController)
}

class GameOverViewController: UIViewController {
    @IBOutlet private var backButton: UIButton!
    @IBOutlet private var resultTextView: UITextView!
    @IBOutlet private var saveButton: UIButton!

    weak var navigationDelegate: GameOverViewNavigationDelegate?

    private var viewModel: GameOverViewModelRepresentable

    /// Log
    var logFile: URL!

    init(viewModel: GameOverViewModelRepresentable) {
        self.viewModel = viewModel

        // Get the view name
        super.init(nibName: GameOverViewController.name, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        /// Rasa get log
        let parameters = RasaRequest(message: viewModel.senderIDArr.joined(separator: ","), sender: "99999")

        debugPrint(parameters)

        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/getlogbyid", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { [self] response in
            switch response.result {
                case .success(let JSON):
                    #if DEBUG
                        debugPrint("Response: \(JSON)")
                    #endif

                    resultTextView.text = response.value?.text

                    preheatLog()

                case .failure(let error):
                    #if DEBUG
                        debugPrint("Failure: \(error)")
                    #endif
            }
        }
    }

    @IBAction func exitButtonAction(_ sender: UIButton) {
        /// Clear textView before exit
        resultTextView.text = ""
        navigationDelegate?.didPressExit(gameOverViewController: self)
    }

    @IBAction func saveButtonAction(_ sender: UIButton) {
        let activityViewController = UIActivityViewController(activityItems: [logFile as Any], applicationActivities: nil)

        /// Exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [
            UIActivity.ActivityType.postToFacebook,
            UIActivity.ActivityType.postToFlickr,
            UIActivity.ActivityType.postToTwitter,
            UIActivity.ActivityType.postToTencentWeibo,
            UIActivity.ActivityType.postToVimeo,
            UIActivity.ActivityType.postToWeibo
        ]

        /// Set email subject
        activityViewController.setValue("AET Log", forKey: "Subject")

        activityViewController.modalPresentationStyle = .popover
        /// Avoiding to crash on iPad
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }

        /// Error handle
        activityViewController.completionWithItemsHandler = {
            (_: UIActivity.ActivityType?, _: Bool, _: [Any]?, error: Error?) in

                if error != nil {
                    self.showAlert(title: "Error", message: "Error:\(error!.localizedDescription)")
                    return
                }
//                if completed {
//                    self.showAlert(title: "Success", message: "Share log.")
//                }
        }

        present(activityViewController, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel)
        alertController.addAction(action)
        present(alertController, animated: true)
    }

    func preheatLog() {
        /// Get data time now
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH-mm"
        let dateTime = dateFormatter.string(from: now)

        let fileName = "Log-" + dateTime + ".txt"

        saveTextToFile(fileName: fileName, text: resultTextView.text)
    }

    /// Save log to user's directory
    func saveTextToFile(fileName: String, text: String) {
        let manager = FileManager.default
        let urlForDocument = manager.urls(for: .documentDirectory, in: .userDomainMask)
        logFile = urlForDocument[0].appendingPathComponent(fileName)
        print("File path: \(String(describing: logFile))")

        guard manager.fileExists(atPath: logFile.path) else {
            let utf8Str = text.data(using: .utf8)
            let base64Encoded = utf8Str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
            let data = Data(base64Encoded: base64Encoded!, options: Data.Base64DecodingOptions(rawValue: 0))
            let createSuccess: Bool = manager.createFile(atPath: logFile.path, contents: data, attributes: nil)

            print("Log build success: \(createSuccess)")

            return
        }
    }
}
