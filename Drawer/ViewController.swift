import UIKit
import Foundation
import SnapKit

class ViewController: UIViewController {
    
    let interactiveTransition = UserPanPercentDriveInteractionTransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button = UIButton(type: .detailDisclosure)
        button.setTitle("Present", for: .normal)
        button.tintColor = UIColor.black
        self.view.addSubview(button)
        button.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        
        let uipanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panGes))
        uipanGestureRecognizer.edges = .left
        self.view.addGestureRecognizer(uipanGestureRecognizer)
        
    }
    
    @objc func panGes(_ ges: UIPanGestureRecognizer) {
        let containerView = self.view
        let dis = ges.translation(in: containerView).x
        let velocity = ges.velocity(in: containerView).x
        
        let percent = abs(dis) / (containerView?.bounds.width ?? UIScreen.main.bounds.width)
        //        print("dismiss \(percent)")
        
        if ges.state == .began {
            interactiveTransition.isEnable = true
            let drawer = Drawer()
            transition.interactiveTransition = interactiveTransition
            drawer.modalPresentationStyle = .custom
            drawer.transitioningDelegate = transition
            self.present(drawer, animated: true)
        } else if ges.state == .changed {
            
            self.interactiveTransition.update(percent)
        } else if ges.state == .ended {
            print("percent is \(percent)  velocity is \(velocity)")
            if percent > 0.5 || abs(velocity) > 500 {
                self.interactiveTransition.finish()
            } else {
                self.interactiveTransition.cancel()
            }
        }
    }
    
    let transition = DrawerTransition()
    
    @objc func buttonAction() {
        let drawer = Drawer()
        transition.interactiveTransition = interactiveTransition
        drawer.modalPresentationStyle = .custom
        drawer.transitioningDelegate = transition
        
        self.present(drawer, animated: true)
    }
}


class Drawer: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.systemBlue
        
        let button = UIButton(type: .system)
        button.setTitle("Dismiss", for: .normal)
        button.tintColor = UIColor.black
        self.view.addSubview(button)
        button.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
    }
    
    @objc func buttonAction() {
        self.dismiss(animated: true)
    }
}


class DrawerTransition: NSObject, UIViewControllerTransitioningDelegate {
    
    let slideAnimation = DrawerSlideAnimation()
    
    var interactiveTransition: UserPanPercentDriveInteractionTransition?
    
    
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return DrawerPresentationController(interactiveTransition: interactiveTransition, presentedViewController: presented, presenting: presenting)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        slideAnimation.isPresenting = false
        print("animationController forDismissed")
        return slideAnimation
    }
    
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        slideAnimation.isPresenting = true
        print("animationController forPresented")
        return slideAnimation
    }
    
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        print("interactionControllerForDismissal")
        return interactiveTransition?.isEnable == true ? interactiveTransition : nil
    }
    
    func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        print("interactionControllerForPresentation")
        return interactiveTransition?.isEnable == true ? interactiveTransition : nil
    }
}




class DrawerPresentationController: UIPresentationController {
    
    let interactiveTransition: UserPanPercentDriveInteractionTransition?
    
    init(interactiveTransition: UserPanPercentDriveInteractionTransition?, presentedViewController: UIViewController, presenting: UIViewController?) {
        self.interactiveTransition = interactiveTransition
        super.init(presentedViewController: presentedViewController, presenting: presenting)
        
    }
    
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    
    @objc func dismiss(_ ges: UIPanGestureRecognizer) {
        let dis = ges.translation(in: containerView).x
        let velocity = ges.velocity(in: containerView).x
        
        let percent = abs(dis) / (containerView?.bounds.width ?? UIScreen.main.bounds.width)
        //        print("dismiss \(percent)")
        
        if ges.state == .began {
            interactiveTransition?.isEnable = true
            self.presentingViewController.dismiss(animated: true)
        } else if ges.state == .changed {
            
            self.interactiveTransition?.update(percent)
        } else if ges.state == .ended {
            print("percent is \(percent)  velocity is \(velocity)")
            if percent > 0.5 || abs(velocity) > 500 {
                self.interactiveTransition?.finish()
            } else {
                self.interactiveTransition?.cancel()
            }
        }
    }
    
    
    override func presentationTransitionWillBegin() {
        guard  let containerView = containerView else {
            return
        }
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(dismiss))
        containerView.addGestureRecognizer(panGesture)
        
        
        // before presentation
        // add dimmingView to container view beneath presentedController
        containerView.insertSubview(dimmingView, at: 0)
        
