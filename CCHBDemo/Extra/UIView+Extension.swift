//
//  File.swift
//  CCHBDemo
//
//  Created by Coruț Fabrizio on 10.03.2021.
//

import Foundation
import UIKit

protocol XibBindable: class {
	var contentView: UIView! { get }

	/// Called after the `commonInit` has performed all the setup.
	func didFinishInit()
}

extension XibBindable where Self: UIView {

	/// Ties the class to the `.xib`.
	func commonInit() {
		// Bind the Xib to the class.
		Bundle(for: Self.self).loadNibNamed(String(describing: Self.self), owner: self, options: nil)

		// Add it as a subview and constrain it.
		contentView.translatesAutoresizingMaskIntoConstraints = false
		addSubview(contentView)
		NSLayoutConstraint.activate([
			contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
			contentView.topAnchor.constraint(equalTo: topAnchor),
			trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
			bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
		])

		// Allow view to perform extra customizations.
		didFinishInit()
	}

	// Default implementation, do nothing.
	func didFinishInit() { }
}
