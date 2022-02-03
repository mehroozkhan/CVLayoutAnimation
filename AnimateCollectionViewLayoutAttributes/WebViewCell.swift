//
//  WebViewCell.swift
//  AnimateCollectionViewLayoutAttributes
//
//  Created by Mehrooz Khan on 02/02/2022.
//

import UIKit
import WebKit

class CellData {
    var isActive = false
    var enteredURL: String?
    var pageTitle = "Page Title"
    var image: UIImage?
    
    init(isActive: Bool) {
        self.isActive = isActive
    }
}

protocol BrowserTabViewControllerDelegate: AnyObject {
    func tabViewController(_ cvCell: WebViewCell, didStartLoadingURL url: URL)
    func tabViewController(_ cvCell: WebViewCell, didChangeLoadingProgressTo progress: Float)
    func tabViewControllerDidScroll(yOffsetChange: CGFloat)
    func tabViewControllerDidEndDragging()
}

class WebViewCell: UICollectionViewCell {
    
    var topViewHeightConstraint: NSLayoutConstraint!
        
    var cellDelegate: CellDelegate?
    weak var delegate: BrowserTabViewControllerDelegate?
    
    private var startYOffset = CGFloat(0)
    
    
    var indexItem: Int?
    var data: CellData?
    
    let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis  = NSLayoutConstraint.Axis.vertical
        sv.alignment = UIStackView.Alignment.fill
        sv.distribution = UIStackView.Distribution.fill
        sv.translatesAutoresizingMaskIntoConstraints = false;
        return sv
    }()
    
    let topView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let webView: WKWebView = {
        let wk = WKWebView()
        wk.translatesAutoresizingMaskIntoConstraints = false
        return wk
    }()
    
    let labelView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    let bottomLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.white
        label.text = "Page title"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let imageView: UIImageView = {
        let image = UIImageView()
        image.backgroundColor = UIColor.red
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    let closeButton: UIButton =  {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = UIColor.lightGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addViews()
        imageView.alpha = 1
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 15
        contentView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 15
        imageView.backgroundColor = .white
        imageView.layer.masksToBounds = true
        imageView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        addShadow()
    }
    
    func addViews(){
        backgroundColor = UIColor.clear
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.leading.trailing.top.bottom.equalToSuperview()
        }
        
        stackView.addArrangedSubview(topView)
        topViewHeightConstraint = topView.heightAnchor.constraint(equalToConstant: 100)
        topViewHeightConstraint.isActive = true
        
        stackView.addArrangedSubview(webView)
        setupWebView()
        
        stackView.addArrangedSubview(labelView)
        
        labelView.addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.height.equalTo(20)
            $0.leading.equalToSuperview().offset(20)
            $0.trailing.equalToSuperview().offset(-20)
        }
        
        contentView.addSubview(imageView)
        imageView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(webView)
            $0.top.equalTo(webView).offset(0)
        }
        
        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints{
            $0.trailing.equalTo(webView).offset(-10)
            $0.top.equalTo(webView).offset(10)
        }
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        layer.zPosition = CGFloat(layoutAttributes.zIndex)
    }
    
    @objc func closeTapped(_ sender: UIButton) {
        cellDelegate?.closeTapped(indexItem: self.indexItem ?? 0)
    }
    
    func setCellContents(_ data: CellData, isGridView: Bool, isShrinking: Bool) {
        self.data = data
        guard data.isActive else {
            self.contentView.alpha = 0
            return
        }
        self.contentView.alpha = 1
        closeButton.isHidden = !isGridView
        self.bottomLabel.text = data.pageTitle
        if isGridView {
            imageView.layer.cornerRadius = 15
            self.labelView.isHidden = false
            self.topViewHeightConstraint.constant = 0
        } else {
            imageView.layer.cornerRadius = 0
            self.labelView.isHidden = true
            self.topViewHeightConstraint.constant = UIView.aboveSafeArea
        }
        if data.enteredURL == nil || isShrinking || isGridView {
            setSnapShot()
        }
        else {
            self.webView.alpha = 1
            self.imageView.alpha = 0
        }
    }

    func setSnapShot() {
        self.imageView.image = #imageLiteral(resourceName: "safari-empty-tab-background.jpg")
        guard data?.enteredURL != nil else {
            self.imageView.contentMode = .scaleAspectFit
            self.webView.alpha = 0
            self.imageView.alpha = 1
            return
        }
        self.imageView.contentMode = .scaleAspectFill
        if let image = data?.image {
            self.imageView.image = image
        }
        else {
            let image = getSnapshot()
            self.imageView.image = image
            data?.image = image
        }
        self.webView.alpha = 0
        self.imageView.alpha = 1
    }
    
    func hideSnapShot() {
        if data?.enteredURL == nil {
            return
        }
        self.webView.alpha = 1
        self.imageView.alpha = 0
    }
    
    func prepareForGridView() {
        topViewHeightConstraint.constant = 0
        imageView.layer.cornerRadius = 15
        UIView.animate(withDuration: 0.2) {
            self.labelView.isHidden =  false
            self.layoutIfNeeded()
        }
    }
    
    func prepareForFullView() {
        closeButton.isHidden = true
        labelView.isHidden =  true
        topViewHeightConstraint.constant = UIView.aboveSafeArea
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
    
    func loadWebsite(from url: URL) {
        webView.load(URLRequest(url: url))
        data?.enteredURL = url.absoluteString
        self.imageView.alpha = 0
        self.webView.alpha = 1
    }
    
    func setupWebView() {
        webView.scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan(_:)))
        webView.navigationDelegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.title), options: .new, context: nil)
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
            case #keyPath(WKWebView.title):
                data?.pageTitle = webView.title ?? "Page title"
                self.bottomLabel.text = data?.pageTitle
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
    
    func getSnapshot() -> UIImage {
            //Create the UIImage
        UIGraphicsBeginImageContext(webView.frame.size)
        webView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    func addShadow() {
        layer.cornerRadius = 15.0
        layer.borderWidth = 0.0
        layer.shadowColor = UIColor.black.withAlphaComponent(0.5).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowRadius = 5.0
        layer.shadowOpacity = 1
        layer.masksToBounds = false
    }
}

extension WebViewCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
                // handle redirects
            guard let url = navigationAction.request.url else { return }
            webView.load(URLRequest(url: url))
        }
        decisionHandler(.allow)
    }
}
