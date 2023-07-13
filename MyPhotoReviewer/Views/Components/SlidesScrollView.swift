//
//  SlidesScrollView.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 13/07/23.
//

import SwiftUI

/**
 Delegate for SlidesScrollView.
 It delegates back status update to the host view after user interations.
 */
protocol SlidesScrollViewDelegate: Any {
    func didSlidePage(index: Int, position: CGFloat)
    func didChangeSlidePosition(index: Int, position: CGFloat)
}

/**
 SlidesScrollView presents a horizontally scrollable page view where users could
 swipe left/right through a given number of views
 */
struct SlidesScrollView<Content: View>: View {

    // MARK: Public properties
    
    let pageCount: Int
    let isLeftSlideEnabled: Bool
    let isRightSlideEnabled: Bool
    @Binding var currentIndex: Int
    let delegate: SlidesScrollViewDelegate?
    let content: Content

    // MARK: Private properties
    
    @GestureState private var translation: CGFloat = 0

    // MARK: Initializer
    
    init(
        pageCount: Int,
        isLeftSlideEnabled: Bool,
        isRightSlideEnabled: Bool,
        currentIndex: Binding<Int>,
        delegate: SlidesScrollViewDelegate?,
        @ViewBuilder content: () -> Content) {

        self.pageCount = pageCount
        self.isLeftSlideEnabled = isLeftSlideEnabled
        self.isRightSlideEnabled = isRightSlideEnabled
        self._currentIndex = currentIndex
        self.delegate = delegate
        self.content = content()
    }

    // MARK: User interface
    
    var body: some View {
        GeometryReader { geometry in
            LazyHStack(spacing: 0) {
                self.content.frame(width: geometry.size.width)
            }
            .frame(width: geometry.size.width, alignment: .leading)
            .offset(x: -CGFloat(self.currentIndex) * geometry.size.width)
            .offset(x: self.translation)
            .onChange(of: self.currentIndex) { index in
                self.delegate?.didSlidePage(index: index, position: 0)
            }
            .animation(.easeIn(duration: 0.2), value: currentIndex)
            .animation(.easeIn(duration: 0.2), value: translation)
            .gesture(
                DragGesture()
                .updating(self.$translation) { value, state, _ in
                    if self.isLeftSlideEnabled && value.translation.width > 0 {
                        state = value.translation.width
                        self.delegate?.didChangeSlidePosition(
                            index: self.currentIndex,
                            position: value.translation.width
                        )
                    } else if self.isRightSlideEnabled && value.translation.width < 0 {
                        state = value.translation.width
                        self.delegate?.didChangeSlidePosition(
                            index: self.currentIndex,
                            position: value.translation.width
                        )
                    }
                }
                .onEnded { value in
                    if self.isLeftSlideEnabled && value.translation.width > 0 {
                        let offset = value.translation.width / geometry.size.width
                        let newIndex = (CGFloat(self.currentIndex) - offset).rounded()
                        self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
                        self.delegate?.didSlidePage(index: self.currentIndex, position: value.translation.width)
                    } else if self.isRightSlideEnabled && value.translation.width < 0 {
                        let offset = value.translation.width / geometry.size.width
                        let newIndex = (CGFloat(self.currentIndex) - offset).rounded()
                        self.currentIndex = min(max(Int(newIndex), 0), self.pageCount - 1)
                        self.delegate?.didSlidePage(index: self.currentIndex, position: value.translation.width)
                    }
                }
            )
        }
    }
}
