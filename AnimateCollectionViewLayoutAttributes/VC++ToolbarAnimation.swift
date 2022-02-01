//
//  VC++ToolbarAnimation.swift
//  AnimateCollectionViewLayoutAttributes
//
//  Created by Hammad Ashraf on 01/02/2022.
//

import Foundation

import UIKit

extension ViewController {
    
    // MARK: Toolbar collapsing animation
    func setupCollapsingToolbarAnimator() {
        collapsingToolbarAnimator?.stopAnimation(true)
        collapsingToolbarAnimator?.finishAnimation(at: .current)
        addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewCollapsingHalfwayBottomOffset)
        toolbarBottomConstraint?.update(offset: toolbarCollapsingHalfwayBottomOffset)
        collapsingToolbarAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
            self?.setAddressBarContainersAlpha(0)
            self?.view.layoutIfNeeded()
        }
        collapsingToolbarAnimator?.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.addressBarsScrollViewBottomConstraint?.update(offset: self.addressBarsScrollViewCollapsingFullyBottomOffset)
            self.toolbarBottomConstraint?.update(offset: self.toolbarCollapsingFullyBottomOffset)
            UIViewPropertyAnimator(duration: 0.2, curve: .easeOut) { [weak self] in
                guard let self = self else { return }
                self.currentAddressBar.containerView.transform = CGAffineTransform(scaleX: 1.2, y: 0.8)
                self.currentAddressBar.domainLabel.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
                self.leftAddressBar?.containerView.transform = CGAffineTransform(scaleX: 1, y: 0.8)
                self.rightAddressBar?.containerView.transform = CGAffineTransform(scaleX: 1, y: 0.8)
                self.view.layoutIfNeeded()
            }.startAnimation()
        }
        collapsingToolbarAnimator?.pauseAnimation()
    }
    
    func reverseCollapsingToolbarAnimation() {
        // isReversed property does not work correctly with autolayout constraints so we have to manually animate back collapsing state
        // http://www.openradar.me/34674968
        guard let collapsingToolbarAnimator = collapsingToolbarAnimator else { return }
        addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewCollapsingHalfwayBottomOffset * collapsingToolbarAnimator.fractionComplete)
        toolbarBottomConstraint?.update(offset: toolbarCollapsingHalfwayBottomOffset * collapsingToolbarAnimator.fractionComplete)
        view.layoutIfNeeded()
        collapsingToolbarAnimator.stopAnimation(true)
        collapsingToolbarAnimator.finishAnimation(at: .current)
        addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewExpandingFullyBottomOffset)
        toolbarBottomConstraint?.update(offset: 0)
        UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
            self?.setAddressBarContainersAlpha(1)
            self?.view.layoutIfNeeded()
        }.startAnimation()
    }
    
    // MARK: Toolbar expanding animation
    func setupExpandingToolbarAnimator() {
        expandingToolbarAnimator?.stopAnimation(true)
        expandingToolbarAnimator?.finishAnimation(at: .current)
        addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewExpandingHalfwayBottomOffset)
        toolbarBottomConstraint?.update(offset: toolbarExpandingHalfwayBottomOffset)
        expandingToolbarAnimator = UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
            self?.view.layoutIfNeeded()
        }
        expandingToolbarAnimator?.addCompletion { [weak self] _ in
            guard let self = self else { return }
            self.toolbarBottomConstraint?.update(offset: self.toolbarExpandingFullyBottomOffset)
            self.addressBarsScrollViewBottomConstraint?.update(offset: self.addressBarsScrollViewExpandingFullyBottomOffset)
            UIViewPropertyAnimator(duration: 0.2, curve: .easeIn) { [weak self] in
                self?.currentAddressBar.containerView.transform = .identity
                self?.currentAddressBar.domainLabel.transform = .identity
                self?.leftAddressBar?.containerView.transform = .identity
                self?.rightAddressBar?.containerView.transform = .identity
                self?.setAddressBarContainersAlpha(1)
                self?.view.layoutIfNeeded()
            }.startAnimation()
        }
        expandingToolbarAnimator?.pauseAnimation()
    }
    
    func reverseExpandingToolbarAnimation() {
        guard let expandingToolbarAnimator = expandingToolbarAnimator else { return }
        addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewExpandingHalfwayBottomOffset * expandingToolbarAnimator.fractionComplete)
        toolbarBottomConstraint?.update(offset: toolbarExpandingHalfwayBottomOffset * expandingToolbarAnimator.fractionComplete)
        view.layoutIfNeeded()
        expandingToolbarAnimator.stopAnimation(true)
        expandingToolbarAnimator.finishAnimation(at: .current)
        addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewCollapsingFullyBottomOffset)
        toolbarBottomConstraint?.update(offset: toolbarCollapsingFullyBottomOffset)
        UIViewPropertyAnimator(duration: 0.1, curve: .linear) { [weak self] in
            self?.setAddressBarContainersAlpha(0)
            self?.view.layoutIfNeeded()
        }.startAnimation()
    }
    
    func setAddressBarContainersAlpha(_ alpha: CGFloat) {
        currentAddressBar.containerView.alpha = alpha
        leftAddressBar?.containerView.alpha = alpha
        
        let rightAddressBarIndex = currentTabIndex + 1
        if !hasHiddenTab || rightAddressBarIndex < data.count - 1 {
            // modify the right address bar only if there is no hidden right address bar
            // or the current right address bar is not the last one
            rightAddressBar?.containerView.alpha = alpha
        }
    }
}

