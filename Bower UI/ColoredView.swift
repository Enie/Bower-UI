//
//  ColoredWindow.swift
//  Bower UI
//
//  Created by Enie Weiß on 28/03/15.
//  Copyright (c) 2015 Enie. All rights reserved.
//

import Cocoa

@IBDesignable
class ColoredView: NSView {

    @IBInspectable var backgroundColor: NSColor
    
    convenience init(color: NSColor)
    {
        self.init()
        backgroundColor = color
    }
    
    override init(frame: NSRect)
    {
        backgroundColor = NSColor(calibratedRed:0.99, green:0.8, blue:0.25, alpha:1.0)
        super.init(frame:frame)
    }
        
    required init?(coder: NSCoder) {
        //fatalError("init(coder:) has not been implemented")
        
        backgroundColor = NSColor(calibratedRed:0.99, green:0.8, blue:0.25, alpha:1.0)
        
        super.init(coder: coder)
    }
    
    override func drawRect(dirtyRect: NSRect) {
        backgroundColor.set()
        NSRectFill(dirtyRect)
    }
}