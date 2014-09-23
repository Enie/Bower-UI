//
//  AppDelegate.swift
//  Bower
//
//  Created by Enie Weiß on 07.09.14.
//  Copyright (c) 2014 Enie. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSMetadataQueryDelegate {
                            
	@IBOutlet weak var window: NSWindow!

	@IBOutlet weak var projectsTableView: NSTableView!
	@IBOutlet weak var projectView: ProjectView!
	
	let windowBackgroundColor = NSColor(calibratedRed:0.99, green:0.8, blue:0.25, alpha:1.0)
	let projectsTableTextColor = NSColor(calibratedRed: 0.33, green: 0.22, blue: 0.16, alpha: 1.0)
	let selectedBackgroundColor = NSColor(calibratedRed: 0.33, green: 0.22, blue: 0.16, alpha: 1.0)
	
	
	var projectPaths : NSMutableOrderedSet {
		get {
			var returnValue: [NSString]? = NSUserDefaults.standardUserDefaults().objectForKey("projectPaths") as? [NSString]
			if returnValue == nil //Check for first run of app
			{
				return NSMutableOrderedSet() //Default value
			}
			return NSMutableOrderedSet(array: returnValue!)
		}
		set (newValue) {
			NSUserDefaults.standardUserDefaults().setObject(newValue.array, forKey: "projectPaths")
			NSUserDefaults.standardUserDefaults().synchronize()
		}
	}
	
	var currentProject: Project?
	var currentPackage: Package?
	
	
	var timer: NSTimer?
	var projectQuery: NSMetadataQuery = NSMetadataQuery()
	
	var projects: [Project] = []
	var packages: [Package] = []

	override init() {
		super.init()
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.addObserver(
			self,
			selector: "applicationWillFinishLaunching:",
			name:NSApplicationDidFinishLaunchingNotification,
			object: nil
		)
	}

	func applicationWillFinishLaunching(notification: NSNotification!) {
		
		//self.window.backgroundColor = windowBackgroundColor
		
		projectView.delegate = self
		projectQuery.delegate = self
		
		for path in projectPaths.array
		{
			let content = NSData(contentsOfFile: path.stringByAppendingPathComponent("bower.json"))
			
			if let data = content
			{
				var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
				
				let newProject = Project()
				newProject.path = path as String
				newProject.name = jsonResult.valueForKey("name") as String
				newProject.authors = jsonResult.valueForKey("authors") as [String]
				newProject.version = jsonResult.valueForKey("version") as String
				newProject.description = jsonResult.valueForKey("description") as String
				
				
				projects += [newProject]
				
			}
		}
		
		projectsTableView.reloadData()
	}
	
	func applicationDidFinishLaunching(aNotification: NSNotification?) {
		// Insert code here to initialize your application
		
	}

	func applicationWillTerminate(aNotification: NSNotification?) {
		// Insert code here to tear down your application
		
		let notificationCenter = NSNotificationCenter.defaultCenter()
		notificationCenter.removeObserver(self)
	}

	@IBAction func addProject(sender: AnyObject?) {
		
		var newProject = Project()
		
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.showsToolbarButton = true
		
		
		if panel.runModal() == NSOKButton
		{
			var selectedFolder: String? = panel.URL.path
			if let folderPath = selectedFolder
			{
				newProject.path = folderPath
				
				let content = NSData(contentsOfFile: folderPath.stringByAppendingPathComponent("bower.json"))
				
				if let data = content
				{
					var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
					
					println(jsonResult.valueForKey("name"))
					
					let newProject = Project()
					newProject.name = jsonResult.valueForKey("name") as String
					newProject.authors = jsonResult.valueForKey("authors") as [String]
					newProject.version = jsonResult.valueForKey("version") as String
					newProject.description = jsonResult.valueForKey("description") as String
				}
				else
				{
					newProject.name = "new Project"
					
					let task = NSTask()
					task.launchPath = folderPath
					task.arguments = ["say", "Hello"]
				}

				projects += [newProject]
				
				projectsTableView.reloadData()
				projectPaths.addObject(NSString(string: newProject.path))
			}
		}
	}
	
	@IBAction func addPackage(sender: AnyObject?) {
		
	}
	
	func updateProject()
	{
		var selectedRow = projectsTableView.selectedRow
		projectsTableView.reloadData()
		projectsTableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
	}
	
	func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
		if tableView == projectsTableView
		{
			return projects.count
		}
		
		return 0
	}
	
	func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
		
		var result: ProjectTableCellView = tableView.makeViewWithIdentifier("projectTableView", owner: self) as ProjectTableCellView

		result.label?.stringValue = projects[row].name
		
		if tableView.selectedRow == row
		{
			result.label?.textColor = NSColor.alternateSelectedControlTextColor()
		}
		
		return result
	}
	
	func tableView(tableView: NSTableView!, rowViewForRow row: Int) -> NSTableRowView! {
		return ProjectTableRowView()
	}
	
	func tableViewSelectionDidChange(notification: NSNotification!) {
		
		if notification.object as NSTableView == projectsTableView
		{
			for var i = 0; i < projectsTableView.numberOfRows; i++
			{
				(projectsTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as ProjectTableCellView).label.textColor = projectsTableTextColor
			}
			
			if(projectsTableView.selectedRow != -1)
			{
				projectView.project = projects[projectsTableView.selectedRow]
				
				(projectsTableView.viewAtColumn(0, row: projectsTableView.selectedRow, makeIfNecessary: true) as ProjectTableCellView).label.textColor = NSColor.whiteColor()
			}
		}
	}
	
	func tableViewSelectionIsChanging(notification: NSNotification!) {
		
		for var i = 0; i < projectsTableView.numberOfRows; i++
		{
			(projectsTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as ProjectTableCellView).label.textColor = projectsTableTextColor
		}
		
		if notification.object as NSTableView == projectsTableView
		{
			if(projectsTableView.selectedRow != -1)
			{
				projectView.project = projects[projectsTableView.selectedRow]
				
				(projectsTableView.viewAtColumn(0, row: projectsTableView.selectedRow, makeIfNecessary: true) as ProjectTableCellView).label.textColor = NSColor.whiteColor()
			}
		}
	}
}
