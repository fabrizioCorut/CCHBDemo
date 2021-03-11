//
//  BalloonSpot.swift
//  CCHBDemo
//
//  Created by Coruț Fabrizio on 10.03.2021.
//

import Foundation
import UIKit

protocol BalloonSpotDelegate: class {
	func didInteractWith(balloon: BalloonView, spot: BalloonSpot)
}

final class BalloonSpot {

	// MARK: - Private interface.

	private let fieldBehavior: UIFieldBehavior = {
		let field: UIFieldBehavior = .springField()
		field.region = UIRegion(radius: 600.0) // Empirical value
		field.smoothness = 1.0
		field.strength = 1.4 // Empirical value
		return field
	}()

	private let dynamicBehavior: UIDynamicItemBehavior = {
		let behavior: UIDynamicItemBehavior = .init()
		behavior.allowsRotation = false
		behavior.resistance = 25.5 // Empirical value
		behavior.density = 0.006 // Empirical value
		return behavior
	}()

	/// The balloon which we manage.
	private weak var balloon: BalloonView?

	/// Detect tap inside the balloon.
	private lazy var tapRecognizer: UITapGestureRecognizer = .init(target: self, action: #selector(balloonTapHandle(recognizer:)))

	// MARK: - Public interface

	/// Handles `spot` specific interaction with balloon.
	public weak var delegate: BalloonSpotDelegate?

	/// The position of the `spot`.
	public var center: CGPoint {
		fieldBehavior.position
	}

	/// Determines the direction by which the `spot` will move.
	public let directionAngle: CGFloat

	// MARK: - Init.

	/// - Parameter animator: To attach any `UIDynamic` behaviors to.
	/// - Parameter directionAngle: Angle, relative to the center of the screen which determines the direction by which the `spot` should move. See `Self.move(to:)`
	/// - Parameter center: Where the spot will be positioned at first.
	public init(animator: UIDynamicAnimator, directionAngle: CGFloat, center: CGPoint) {
		self.directionAngle = directionAngle
		// TODO: - Add behaviors to the animator so their effect will be visible on the screen.
		animator.addBehavior(fieldBehavior)
		animator.addBehavior(dynamicBehavior)
		fieldBehavior.position = center
	}

	// MARK: - Public interface.

	/// Binds the `balloon` to the `spot`.
	/// - Parameter balloon: To add any `UIDynamic` behaviors to it.
	public func assign(balloon: BalloonView) {
		balloon.addGestureRecognizer(tapRecognizer)
		self.balloon = balloon
		// TODO: - Add the item to the behaviors.
		fieldBehavior.addItem(balloon)
		dynamicBehavior.addItem(balloon)
	}

	/// Changes the position of the view.
	/// - Parameter newPositionDelta: Delta values by which the position has changed.
	public func move(by newPositionDelta: CGPoint) {
		// TODO: - Move the view.
		fieldBehavior.position = computeNewCenterUsingBoringMath(newPositionDelta: newPositionDelta)
	}

	/// Unbinds the `balloon`.
	/// - Returns: The `balloon` which has been in this `spot`.
	public func removeBalloon() -> BalloonView? {
		defer {
			balloon = nil
		}

		// Remove the balloon from the behaviours since they keep a strong reference to it
		// and we risk keeping them around.
		balloon.map {
			balloon?.removeGestureRecognizer(tapRecognizer)
			// TODO: - Clean-up the view from the behaviors.
			fieldBehavior.removeItem($0)
			dynamicBehavior.removeItem($0)
		}
		return balloon
	}

	/// Decomposes the delta, just on the `y axis`, since we want to react just to vertical pans, and moves the `balloon` on the
	/// line determined by its angle.
	/// - Parameter newPositionDelta: Delta values by which the position has changed.
	private func computeNewCenterUsingBoringMath(newPositionDelta: CGPoint) -> CGPoint {
		// Negate the position so when we pan up, we expand the balloons
		// and when we pan down, we pull the baloons together.
		let yDelta = -newPositionDelta.y * sin(directionAngle)
		let xDelta = -newPositionDelta.y * cos(directionAngle)
		return center.applying(.init(translationX: xDelta, y: yDelta))
	}

	// MARK: - Selectors

	@objc private func balloonTapHandle(recognizer: UITapGestureRecognizer) {
		balloon.map { delegate?.didInteractWith(balloon: $0, spot: self) }
	}
}
