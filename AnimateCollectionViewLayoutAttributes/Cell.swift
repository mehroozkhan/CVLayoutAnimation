//
//  Utilities.swift
//  AnimateBetweenCollectionLayouts
//
//  Created by Zheng on 8/14/21.
//

import UIKit
import WebKit
import SnapKit

protocol BrowserTabViewControllerDelegate: AnyObject {
  func tabViewController(_ cvCell: Cell, didStartLoadingURL url: URL)
  func tabViewController(_ cvCell: Cell, didChangeLoadingProgressTo progress: Float)
  func tabViewControllerDidScroll(yOffsetChange: CGFloat)
  func tabViewControllerDidEndDragging()
}

class Cell: UICollectionViewCell {
    @IBOutlet weak var emptyStateView: UIView!
    
    @IBOutlet weak var label: UILabel!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var topViewHeightConstraint: NSLayoutConstraint!
    
    var cellDelegate: CellDelegate?
    weak var delegate: BrowserTabViewControllerDelegate?
    
    private var startYOffset = CGFloat(0)
    
    var indexItem: Int?
    var hasLoadedUrl = false
    var isActive = false
    
    /// https://stackoverflow.com/a/57249637/14351818
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.zPosition = CGFloat(layoutAttributes.zIndex) // or any zIndex you want to set
    }
    
    @IBAction func closeTapped(_ sender: UIButton) {
        cellDelegate?.closeTapped(indexItem: self.indexItem ?? 0)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupWebView()
        emptyStateView.alpha = 1
        
        
        contentView.layer.cornerRadius = 10
    }
    
    func loadWebsite(from url: URL) {
      webView.load(URLRequest(url: url))
      hasLoadedUrl = true
      hideEmptyStateIfNeeded()
    }
    
    func hideEmptyStateIfNeeded() {
        guard hasLoadedUrl else { return }
        UIView.animate(withDuration: 0.2) {
            self.emptyStateView.alpha = 0
        }
    }
    
    func setupWebView() {
//        webView.allowsBackForwardNavigationGestures = true
//        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
//        webView.scrollView.contentInset = .zero
//        webView.scrollView.layer.masksToBounds = false
//        webView.snp.makeConstraints {
//          $0.top.equalTo(safeAreaLayoutGuide)
//          $0.leading.bottom.trailing.equalToSuperview()
//        }
        
        
        webView.scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
        if #available(iOS 15.0, *) {
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.themeColor), options: .new, context: nil)
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.underPageBackgroundColor), options: .new, context: nil)
        }
        
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case #keyPath(WKWebView.url):
            delegate?.tabViewController(self, didStartLoadingURL: webView.url!)
        case #keyPath(WKWebView.estimatedProgress):
            delegate?.tabViewController(self, didChangeLoadingProgressTo: Float(webView.estimatedProgress))
//        case #keyPath(WKWebView.themeColor):
//            updateStatusBarColor()
//        case #keyPath(WKWebView.underPageBackgroundColor):
//            updateStatusBarColor()
        default:
            break
        }
    }
    
    @objc func handlePan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let yOffset = webView.scrollView.contentOffset.y
        switch panGestureRecognizer.state {
        case .began:
            startYOffset = yOffset
        case .changed:
            delegate?.tabViewControllerDidScroll(yOffsetChange: startYOffset - yOffset)
        case .failed, .ended, .cancelled:
            delegate?.tabViewControllerDidEndDragging()
        default:
            break
        }
    }
}

extension Cell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      if navigationAction.navigationType == .linkActivated {
        // handle redirects
        guard let url = navigationAction.request.url else { return }
        webView.load(URLRequest(url: url))
      }
      decisionHandler(.allow)
    }
}