        // set constraints of dimming view to fit container
        // that's why we set translatesAutoresizingMaskIntoConstraints to false
        dimmingView.snp.makeConstraints { make in
            make.size.equalToSuperview()
        }
        // check for animation coordinator
        // if it's missing make dimming view visible immediately
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1
            return
        }
        // otherwise do it in animation
        // duration of this animation same as duration of slide animation
        coordinator.animate { (_) in
            self.dimmingView.alpha = 1
        }
    }
    override func dismissalTransitionWillBegin() {
        // do the same for making dimming view transparent on dismiss
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0
            return
        }
        
        coordinator.animate { (_) in
            self.dimmingView.alpha = 0
        }
    }
    
    // define default size of child controller
    // inserted in this container controller
    override func size(forChildContentContainer container: UIContentContainer, withParentContainerSize parentSize: CGSize) -> CGSize {
        // I want to have some space to the right of drawer
        // to see underlying controller
        return CGSize(width: parentSize.width * 0.8, height: parentSize.height )
    }
    // define final frame of presented controller
    // will be set at the end of animation
    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        guard let containerView = containerView else {
            return frame
        }
        frame.size = size(forChildContentContainer: presentedViewController, withParentContainerSize: containerView.bounds.size)
        return CGRect(x: 0, y: 0, width: containerView.bounds.width * 0.8, height: containerView.bounds.height)
    }
    // set final frame to controller at the begin of layouting
    //    override func containerViewWillLayoutSubviews() {
    //        presentedView?.frame = frameOfPresentedViewInContainerView
    //    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        super.dismissalTransitionDidEnd(completed)
        interactiveTransition?.isEnable = false
    }
    
    override func presentationTransitionDidEnd(_ completed: Bool) {
        super.presentationTransitionDidEnd(completed)
        interactiveTransition?.isEnable = false
    }
}


class DrawerSlideAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    var isPresenting: Bool = true
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    // DrawerSlideAnimation.swift
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // if presenting drawer will be under key .to
        // if dismissing drawer will be under key .from
        let key: UITransitionContextViewControllerKey = isPresenting ? .to : .from
        let key2: UITransitionContextViewControllerKey = isPresenting ? .from : .to
        // check if our controller exist in transition
        guard let presentingController = transitionContext.viewController(forKey: key) else {
            return
        }
        
        guard let presentedController = transitionContext.viewController(forKey: key2) else {
            return
        }
        
        // for convenience set containerView to new variable
        let containerView = transitionContext.containerView
        
        
        // define position and size of drawer at the end of presentation
        let presentedFrame = transitionContext.finalFrame(for: presentingController)
        // define position and size of drawer at the end of dismiss
        // just offset presentedFrame by its width to left
        let dismissedFrame = presentedFrame.offsetBy(dx: -presentedFrame.width, dy: 0)
        // if we are going to present controller, we need to add its view to the container
        if isPresenting {
            containerView.addSubview(presentingController.view)
        }
        // get actual duration for animation, defined in the function above
        let duration = transitionDuration(using: transitionContext)
        // we need to notify that transition is finished with status from the context, not our custom animation
        let wasCancelled = transitionContext.transitionWasCancelled
        print("aa was cancelled \(wasCancelled)")
        // define start and end frames for animation
        let fromFrame = isPresenting ? dismissedFrame : presentedFrame
        let toFrame = isPresenting ? presentedFrame : dismissedFrame
        // set start frame for controller view before animation
        presentingController.view.frame = fromFrame
        
        if isPresenting {
            presentedController.view.transform = .init(scaleX: 1, y: 1)
        } else {
            presentedController.view.transform = .init(scaleX: 0.95, y: 0.95)
        }
        
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseIn]) {
            // change controller view frame to end frame during animation
            presentingController.view.frame = toFrame
            
            if self.isPresenting {
                presentedController.view.transform = .init(scaleX: 0.95, y: 0.95)
            } else {
                presentedController.view.transform = .identity
            }
        } completion: { (_) in
            let wasCancelled2 = transitionContext.transitionWasCancelled
            print("aa was cancelled2 \(wasCancelled2)")
            // notify animation complete with context status
            transitionContext.completeTransition(!wasCancelled2)
        }
        
    }
}


class UserPanPercentDriveInteractionTransition: UIPercentDrivenInteractiveTransition {
    var isEnable = false
}


