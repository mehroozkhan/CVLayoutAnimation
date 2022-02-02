//
//  VC+Keyboard.swift
//  AnimateCollectionViewLayoutAttributes
//
//  Created by Hammad Ashraf on 31/01/2022.
//

import UIKit

import UIKit

extension ViewController {
    
  func setupKeyboardManager() {
    viewModel.setKeyboardHandler(onKeyboardWillShow: { [weak self] notification in
      guard let self = self, self.isAddressBarActive else { return }
      self.setCancelButtonHidden(false)
      self.animateWithKeyboard(for: notification) { keyboardFrame in
        self.updateStateForKeyboardAppearing(with: keyboardFrame.height)
      }
    }, onKeyboardWillHide: { [weak self] notification in
      guard let self = self, self.isAddressBarActive else { return }
      self.isAddressBarActive = false
      self.setCancelButtonHidden(true)
      self.animateWithKeyboard(for: notification) { _ in
        self.updateStateForKeyboardDisappearing()
      }
    })
  }
    
}

// MARK: Helper methods
private extension ViewController {
    func animateWithKeyboard(for notification: NSNotification, animation: ((CGRect) -> Void)?) {
        guard let frame = notification.keyboardEndFrame,
              let duration = notification.keyboardAnimationDuration,
              let curve = notification.keyboardAnimationCurve else {
                  return
              }
        UIViewPropertyAnimator(duration: duration, curve: curve) {
            animation?(frame)
            self.view?.layoutIfNeeded()
        }.startAnimation()
    }
  
    func updateStateForKeyboardAppearing(with keyboardHeight: CGFloat) {
        addressBarKeyboardBackgroundView.isHidden = false
        let offset = keyboardHeight - view.safeAreaInsets.bottom
        addressBarKeyboardBackgroundViewBottomConstraint?.update(offset: -offset + 10)
        addressBarsScrollViewBottomConstraint?.update(offset: -offset)
        
        //self.collectionView.cellForItem(at: IndexPath(item: currentTabIndex, section: 0))
        //tabViewControllers[safe: currentTabIndex]?.showEmptyState()
        setSideAddressBarsHidden(true)
    }
  
  func updateStateForKeyboardDisappearing() {
    addressBarKeyboardBackgroundView.isHidden = true
    addressBarKeyboardBackgroundViewBottomConstraint?.update(offset: 0)
    addressBarsScrollViewBottomConstraint?.update(offset: addressBarsScrollViewExpandingFullyBottomOffset)
    setSideAddressBarsHidden(false)
  }
  
  func setSideAddressBarsHidden(_ isHidden: Bool) {
    if let leftAddressBar = leftAddressBar {
      setHidden(isHidden, forLeftAddressBar: leftAddressBar)
    }
    if let rightAddressBar = rightAddressBar {
      setHidden(isHidden, forRightAddressBar: rightAddressBar)
    }
  }
  
  func setHidden(_ isHidden: Bool, forRightAddressBar addressBar: UIView) {
    // In some cases keyboard will show is called multiple times.
    // To prevent the address bar center from being offset multiple times we have to check if it is already offset
    if (isHidden && addressBar.alpha == 0) {
      return
    }
    
    let offset = addressBarsHidingCenterOffset
    if isHidden {
      addressBar.center = CGPoint(x: addressBar.center.x + offset,
                                  y: addressBar.center.y - offset)
    } else {
      addressBar.center = CGPoint(x: addressBar.center.x - offset,
                                  y: addressBar.center.y + offset)
    }
    addressBar.alpha = isHidden ? 0 : 1
  }
  
  func setHidden(_ isHidden: Bool, forLeftAddressBar addressBar: UIView) {
    if (isHidden && addressBar.alpha == 0) {
      return
    }
    
    let offset = addressBarsHidingCenterOffset
    if isHidden {
      addressBar.center = CGPoint(x: addressBar.center.x - offset,
                                  y: addressBar.center.y - offset)
    } else {
      addressBar.center = CGPoint(x: addressBar.center.x + offset,
                                  y: addressBar.center.y + offset)
    }
    addressBar.alpha = isHidden ? 0 : 1
  }
}


