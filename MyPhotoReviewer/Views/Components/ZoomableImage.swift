//
//  ZoomableImage.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 08/12/23.
//

import SwiftUI
import PDFKit

struct ZoomableImage: UIViewRepresentable {
    
    // used to set the image that will be displayed in the PDFView
    private(set) var image: UIImage
    
    // sets the background color of the PDFView
    private(set) var backgroundColor: Color
    
    // sets the minimum scale factor for zooming out of the image
    private(set) var minScaleFactor: CGFloat
    
    // sets the ideal scale factor for the image when it is first displayed in the PDFView
    // the initial zoom level of the image when it is first displayed
    private(set) var idealScaleFactor: CGFloat
    
    // sets the maximum scale factor for zooming in on the image
    private(set) var maxScaleFactor: CGFloat
    
    public init(
        image: UIImage,
        backgroundColor: Color,
        minScaleFactor: CGFloat,
        idealScaleFactor: CGFloat,
        maxScaleFactor: CGFloat
    ) {
        self.image = image
        self.backgroundColor = backgroundColor
        self.minScaleFactor = minScaleFactor
        self.idealScaleFactor = idealScaleFactor
        self.maxScaleFactor = maxScaleFactor
    }
    
    public func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        guard let page = PDFPage(image: image) else { return view }
        let document = PDFDocument()
        document.insert(page, at: 0)
        
        //view.backgroundColor = UIColor(cgColor: backgroundColor.cgColor!)
        
        view.autoScales = true
        view.document = document
        
        view.maxScaleFactor = maxScaleFactor
        view.minScaleFactor = minScaleFactor
        view.scaleFactor = idealScaleFactor
        return view
    }
    
    public func updateUIView(_ uiView: PDFView, context: Context) {}
}
