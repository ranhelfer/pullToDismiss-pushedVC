//
//  ControllerAnimatedTransitioning.swift
//
//  Created by Ran Helfer on 3/12/2020.

import UIKit

public enum AnimationDirection {
    case up
    case right
    case left
    case down
}

public enum PullToDismissMethod {
    case pop
    case dismiss
}

/*
    This class is a mix of several reference dealing with pull to dismiss and collection views.
    https://stackoverflow.com/questions/29290313/in-ios-how-to-drag-down-to-dismiss-a-modal/56113094#56113094
 
    However, there is not a full P2D tutorial for our use case. Please also see:
    https://rhelfer.medium.com/how-to-implement-pull-to-dismiss-for-a-pushed-view-controller-with-a-collection-view-ios-644bd755210e
 */

public class DismissInteractor: UIPercentDrivenInteractiveTransition {
    public var hasStarted = false
    public var shouldFinish = false
    
    /* A dynamic variable indicating if pull to dismiss is now happening from the bottom or top */
    public var animationDirection: AnimationDirection = .up
    
    /* If the view controller is presented we need also to set pullToDismissMethod to .dismiss */
    public var pullToDismissMethod: PullToDismissMethod = .pop
    
    /* Make sure that numberOfPullToDismissSteps is greater than MinimumNumberOfPullToDismissSteps, there are cases when we scroll very fast and pull to dismiss is wrongly recognized */
    private var numberOfPullToDismissSteps = 0
    static var MinimumNumberOfPullToDismissSteps = 5

    /* not owned varibales so we can spare code duplications at the different view controllers */
    private weak var scrollView: UIScrollView?
    private weak var viewController: UIViewController?

    /* Pull to dismiss gesture Threshold */
    let shouldFinishPullToDismissThreshold = CGFloat(0.4)
    
    /* for iPad in case we dismiss from the bottom we need for some reason additional 2 pixels */
    static let AdditionalMarginForIPad = CGFloat(2.0)

    private var initialContentOffset: CGPoint = .zero
    
    /* pull to dismiss should be setup with a collection view and the relevant view controller */
    public func setUp(scrollView: UIScrollView? = nil,
                      viewController: UIViewController) {
        self.scrollView = scrollView
        self.viewController = viewController

        hasStarted = false
        animationDirection = .down
        
        if let scrollView = scrollView {
            scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleGesture(_:)))
        } else {
            viewController.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:))))
        }
    }
        
    private func pullToDismissViewController() {
        switch pullToDismissMethod {
        case .pop:
            viewController?.navigationController?.popViewController(animated: true)
            break
        case .dismiss:
            viewController?.presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    override public func cancel() {
        super.cancel()
        hasStarted = false
        numberOfPullToDismissSteps = 0
    }
    
    @objc func handleGesture(_ sender: UIPanGestureRecognizer) {
        if !hasStarted && sender.state == .ended, let scrollView = scrollView, !scrollView.isDragging {
            /* P2D has started and cancelled, however, user did not move his finger off the screen */
            cancel()
            return
        }
        
        var translation: CGPoint = .zero
        var verticalMovement: CGFloat = 0
        
        if let scrollView = scrollView,
              scrollView.contentSize.height > 0 {
            
            // convert y-position to downward pull progress (percentage)
            translation = sender.translation(in: scrollView.superview)
            verticalMovement = -translation.y / (scrollView.superview?.bounds.height ?? 1)
                
            if !hasStarted {
                
                initialContentOffset = scrollView.contentOffset

                if scrollView.contentOffset.y >= scrollView.contentSize.height - scrollView.frame.size.height -  Self.AdditionalMarginForIPad && verticalMovement >= 0 {
                    animationDirection = .up
                } else if scrollView.contentOffset.y <= 0 && verticalMovement <= 0 {
                    animationDirection = .down
                } else {
                    return
                }
            }
        } else {
            translation = sender.translation(in: sender.view)
            verticalMovement = -translation.y / (sender.view?.bounds.height ?? 1)
            print("vertical movement \(verticalMovement)")
            if verticalMovement > 0 {
                animationDirection = .up
            } else {
                animationDirection = .down
            }
        }
        
        let movement = fmaxf(fabsf(Float(verticalMovement)), 0.0)
        let movementPercent = fminf(movement, 1.0)
        let progress = CGFloat(movementPercent)
        
        switch sender.state {
        case .began:
            numberOfPullToDismissSteps = 0
            hasStarted = true
            pullToDismissViewController()
        case .changed:
            if let scrollView = scrollView {
                scrollView.contentOffset = initialContentOffset
            }
            
            if (animationDirection == .down && verticalMovement > 0) || (animationDirection == .up && verticalMovement < 0) {
                /* in case gesture is opposite to initial animationDirection and user is still dragging */
                return
            }
            
            numberOfPullToDismissSteps += 1
            shouldFinish = progress > shouldFinishPullToDismissThreshold
            update(progress)
        case .cancelled:
            cancel()
        case .ended:
            if shouldFinish && numberOfPullToDismissSteps > Self.MinimumNumberOfPullToDismissSteps {
                hasStarted = false
                finish()
                pullToDismissViewController()
            } else {
                cancel()
            }
        default:
            break
        }
    }
}

public class ControllerAnimatedTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    
    public var animationDirection: AnimationDirection = .up
    private let transitionTime = TimeInterval(1.0)
    public var pullToDismissMethod: PullToDismissMethod = .pop

    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionTime
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)
            else {
                return
        }
        
        let fromVCInitialFrame = fromVC.view.frame
        
        if pullToDismissMethod == .pop {
            transitionContext.containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        }
        
        let finalFrame = frameForAnimation()
        toVC.view.alpha = 0.6
        
        /* Special treatment for tab bar */
        let tabBarCenterKeeper = CGPoint(x: toVC.view.center.x, y: toVC.tabBarController?.tabBar.center.y ?? 0)
        toVC.tabBarController?.tabBar.center = CGPoint(x: toVC.view.center.x, y: tabBarCenterKeeper.y + (toVC.tabBarController?.tabBar.bounds.size.height ?? 0))
        toVC.tabBarController?.tabBar.alpha = 0.0
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            animations: {
                fromVC.view.frame = finalFrame
                toVC.view.alpha = 1.0
                
                /* Special treatment for tab bar */
                toVC.tabBarController?.tabBar.center = tabBarCenterKeeper
                toVC.tabBarController?.tabBar.alpha = 1.0
        },
            completion: { _ in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                fromVC.view.frame = fromVCInitialFrame
                toVC.view.alpha = 1.0
                
                /* Special treatment for tab bar */
                toVC.tabBarController?.tabBar.center = tabBarCenterKeeper
                toVC.tabBarController?.tabBar.alpha = 1.0        })
    }
    
    private func frameForAnimation() -> CGRect {
        let screenBounds = UIScreen.main.bounds
        var finalTopLeftCorner: CGPoint = .zero
        
        switch animationDirection {
        case .right:
            finalTopLeftCorner = CGPoint(x: screenBounds.width, y: 0)
            break
        case .left:
            finalTopLeftCorner = CGPoint(x: -screenBounds.width, y: 0)
            break
        case .down:
            finalTopLeftCorner = CGPoint(x: 0, y: screenBounds.height)
            break
        case .up:
            finalTopLeftCorner = CGPoint(x: 0, y: -screenBounds.height)
            break
        }
        
        return CGRect(origin: finalTopLeftCorner, size: screenBounds.size)
    }
}
