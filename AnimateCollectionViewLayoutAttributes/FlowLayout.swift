//
//  FlowLayout.swift
//  AnimateBetweenCollectionLayouts
//
//  Created by Zheng on 6/24/21.
//

import UIKit

enum LayoutType {
    case strip
    case list
}

/**
 Enum to hold the type of layout transition
 */
fileprivate enum LayoutTransition{
    case fromStripToList
    case fromListToStrip
}

class FlowLayout: UICollectionViewFlowLayout {
    
    let cellPadding : CGFloat = 15
    
    var selectedItem = 0
    var shrinkCell: CGFloat = 1
    var visibleItem = 0
    var animating: Bool = false
    var preparedOnce: Bool = false
    var layoutType: LayoutType
    var layoutAttributes = [UICollectionViewLayoutAttributes]() /// store the frame of each item
    var contentSize = CGSize.zero /// the scrollable content size of the collection view
    override var collectionViewContentSize: CGSize { return contentSize } /// pass scrollable content size back to the collection view
    
    /**
     Fix content offset jumping
     */
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint) -> CGPoint {
        guard animating else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        }

        switch(layoutType){
        case .list: return transformCurrentContentOffset(.fromStripToList)
        case .strip: return transformCurrentContentOffset(.fromListToStrip)
        }
    }
    
    /// pass attributes to the collection view flow layout
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributes[indexPath.item]
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        /// edge cells don't shrink, but the animation is perfect
         return layoutAttributes.filter { rect.intersects($0.frame) } /// try deleting this line
        
    }
    
    /// makes the edge cells slowly shrink as you scroll
    func shrinkingEdgeCellAttributes(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }

        var rectAttributes: [UICollectionViewLayoutAttributes] = []
        /// rect of the visible collection view cells
        let ogVisibleRect: CGRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        var visibleRect: CGRect
        
        if animating{
            if layoutType == .strip {
                visibleRect = transformVisibleRectToOppositeLayout(.fromListToStrip, ogVisibleRect)
            }
            else{
                visibleRect = transformVisibleRectToOppositeLayout(.fromStripToList, ogVisibleRect)
            }
            
            rectAttributes = layoutAttributes
        }
        else{
            visibleRect = ogVisibleRect
            rectAttributes = layoutAttributes.filter { rect.intersects($0.frame) }
        }

        let leadingCutoff: CGFloat = 50 /// once a cell reaches here, start shrinking it
        let trailingCutoff: CGFloat
        let paddingInsets: UIEdgeInsets /// apply shrinking even when cell has passed the screen's bounds

        let pointKeyPath: WritableKeyPath<CGPoint, CGFloat>
        
        if layoutType == .strip {
            trailingCutoff = CGFloat(collectionView.bounds.width - leadingCutoff)
            paddingInsets = UIEdgeInsets(top: 0, left: -50, bottom: 0, right: -50)
            pointKeyPath = \.x
        } else {
            trailingCutoff = CGFloat(collectionView.bounds.height - leadingCutoff)
            paddingInsets = UIEdgeInsets(top: -50, left: 0, bottom: -50, right: 0)
            pointKeyPath = \.y
        }
        
        // Reset transform
        for attributes in rectAttributes {
            attributes.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            attributes.alpha = 0
            attributes.zIndex = 0
        }
        
        var currentTopCount = 0
        for attributes in rectAttributes where visibleRect.inset(by: paddingInsets).contains(attributes.center) {
            /// center of each cell, converted to a point inside `visibleRect`
            
            let center = attributes.center[keyPath: pointKeyPath] - visibleRect.origin[keyPath: pointKeyPath]

            var offset: CGFloat?
            var translation = CGPoint.zero
            if center <= leadingCutoff {
                offset = leadingCutoff - center /// distance from the cutoff, 0 if exactly on cutoff
                translation[keyPath: pointKeyPath]  = pow((offset! / leadingCutoff), 1.5) * leadingCutoff
            } else if center >= trailingCutoff {
                offset = center - trailingCutoff
                translation[keyPath: pointKeyPath]  = -pow((offset! / leadingCutoff), 1.5) * leadingCutoff
            }

            if let offset = offset {
                let alpha = 1 - (pow(offset, 1.1) / 100)
                let scale = 1 - (pow(offset, 1.1) / 5000) /// gradually shrink the cell
                
                attributes.alpha = alpha
                attributes.zIndex = Int(alpha * 100) /// if alpha is 1, keep on the top
                attributes.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: translation.x, y: translation.y)

            } else {
                currentTopCount += 1
                attributes.alpha = 1
                attributes.zIndex = 100 + currentTopCount /// maintain order even when on top
            }
        }
        return rectAttributes
    }
    
    /// initialize with a LayoutType
    init(layoutType: LayoutType) {
        self.layoutType = layoutType
        super.init()
    }
    
    /// make the layout (strip vs list) here
    override func prepare() { /// configure the cells' frames
        super.prepare()
        guard let collectionView = collectionView else { return }
        
        // FIX redundant prepare calls
        guard !preparedOnce else { return }
        preparedOnce = true
        layoutAttributes = []
        
        //let screenWidth = UIScreen.main.bounds.width
        
        var offset: CGFloat = 0 /// origin for each cell
        let listWidth = (collectionView.frame.width - 45) / 2
        var cellSize = layoutType == .strip ? CGSize(width: collectionView.frame.width , height: collectionView.frame.height) :
        CGSize(width: listWidth , height: listWidth * 1.6)
        
        if layoutType == .strip, shrinkCell != 1 {
            cellSize = CGSize(width: cellSize.width * shrinkCell, height: cellSize.height * shrinkCell)
        }
        
        //let cellSize = layoutType == .strip ? CGSize(width: screenWidth , height: collectionView.frame.height) : CGSize(width: (screenWidth / 2) , height: collectionView.frame.height / 2.8)
        
        
        for itemIndex in 0..<collectionView.numberOfItems(inSection: 0) {
            let indexPath = IndexPath(item: itemIndex, section: 0)
            let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
            
            var origin: CGPoint
            var addedOffset: CGFloat
            
            if layoutType == .strip {
                
                origin = CGPoint(x: offset, y: (collectionView.frame.height - cellSize.height)/2)
                addedOffset = cellSize.width + cellPadding
                
                if shrinkCell != 1 {
                    let increaseWPadding = (collectionView.frame.width - cellSize.width) / 2
                    var x = ((collectionView.frame.size.width + cellPadding) * CGFloat(itemIndex)) + increaseWPadding
                    if itemIndex == visibleItem + 1 {
                        x = ((collectionView.frame.size.width + cellPadding) * CGFloat(itemIndex)) - increaseWPadding
                    }
                    else if itemIndex == visibleItem - 1 {
                        x = ((collectionView.frame.size.width + cellPadding) * CGFloat(itemIndex)) + (increaseWPadding * 3)

                    }
                    
                    origin = CGPoint(x: x , y: (collectionView.frame.height - cellSize.height)/4)
                    addedOffset = collectionView.frame.width + cellPadding
                }
                
            } else {
                let y = (cellSize.height + cellPadding) * CGFloat(Int(itemIndex/2)) + UIView.aboveSafeArea
                if itemIndex % 2 == 0 {
                    origin = CGPoint(x: cellPadding , y: y)
                    addedOffset = cellSize.height + cellPadding
                    
                } else {
                    origin = CGPoint(x: cellSize.width + 30, y: y)
                    addedOffset = 0
                }
                
            }
            
            attributes.frame = CGRect(origin: origin, size: cellSize)
            layoutAttributes.append(attributes)
            offset += addedOffset
            
        }
        
        self.contentSize = layoutType == .strip /// set the collection view's `collectionViewContentSize`
            ? CGSize(width: offset , height: cellSize.height) /// if strip, height is fixed
        : CGSize(width: collectionView.contentSize.width, height: offset) /// if list, width is fixed
        
        
    }
    
    
    
    /// boilerplate code
    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { return true }
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds) as! UICollectionViewFlowLayoutInvalidationContext
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
    
    func reset(){
        preparedOnce = false
    }
}