extension ViewController: BrowserTabViewControllerDelegate {
    
    // MARK: Toolbar collapsing/expanding bar animation handling
    func tabViewControllerDidScroll(yOffsetChange: CGFloat) {
        let offsetChangeBeforeFullAnimation = CGFloat(30)
        let animationFractionComplete = abs(yOffsetChange) / offsetChangeBeforeFullAnimation
        let tresholdBeforeAnimationCompletion = CGFloat(0.6)
        let isScrollingDown = yOffsetChange < 0
        
        if isScrollingDown {
            // if we are scrolling down and the toolbar is collapsed then we skip the animation
            guard !isCollapsed else { return }
            
            // if an animator does not exist (e.g. we just started the animation)
            // or if the animation completed once but user keeps scrolling without ending the pan gesture
            // then we need to recreate a new animator
            if collapsingToolbarAnimator == nil || collapsingToolbarAnimator?.state == .inactive {
                setupCollapsingToolbarAnimator()
            }
            
            if animationFractionComplete < tresholdBeforeAnimationCompletion {
                collapsingToolbarAnimator?.fractionComplete = animationFractionComplete
            } else {
                isCollapsed = true
                collapsingToolbarAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        } else {
            guard isCollapsed else { return }
            if expandingToolbarAnimator == nil || expandingToolbarAnimator?.state == .inactive {
                setupExpandingToolbarAnimator()
            }
            
            if animationFractionComplete < tresholdBeforeAnimationCompletion {
                expandingToolbarAnimator?.fractionComplete = animationFractionComplete
            } else {
                isCollapsed = false
                expandingToolbarAnimator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
            }
        }
    }
    
    func tabViewControllerDidEndDragging() {
        // if the collapsing animator is active, but the toolbar is not fully collapsed then we need to revert the animation
        if let collapsingToolbarAnimator = collapsingToolbarAnimator,
           collapsingToolbarAnimator.state == .active,
           !isCollapsed {
            reverseCollapsingToolbarAnimation()
        }
        
        // if the expanding animator is active, but the toolbar is not fully expanded then we need to revert the animation
        if let expandingToolbarAnimator = expandingToolbarAnimator,
           expandingToolbarAnimator.state == .active,
           isCollapsed {
            reverseExpandingToolbarAnimation()
        }
        
        collapsingToolbarAnimator = nil
        expandingToolbarAnimator = nil
    }
    
    // MARK: Address bar loading bar animation handling
    func tabViewController(_ cvCell: Cell, didStartLoadingURL url: URL) {
        guard let addressBar = addressBars[safe: cvCell.indexItem ?? 0] else { return }
        
        addressBar.setLoadingProgress(0, animated: false)
        addressBar.domainLabel.text = viewModel.getDomain(from: url)
    }
    
    func tabViewController(_ cvCell: Cell, didChangeLoadingProgressTo progress: Float) {
        
        addressBars[safe: cvCell.indexItem ?? 0]?.setLoadingProgress(progress, animated: true)
    }
}
