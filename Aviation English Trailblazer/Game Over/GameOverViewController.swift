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
    func didPressBack(gameOverViewController: GameOverViewController)
}

class GameOverViewController: UIViewController {
//    @IBOutlet private var enterButton: UIButton!
    @IBOutlet private var backButton: UIButton!
    @IBOutlet private var resultTextView: UITextView!

    weak var navigationDelegate: GameOverViewNavigationDelegate?

    private var viewModel: GameOverViewModelRepresentable

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
        
        AF.request("http://atcrasa.eastasia.azurecontainer.io:6000/getlogbyid", method: .post, parameters: parameters, encoder: JSONParameterEncoder.default).responseDecodable(of: RasaResponse.self) { response in
            switch response.result {
                case .success(let JSON):
                    debugPrint("Response: \(JSON)")

                    self.resultTextView.text = response.value?.text

                case .failure(let error):
                    debugPrint("Failure: \(error)")
            }
        }
    }

    @IBAction func backButtonAction(_ sender: UIButton) {
        navigationDelegate?.didPressBack(gameOverViewController: self)
    }
}
