//
//  ViewController.swift
//  CCHBDemo
//
//  Created by Coruț Fabrizio on 10.03.2021.
//

import UIKit

extension ViewController: BalloonSpotDelegate {

	func didInteractWith(balloon: BalloonView, spot: BalloonSpot) {
		// TODO: - Add gravity.
		// Remove the balloon from the spot so it will also be removed from the effect
		// of any other dynamic field.
		_ = spot.removeBalloon()

		// Add it to the gravity field so it will give the impression of "flying away"
		gravity.addItem(balloon)
		collision.addItem(balloon)
	}
}

final class ViewController: UIViewController {

	@IBOutlet private weak var blackHoleButton: UIButton!
	@IBOutlet private weak var blackHoleImageView: UIImageView!
	@IBOutlet private weak var theEndLabel: UILabel!

	// MARK: - Private interface.

	/// Makes the `UIDynamicBehaviors` work.
	private lazy var animator: UIDynamicAnimator = .init(referenceView: view)

	// TODO: - Add gravity.
	/// Gravity field used to create the effect of the balloons flying away.
	private lazy var gravity: UIGravityBehavior = {
		let behavior: UIGravityBehavior = .init()
		behavior.gravityDirection = .init(dx: 0.0, dy: -0.4)
		animator.addBehavior(behavior)
		return behavior
	}()

	/// Blocks the balloon from exiting the bounds.
	private lazy var collision: UICollisionBehavior = {
		let behavior: UICollisionBehavior = .init()
		animator.addBehavior(behavior)
		behavior.translatesReferenceBoundsIntoBoundary = true
		return behavior
	}()

	// TODO: - Add black hole implementation.
	/// Mimics a vortex.
	private lazy var blackHoleVortex: UIFieldBehavior = {
		let behavior: UIFieldBehavior = .vortexField()
		behavior.position = balloonsStartingPoint
		behavior.strength = 0.03
		behavior.minimumRadius = 200.0
		animator.addBehavior(behavior)
		return behavior
	}()

	/// Mimics a radial gravity pull, which in combination iwth the `blackHoleVortex` creates the circular pull of a black hole.
	private lazy var blackHoleGravity: UIFieldBehavior = {
		let gravity: UIFieldBehavior = .radialGravityField(position: balloonsStartingPoint)
		gravity.minimumRadius = 50.0
		animator.addBehavior(gravity)
		return gravity
	}()

	/// Storage of the `BalloonSpots` which manage a space on the screen.
	private var balloonSpots: [BalloonSpot] = []

	// MARK: - Utils.

	/// The rate at which the balloon spots scrambing timer will fire.
	private let timerFireInterval: TimeInterval = 5.0

	/// Where the balloons will spawn from.
	private lazy var balloonsStartingPoint: CGPoint = view.center.applying(.init(translationX: 0.0, y: -15.0))

	/// Used to randomly move the balloons from a spot to another.
	private lazy var scrambleTimer: Timer = .scheduledTimer(timeInterval: timerFireInterval, target: self, selector: #selector(scrambleBalloonSpots), userInfo: nil, repeats: true)

	// MARK: - View lifecycle.

	override func loadView() {
		super.loadView()
		setupUI()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		// Allow the user to observe the balloons first.
		DispatchQueue.main.asyncAfter(deadline: .now() + timerFireInterval) { [self] in
			scrambleTimer.fire()
		}
	}

	// MARK: - Utils.

	/// Add some balloons..
	private func setupUI() {
		let angles = [0, CGFloat.pi / 4, CGFloat.pi / 2, 3 / 4 * CGFloat.pi, CGFloat.pi, 5 / 4 * CGFloat.pi, 3 / 2 * CGFloat.pi, 7 / 4 * CGFloat.pi]
		let radius = view.frame.width / 2.5
		balloonSpots = angles.compactMap { angle in
			let balloonSpot: BalloonSpot = .init(animator: animator, directionAngle: angle, center: balloonsStartingPoint)
			balloonSpot.delegate = self
			let balloon: BalloonView = .init(frame: .init(origin: balloonsStartingPoint, size: .init(width: 60.0, height: 90.0)))

			// Add in view hierarchy and hook up to the animator.
			view.addSubview(balloon)
			balloonSpot.assign(balloon: balloon)
			balloonSpot.move(by: .init(x: -radius, y: -radius))
			return balloonSpot
		}

		// Add a pan gesture in order to move the balloons.
		let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(recognizer:)))
		view.addGestureRecognizer(panRecognizer)
	}

	// MARK: - Actions

	@IBAction private func handleBlackHoleAction(_ sender: UIButton) {
		// Hide the button and activate the black hole effect dynamicField.
		blackHoleButton.isHidden = true
		blackHoleImageView.isHidden = false

		// Game over, stop the timer.
		scrambleTimer.invalidate()

		// Enable the debug so we can see the interaction.
		balloonSpots.lazy
			// Remove them from any other field that they're under.
			.compactMap { $0.removeBalloon() }
			// Add them to the black hole gravity field.
			.forEach {
				blackHoleVortex.addItem($0)
				blackHoleGravity.addItem($0)
			}

		DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) { [self] in
			view.subviews
				.compactMap { $0 as? BalloonView }
				.forEach { $0.removeFromSuperview() }
			blackHoleImageView.isHidden = true
			theEndLabel.isHidden = false
		}
	}

	// MARK: - Selectors.

	@objc private func scrambleBalloonSpots() {
		let size = balloonSpots.count
		let firstIndex = Int.random(in: 0..<size)
		// Create new positions for the balloons. Do not allow for situations
		// in which the new index is equal to its position in the array. That means that
		// the balloon will not change positions.
		var changedIndexes: [Int] = [firstIndex == 0 ? balloonSpots.count - 1 : firstIndex]

		while changedIndexes.count != size {
			// Make sure to create a unique index every time;
			var newIndex = firstIndex
			while changedIndexes.contains(newIndex) {
				newIndex = Int.random(in: 0..<size)
			}
			changedIndexes.append(newIndex)
		}

		// Combine all the removed balloons with their new positions
		// and assign them so they'll change places.
		zip(
			balloonSpots.compactMap { $0.removeBalloon() },
			changedIndexes
		)
		.forEach { (balloon, newIndex) in balloonSpots[newIndex].assign(balloon: balloon) }
	}

	@objc private func handlePan(recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .changed:
			let deltaPosition = recognizer.translation(in: view)
			// Reset the translation so we always get relative to the last detected point.
			recognizer.setTranslation(.zero, in: view)

			// Use just the y component in order to consider a move on the
			// line whose curve is determined by the center of the screen and the initial
			// position of the balloons. That is ultimately the angle from the tuple.
			balloonSpots.forEach { $0.move(by: deltaPosition) }

		case .possible, .began, .ended, .cancelled, .failed:
			// Don't care about those cases.
			break

		@unknown default:
			break
		}
	}
}
