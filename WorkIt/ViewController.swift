//
//  ViewController.swift
//  WorkIt
//
//  Created by Aaryaman Saini on 04/04/21.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var howToSteps: UITextView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        howToSteps.textContainerInset = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }


}