// MARK: Helper Methods

extension FlowLayout{
    
    
    private func transformVisibleRectToOppositeLayout(_ transition: LayoutTransition, _ source: CGRect) -> CGRect{
        let transformedContentOffset = transformCurrentContentOffset(transition)
        return CGRect(origin: transformedContentOffset, size: source.size)
    }
    
    /**
     Transforms this layouts content offset, to the other layout
     as specified in the layout transition parameter.
     */
    private func transformCurrentContentOffset(_ transition: LayoutTransition) -> CGPoint {
        
        //let stripItemWidth = UIScreen.main.bounds.width
        let listWidth = (collectionView!.frame.width - 45) / 2
        let stripItemWidth: CGFloat = collectionView!.frame.width
        let listItemHeight: CGFloat = listWidth * 1.6
        
        switch(transition){
        case .fromStripToList:
            let numberOfItems = collectionView!.contentOffset.x / stripItemWidth  // from strip
            var newPoint = CGPoint(x: 0, y: numberOfItems * CGFloat(listItemHeight)) // to list

            if (newPoint.y + collectionView!.frame.height) >= contentSize.height{
                newPoint = CGPoint(x: 0, y: contentSize.height - collectionView!.frame.height)
            }

            return newPoint

        case .fromListToStrip:
            //let numberOfItems = collectionView!.contentOffset.y / listItemHeight // from list
            var newPoint = CGPoint(x: CGFloat(selectedItem) * CGFloat(stripItemWidth +  cellPadding), y: 0) // to strip

            if (newPoint.x + collectionView!.frame.width) >= contentSize.width{
                newPoint = CGPoint(x: contentSize.width - collectionView!.frame.width, y: 0)
            }

            return newPoint
        }
    }
    
}
