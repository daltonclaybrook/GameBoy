//
//  ViewController.swift
//  GameBoy
//
//  Created by Dalton Claybrook on 5/28/19.
//  Copyright © 2019 Dalton Claybrook. All rights reserved.
//

import GameBoyKit
import UIKit

class ViewController: UIViewController {
	private let gameBoy = GameBoy()

	override func viewDidLoad() {
		super.viewDidLoad()
		gameBoy.start()
	}
}

