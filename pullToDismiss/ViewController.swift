//
//  ViewController.swift
//  pullToDismiss
//
//  Created by rhalfer on 16/01/2020.
//  Copyright © 2020 rhalfer. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate {
    private var interactor = DismissInteractor()
    private var customTransition = ControllerAnimatedTransitioning()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        customTransition = ControllerAnimatedTransitioning()
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        let controller = PushedViewController(nibName: "PushedViewController", bundle: nil)
        controller.interactor = interactor
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .overCurrentContext
        
        /* Define P2D method */
        //customTransition.pullToDismissMethod = .dismiss
        //interactor.pullToDismissMethod = .dismiss
        //self.present(controller, animated: true, completion: nil)
        
        customTransition.pullToDismissMethod = .pop
        interactor.pullToDismissMethod = .pop
        self.navigationController?.pushViewController(controller, animated: true)

    }
 
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if interactor.hasStarted {
            customTransition.animationDirection = interactor.animationDirection
        } else {
            return nil
        }
        return customTransition
    }
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
    
    func animationController(forDismissed dismissed: UIViewController)
            -> UIViewControllerAnimatedTransitioning? {
        if interactor.hasStarted {
            customTransition.animationDirection = interactor.animationDirection
        } else {
            return nil
        }
        return customTransition
    }

    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning)
            -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}

