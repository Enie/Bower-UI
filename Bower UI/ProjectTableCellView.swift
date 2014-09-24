//
//  ProjectTableCellView.swift
//  Bower
//
//  Created by Enie Weiß on 20.09.14.
//  Copyright (c) 2014 Enie. All rights reserved.
//

import Cocoa

class ProjectTableCellView: NSTableCellView {
	@IBOutlet var label: NSTextField!
	
}

class ProjectTableRowView: NSTableRowView {
	let selectedBackgroundColor = NSColor(calibratedRed: 0.33, green: 0.22, blue: 0.16, alpha: 1.0)
	
	override func drawSelectionInRect(dirtyRect: NSRect) {
		
		selectedBackgroundColor.set()
		NSRectFill(dirtyRect)
	}
}