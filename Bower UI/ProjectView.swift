//
//  File.swift
//  Bower
//
//  Created by Enie Weiß on 20.09.14.
//  Copyright (c) 2014 Enie. All rights reserved.
//

import Cocoa

@IBDesignable
class ProjectView: NSView {
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var authorsTextField: NSTextField!
	@IBOutlet var descriptionTextField: NSTextField!
	@IBOutlet var versionTextField: NSTextField!
	
	var delegate: AppDelegate!
	var project: Project?{
		didSet {
			nameTextField.stringValue = self.project?.name
			authorsTextField.stringValue = self.project?.authors.combine(", ")
			descriptionTextField.stringValue = self.project?.description
			versionTextField.stringValue = self.project?.version
		}
	}
	
	override func drawRect(dirtyRect: NSRect) {
		NSColor.whiteColor().set()
		NSRectFill(dirtyRect)
	}
	
	@IBAction func editTextField(sender: NSTextField)
	{
		if sender == nameTextField
		{
			project?.name = nameTextField.stringValue
		}
		else if sender == authorsTextField
		{
			project?.authors = authorsTextField.stringValue.componentsSeparatedByString(",")
		}
		else if sender == descriptionTextField
		{
			project?.description = descriptionTextField.stringValue
		}
		else if sender == versionTextField
		{
			project?.version = versionTextField.stringValue
		}
		
		delegate.updateProject()
	}
}