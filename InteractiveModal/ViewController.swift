//
//  ViewController.swift
//  InteractiveModal
//
//  Created by Takeru Sato on 2019/01/02.
//  Copyright © 2019 son. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {
    
    enum CardState {
        case expanded
        case collapsed
    }
    
    private var cardViewController: CardViewController!
    private var visualEffectView: UIVisualEffectView!
    
    private let cardHeight: CGFloat = 600
    private let cardhandleAreaHEight: CGFloat = 65
    
    private var isCardVisible = false
    private var nextState: CardState {
        return isCardVisible ? .collapsed : .expanded
    }
    
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationProgressWhenInterrupted: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCard()
    }
    
    private func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = view.frame
        view.addSubview(visualEffectView)
        
        cardViewController = CardViewController(nibName: "CardViewController", bundle: nil)
        addChild(cardViewController)
        view.addSubview(cardViewController.view)
        
        cardViewController.view.frame = CGRect(
            x: 0,
            y: view.frame.height - cardhandleAreaHEight,
            width: view.bounds.width, height: cardHeight)
        
        cardViewController.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardViewTapped)))
        cardViewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(cardViewPanned)))
    }
    
    @objc private func cardViewTapped(gesture: UITapGestureRecognizer) {
        switch gesture.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    
    @objc private func cardViewPanned(gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            startInteractiveTransition(state: nextState, duration: 0.9)
        case .changed:
            let transition = gesture.translation(in: self.cardViewController.view)
            var fractionComplete = transition.y / cardHeight
            fractionComplete = isCardVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    private func animateTransitionIfNeeded(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardHeight
                case .collapsed:
                    self.cardViewController.view.frame.origin.y = self.view.frame.height - self.cardhandleAreaHEight
                }
            }
            frameAnimator.addCompletion { _ in
                self.isCardVisible.toggle()
                self.runningAnimations.removeAll()
            }
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear) {
                switch state {
                case .expanded:
                    self.cardViewController.view.layer.cornerRadius = 12
                case .collapsed:
                    self.cardViewController.view.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            
            let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapsed:
                    self.visualEffectView.effect = nil
                }
            }
            blurAnimator.startAnimation()
            runningAnimations.append(blurAnimator)
        }
    }
    
    private func startInteractiveTransition(state: CardState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationProgressWhenInterrupted = animator.fractionComplete
        }
    }
    
    private func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        }
    }
    
    private func continueInteractiveTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
}

