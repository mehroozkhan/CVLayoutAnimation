//
//  ViewController.swift
//  AnimateBetweenCollectionLayouts
//
//  Created by Zheng on 6/20/21.
//

import UIKit
import SnapKit

protocol CellDelegate {
    func closeTapped(indexItem: Int)
}

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    let viewModel = BrowserContainerViewModel()
    
    // Address bar animation constants
    let tabsStackViewSpacing = CGFloat(24)
    let addressBarWidthOffset = CGFloat(-48)
    let addressBarContainerHidingWidthOffset = CGFloat(-200)
    let addressBarsStackViewSidePadding = CGFloat(24)
    let addressBarsStackViewSpacing = CGFloat(4)
    let addressBarsHidingCenterOffset = CGFloat(30)
    
    // Toolbar collapsing and expanding animation constants
    let addressBarsScrollViewExpandingHalfwayBottomOffset = CGFloat(-22)
    let addressBarsScrollViewExpandingFullyBottomOffset = CGFloat(-38)
    let addressBarsScrollViewCollapsingHalfwayBottomOffset = CGFloat(-8)
    let addressBarsScrollViewCollapsingFullyBottomOffset = CGFloat(20)
    let toolbarCollapsingHalfwayBottomOffset = CGFloat(30)
    let toolbarCollapsingFullyBottomOffset = CGFloat(80)
    let toolbarExpandingHalfwayBottomOffset = CGFloat(40)
    let toolbarExpandingFullyBottomOffset = CGFloat(0)
    
    // Toolbar animation properties
    var collapsingToolbarAnimator: UIViewPropertyAnimator?
    var expandingToolbarAnimator: UIViewPropertyAnimator?
    var isCollapsed = false
    
    var addressBarPageWidth: CGFloat {
        view.frame.width + addressBarWidthOffset + addressBarsStackViewSpacing
    }
    
    var data:[String] = []
    
    var isExpanded = false
    lazy var listLayout = FlowLayout(layoutType: .list)
    lazy var stripLayout = FlowLayout(layoutType: .strip)
    
    var addressBars: [BrowserAddressBar] {
      addressBarsStackView.arrangedSubviews as? [BrowserAddressBar] ?? []
    }
    
    var isAddressBarActive = false
    var hasHiddenTab = false
    var currentTabIndex = 0 {
        didSet {
            updateAddressBarsAfterTabChange()
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    var currentAddressBar: BrowserAddressBar {
      addressBars[currentTabIndex]
    }
    
    var leftAddressBar: BrowserAddressBar? {
      addressBars[safe: currentTabIndex - 1]
    }
    
    var rightAddressBar: BrowserAddressBar? {
      addressBars[safe: currentTabIndex + 1]
    }
    
    @IBOutlet weak var cvLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var cvTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionView: UICollectionView!
    
    let cancelButton = UIButton(type: .system)
    let toolbar = BrowserToolbar()
    var toolbarBottomConstraint: Constraint?
    var addressBarsScrollViewBottomConstraint: Constraint?
    var addressBarKeyboardBackgroundViewBottomConstraint: Constraint?
    
    let addressBarKeyboardBackgroundView = UIView()
    
    let addressBarsStackView = UIStackView()
    let addressBarsScrollView = UIScrollView()
    
    var addressBarGesture: UIPanGestureRecognizer!
    var toolBarGesture: UIPanGestureRecognizer!
    
    var cvContentOffset = CGPoint(x: 0, y: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.collectionViewLayout = stripLayout /// start with the strip layout
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.isScrollEnabled = false
        //collectionView.layer.masksToBounds = false
        addressBarGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        toolBarGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addressBarGesture.delegate = self
        toolBarGesture.delegate = self
        self.addressBarsScrollView.addGestureRecognizer(addressBarGesture)
        self.toolbar.addGestureRecognizer(toolBarGesture)
        
        setupToolbar()
        setupAddressBarsScrollView()
        setupAddressBarsStackView()
        setupAddressBarKeyboardBackgroundView()
        setupCancelButton()
        setupKeyboardManager()
        addressBarsScrollView.delegate = self
        
        openNewTab(isHidden: false)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func openNewTab(isHidden: Bool) {
      addNewCell(isHidden: isHidden)
      addAddressBar(isHidden: isHidden)
    }
    
    func addNewCell(isHidden: Bool) {
        self.data.append("")
        self.stripLayout.preparedOnce = false
        self.collectionView.reloadData()
    }
    
    func addAddressBar(isHidden: Bool) {
        let addressBar = BrowserAddressBar()
        addressBar.delegate = self
        addressBarsStackView.addArrangedSubview(addressBar)
        addressBar.snp.makeConstraints {
            $0.width.equalTo(collectionView).offset(addressBarWidthOffset)
        }
        
        if isHidden {
            hasHiddenTab = true
            addressBar.containerViewWidthConstraint?.update(offset: addressBarContainerHidingWidthOffset)
            addressBar.containerView.alpha = 0
            addressBar.plusOverlayView.alpha = 1
        }
    }
    
    func updateAddressBarsAfterTabChange() {
      currentAddressBar.setSideButtonsHidden(false)
      currentAddressBar.isUserInteractionEnabled = true
      leftAddressBar?.setSideButtonsHidden(true)
      leftAddressBar?.isUserInteractionEnabled = false
      rightAddressBar?.setSideButtonsHidden(true)
      rightAddressBar?.isUserInteractionEnabled = false
    }
    
    func setupToolbar() {
        view.addSubview(toolbar)
        toolbar.snp.makeConstraints {
            //$0.top.equalTo(collectionView.snp.bottom)
            $0.leading.trailing.equalToSuperview()
            toolbarBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).constraint
            $0.height.equalTo(100)
        }
    }
    
    func setupAddressBarsScrollView() {
        addressBarsScrollView.clipsToBounds = false
        addressBarsScrollView.showsHorizontalScrollIndicator = false
        addressBarsScrollView.showsVerticalScrollIndicator = false
        addressBarsScrollView.decelerationRate = .fast
        view.addSubview(addressBarsScrollView)
        addressBarsScrollView.snp.makeConstraints {
            addressBarsScrollViewBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(addressBarsScrollViewExpandingFullyBottomOffset).constraint
            $0.leading.trailing.equalToSuperview()
        }
    }
    
    func setupAddressBarsStackView() {
        addressBarsStackView.clipsToBounds = false
        addressBarsStackView.axis = .horizontal
        addressBarsStackView.alignment = .fill
        addressBarsStackView.distribution = .fill
        addressBarsStackView.spacing = addressBarsStackViewSpacing
        addressBarsScrollView.addSubview(addressBarsStackView)
        addressBarsStackView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.leading.equalToSuperview().offset(addressBarsStackViewSidePadding)
            $0.trailing.equalToSuperview().offset(-addressBarsStackViewSidePadding)
            $0.height.equalToSuperview()
        }
    }
    
    func setupAddressBarKeyboardBackgroundView() {
        addressBarKeyboardBackgroundView.backgroundColor = .keyboardGray
        view.insertSubview(addressBarKeyboardBackgroundView, belowSubview: toolbar)
        addressBarKeyboardBackgroundView.snp.makeConstraints {
            addressBarKeyboardBackgroundViewBottomConstraint = $0.bottom.equalTo(view.safeAreaLayoutGuide).constraint
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(72)
        }
    }
    
    func setupCancelButton() {
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.alpha = 0
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            $0.trailing.equalToSuperview().inset(24)
        }
    }
    
    @objc func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        
        if isExpanded {
            return
        }
        
        let translation = gestureRecognizer.translation(in: self.view)
        let computedTranslation = abs(abs(translation.y/collectionView.frame.size.height) - 1)
        
        if gestureRecognizer.state == .began {
            stripLayout.visibleItem = getVisibleItem()
            cvContentOffset = collectionView.contentOffset
        }
        
        if gestureRecognizer.state == .changed {
            
            self.collectionView.setContentOffset(CGPoint(x: (translation.x * -1) + cvContentOffset.x, y: 0), animated: false)
            
            if translation.y < 0, computedTranslation > 0.5 {
                stripLayout.shrinkCell = computedTranslation
                stripLayout.reset()
                stripLayout.prepare()
                stripLayout.invalidateLayout()
            }
        }
        
        if gestureRecognizer.state == .ended {
            
            if abs(translation.y) > 150 {
                stripLayout.shrinkCell = 1
                toggleExpandPressed()
            }
            else {
                _ = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                    if self.stripLayout.shrinkCell >= 1 {
                        timer.invalidate()
                    }
                    else {
                        self.stripLayout.shrinkCell += 0.01
                        if self.stripLayout.shrinkCell > 1 {
                            self.stripLayout.shrinkCell = 1.0
                        }
                        self.stripLayout.reset()
                        self.stripLayout.prepare()
                        self.stripLayout.invalidateLayout()
                        
                        //self.addressBarsScrollView.isUserInteractionEnabled = false
                    }
                }
            }
        }
    }
    
    func getVisibleItem() -> Int {
        let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView!.indexPathForItem(at: visiblePoint)
        return visibleIndexPath?.item ?? 0
    }
    
    func toggleExpandPressed() {
        // See change in layout better
        collectionView.layer.speed = 0.5
        //collectionView.layer.duration = CFTimeInterval(1)
        
        isExpanded.toggle()
        
        if isExpanded {
            collectionView.isPagingEnabled = false
            listLayout.reset()
            listLayout.animating = true
            collectionView.setCollectionViewLayout(listLayout, animated: true) { (completed) in
                if completed{
                    self.listLayout.animating = false
                    self.collectionView.isScrollEnabled = true
                    self.collectionView.reloadData()
                }
            }
        } else {
            collectionView.isPagingEnabled = true
            stripLayout.reset()
            stripLayout.animating = true
            collectionView.setCollectionViewLayout(stripLayout, animated: true) { (completed) in
                if completed{
                    self.stripLayout.animating = false
                    self.collectionView.isScrollEnabled = false
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    func setCancelButtonHidden(_ isHidden: Bool) {
      UIView.animate(withDuration: 0.1) {
        self.cancelButton.alpha = isHidden ? 0 : 1
      }
    }
}

/// sample data source
extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ID", for: indexPath) as! Cell
        
        cell.label.isHidden = !isExpanded
        cell.closeButton.isHidden = !isExpanded
        
        cell.cellDelegate = self
        cell.delegate = self
        cell.indexItem = indexPath.item
        if isExpanded {
            cell.webView.isUserInteractionEnabled = false
            cell.topViewHeightConstraint.constant = 0
            cell.topView.isHidden = true
        } else {
            cell.webView.isUserInteractionEnabled = true
            let height = view.window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 40
            cell.topViewHeightConstraint.constant = height
            cell.topView.isHidden = false
        }
        
        
        if indexPath.item == self.data.count - 1, data.count > 1 {
            cell.contentView.alpha = 0
        } else {
            cell.contentView.alpha = 1
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !isExpanded {
            toggleExpandPressed()
            return
        }

        stripLayout.selectedItem = indexPath.item
        if let cell = collectionView.cellForItem(at: indexPath) as? Cell {
            cell.label.isHidden = true
            cell.closeButton.isHidden = true
        }
        isExpanded.toggle()
        collectionView.isPagingEnabled = true
        stripLayout.reset()
        stripLayout.animating = true

        self.collectionView.setCollectionViewLayout(self.stripLayout, animated: true) { (completed) in
            if completed{
                self.stripLayout.animating = false
                self.collectionView.isScrollEnabled = false
                self.collectionView.reloadData()
            }
        }
    }
}

extension ViewController: CellDelegate {
    
    func closeTapped(indexItem: Int) {
        self.data.remove(at: indexItem)
        //self.collectionView.reloadData()
        
        let indexPath = IndexPath(item: indexItem, section: 0)
        self.collectionView.performBatchUpdates({
            self.collectionView.deleteItems(at:[indexPath])
        }, completion: {_ in
            self.collectionView.reloadData()
        })
    }
}


extension ViewController: BrowserAddressBarDelegate {
    
  func addressBarDidBeginEditing() {
    isAddressBarActive = true
  }
  
  func addressBar(_ addressBar: BrowserAddressBar, didReturnWithText text: String) {
      
      guard let cvCell = self.collectionView.cellForItem(at: IndexPath(item: currentTabIndex, section: 0)) as? Cell else { return }
      let isLastTab = currentTabIndex == self.data.count - 1
      
    if isLastTab && !cvCell.hasLoadedUrl {
      // if we started loading a URL and it is on the last tab then ->
      // open a hidden tab so that we can prepare it for new tab animation if the user swipes to the left
      openNewTab(isHidden: true)
    }
      
    if let url = self.viewModel.getURL(for: text) {
      addressBar.domainLabel.text = viewModel.getDomain(from: url)
        cvCell.loadWebsite(from: url)
    }
      view.endEditing(true)
  }
}

