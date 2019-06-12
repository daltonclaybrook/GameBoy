//
//  ViewController.swift
//  GameBoy
//
//  Created by Dalton Claybrook on 5/28/19.
//  Copyright © 2019 Dalton Claybrook. All rights reserved.
//

import GameBoyKit
import MetalKit
import UIKit

class ViewController: UIViewController {
	@IBOutlet var mtkView: MTKView!
	private var gameBoy: GameBoy?

	override func viewDidLoad() {
		super.viewDidLoad()

		guard let device = MTLCreateSystemDefaultDevice() else {
			return assertionFailure("Metal device could not be created")
		}
		mtkView.device = device

		do {
			let renderer = try MetalRenderer(view: mtkView, device: device)
			let gameBoy = GameBoy(renderer: renderer)
			gameBoy.start()
			self.gameBoy = gameBoy
		} catch let error {
			return assertionFailure("error creating renderer: \(error)")
		}
	}
}

