//
//  BaloonView.swift
//  CCHBDemo
//
//  Created by Coruț Fabrizio on 10.03.2021.
//

import Foundation
import UIKit

final class BalloonView: UIView, XibBindable {

	// MARK: - Outlets.

	@IBOutlet weak var contentView: UIView!

	// MARK: - Init

	override init(frame: CGRect) {
		super.init(frame: frame)
		commonInit()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
}
