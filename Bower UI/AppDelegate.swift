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
	
	@IBOutlet weak var packagesTableView: NSTableView!
	@IBOutlet weak var packagesSearchField: NSSearchField!
	
	let windowBackgroundColor = NSColor(calibratedRed:0.99, green:0.8, blue:0.25, alpha:1.0)
	let projectsTableTextColor = NSColor(calibratedRed: 0.33, green: 0.22, blue: 0.16, alpha: 1.0)
	let selectedBackgroundColor = NSColor(calibratedRed: 0.33, green: 0.22, blue: 0.16, alpha: 1.0)
	
	var projectPaths : NSMutableOrderedSet {
		get {
			var returnValue: [NSString]? = NSUserDefaults.standardUserDefaults().arrayForKey("projectPaths") as? [NSString]
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
	
	var isSearchingForPackages = false

	
	/**************************************************************************
	// MARK - AppDelegate functions
	**************************************************************************/
	
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
		
        self.window.titlebarAppearsTransparent = true
        self.window.titleVisibility = .Hidden
        
		projectView.delegate = self
		projectQuery.delegate = self
		
		for path in projectPaths.array as [String]
		{
			let project = readProject(path)
			if project != nil
			{
				projects += [project!]
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
	
	/**************************************************************************
	// TODO: Project handling mark
	// MARK - Project handling
	**************************************************************************/

	@IBAction func addProject(sender: AnyObject?) {
		
		var newProject = Project()
		
		let panel = NSOpenPanel()
		panel.canChooseFiles = false
		panel.canChooseDirectories = true
		panel.showsToolbarButton = true
		
		
		if panel.runModal() == NSOKButton
		{
			var selectedFolder: String? = panel.URL!.path
			if let folderPath = selectedFolder
			{
				var newProject = readProject(folderPath)
				
				if newProject == nil
				{
					newProject = Project()
					
					let pipe = NSPipe()
					let inPipe = NSPipe()
					
					let task = NSTask()
					task.launchPath = "/usr/local/bin/node"
					task.currentDirectoryPath = folderPath
					task.arguments = ["/usr/local/bin/bower", "--config.interactive", "init"]
					task.standardOutput = pipe
					task.standardInput = inPipe
					
					let inString: NSString = "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\nY\n\n\n\n\n"
					let inData = inString.dataUsingEncoding(NSUTF8StringEncoding)!
					inPipe.fileHandleForWriting.writeData(inData)
					
					pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
					
					NSNotificationCenter.defaultCenter().addObserverForName(
						NSFileHandleDataAvailableNotification,
						object: pipe.fileHandleForReading,
						queue: nil,
						usingBlock:
						{ (note: NSNotification!) -> Void in
							sleep(1)
							var outData: NSData = pipe.fileHandleForReading.availableData
							var outString = NSString(data: outData, encoding: NSUTF8StringEncoding)!
							
							inPipe.fileHandleForWriting.writeData(inData)
							inPipe.fileHandleForWriting.closeFile()
						})
					
					task.launch()
					task.waitUntilExit()

					newProject = readProject(folderPath)
				}

				projects += [newProject!]
				
				projectsTableView.reloadData()
				//projectPaths.addObject(NSString(string: newProject.path))
				let set: NSMutableOrderedSet = projectPaths
				set.addObject(NSString(string: newProject!.path))
				NSUserDefaults.standardUserDefaults().setObject(set.array, forKey: "projectPaths")
				NSUserDefaults.standardUserDefaults().synchronize()
			}
		}
	}
	
	@IBAction func deleteProject(sender: AnyObject?) {
		//TODO: ask if bower.json should be removed, too
		
		let set: NSMutableOrderedSet = projectPaths
		set.removeObjectAtIndex(projectsTableView.selectedRow)
		NSUserDefaults.standardUserDefaults().setObject(set.array, forKey: "projectPaths")
		NSUserDefaults.standardUserDefaults().synchronize()
		
		projects.removeAtIndex(projectsTableView.selectedRow)
		
		projectsTableView.removeRowsAtIndexes(NSIndexSet(index: projectsTableView.selectedRow), withAnimation: NSTableViewAnimationOptions.EffectFade)
		projectsTableView.reloadData()
	}
	
	@IBAction func refreshProject(sender: AnyObject?)
	{
		if currentProject != nil
		{
			let index = projectsTableView.selectedRow
			projects[index] = readProject(currentProject!.path)!
			currentProject = projects[index]
			projectView.project = currentProject
			projectsTableView.reloadData()
			projectsTableView.selectRowIndexes(NSIndexSet(index: index), byExtendingSelection: false)
		}
	}
	
	@IBAction func revertProject(sender: AnyObject?)
	{
		if currentProject != nil
		{
			let index = projectsTableView.selectedRow
			projects[index] = readProject(currentProject!.path)!
			currentProject = projects[index]
			projectView.project = currentProject
			projectsTableView.reloadData()
			projectsTableView.selectRowIndexes(NSIndexSet(index: index), byExtendingSelection: false)
		}
	}
	
	@IBAction func saveProject(sender: AnyObject?)
	{
		if currentProject != nil
		{
			writeProject(currentProject!, toPath: currentProject!.path)
		}
	}
	
	func updateProject()
	{
		var selectedRow = projectsTableView.selectedRow
		projectsTableView.reloadData()
		projectsTableView.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
	}
	
	func readProject(fromPath: String) -> Project?
	{
		let content = NSData(contentsOfFile: fromPath.stringByAppendingPathComponent("bower.json"))
		
		if let data = content
		{
			var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
			
			let project = Project()
			project.path = fromPath
			project.name = jsonResult.valueForKey("name") as String
			project.authors = jsonResult.valueForKey("authors") as [String]
			project.version = jsonResult.valueForKey("version") as String
			project.license = jsonResult.valueForKey("license") as String
			if jsonResult.valueForKey("keywords") != nil
				{ project.keywords = jsonResult.valueForKey("keywords") as [String] }
			if jsonResult.valueForKey("description") != nil
				{ project.description = jsonResult.valueForKey("description") as String }
			
			return project
		}
		
		return nil
		
	}
	
	func writeProject(project: Project, toPath: String) -> Bool
	{
		let content = NSData(contentsOfFile: toPath.stringByAppendingPathComponent("bower.json"))
		
		if let data = content
		{
			var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as NSDictionary
			
			jsonResult.setValue(project.name, forKey: "name")
			if project.authors.count != 0
				{ jsonResult.setValue(project.authors, forKey: "authors") }
			jsonResult.setValue(project.version, forKey: "version")
			jsonResult.setValue(project.description, forKey: "description")
			jsonResult.setValue(project.license, forKey: "license")
			if project.keywords.count != 0
				{ jsonResult.setValue(project.keywords, forKey: "keywords") }
			
			let outStream = NSOutputStream(toFileAtPath: toPath.stringByAppendingPathComponent("bower.json"), append: false)
			outStream?.open()
			
			let error = NSErrorPointer()
			
			if outStream != nil
			{
				NSJSONSerialization.writeJSONObject(jsonResult, toStream: outStream!, options: NSJSONWritingOptions.PrettyPrinted, error: error)
				
				//println(error)
				return true
			}
			
			outStream?.close()
			
		}
		
		return false
	}
	
	/**************************************************************************
	// TODO: Package handling mark
	// MARK - Package handling
	**************************************************************************/
	
	@IBAction func addPackage(sender: AnyObject?) {
		dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
			let pipe = NSPipe()
			
			let newPackage = (self.packagesTableView.viewAtColumn(0, row: self.packagesTableView.selectedRow, makeIfNecessary: true) as PackageTableCellView).nameLabel.stringValue
			
			let task = NSTask()
			task.launchPath = "/usr/local/bin/node"
			task.currentDirectoryPath = (self.currentProject != nil) ? self.currentProject!.path : ""
			task.arguments = ["/usr/local/bin/bower", "install", newPackage]
			task.standardOutput = pipe
			
			println("install \(newPackage)")
			
			/*var outString: String = ""
			pipe.fileHandleForReading.readInBackgroundAndNotify()
			
			NSNotificationCenter.defaultCenter().addObserverForName(
				NSFileHandleReadCompletionNotification,
				object: pipe.fileHandleForReading,
				queue: nil,
				usingBlock:
				{ (note: NSNotification!) -> Void in
					var outData: NSData = pipe.fileHandleForReading.availableData
					outString += NSString(data: outData, encoding: NSUTF8StringEncoding)!
					print(outString)
					//if outString != ""
					//{
					pipe.fileHandleForReading.readInBackgroundAndNotify()
					//}
			})*/
			
			task.launch()
			task.waitUntilExit()
		}
	}
	
	@IBAction func removePackage(sender: AnyObject?) {
		dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
			let pipe = NSPipe()
			
			let oldPackage = (self.packagesTableView.viewAtColumn(0, row: self.packagesTableView.selectedRow, makeIfNecessary: true) as PackageTableCellView).nameLabel.stringValue
			
			let task = NSTask()
			task.launchPath = "/usr/local/bin/node"
			task.currentDirectoryPath = (self.currentProject != nil) ? self.currentProject!.path : ""
			task.arguments = ["/usr/local/bin/bower", "uninstall", oldPackage ]
			/*task.standardOutput = pipe
			
			var outString: String = ""
			pipe.fileHandleForReading.readInBackgroundAndNotify()
			
			NSNotificationCenter.defaultCenter().addObserverForName(
				NSFileHandleReadCompletionNotification,
				object: pipe.fileHandleForReading,
				queue: nil,
				usingBlock:
				{ (note: NSNotification!) -> Void in
					var outData: NSData = pipe.fileHandleForReading.availableData
					outString += NSString(data: outData, encoding: NSUTF8StringEncoding)!
					print(outString)
					if outString != ""
					{
						pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
					}
			})*/
			
			task.launch()
			task.waitUntilExit()
			
			self.listPackages()
		}
	}
	
	@IBAction func updatePackage(sender: AnyObject?) {
		
	}
	
	func listPackages() {
		isSearchingForPackages = false
		
        //TODO: check if node and bower are installed
		dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
			let pipe = NSPipe()
			
			let task = NSTask()
			task.launchPath = "/usr/local/bin/node"
			task.currentDirectoryPath = (self.currentProject != nil) ? self.currentProject!.path : ""
			task.arguments = ["/usr/local/bin/bower", "list"]
			task.standardOutput = pipe
			
			var outString: String = ""
			pipe.fileHandleForReading.readInBackgroundAndNotify()
			
			NSNotificationCenter.defaultCenter().addObserverForName(
				NSFileHandleReadCompletionNotification,
				object: pipe.fileHandleForReading,
				queue: nil,
				usingBlock:
				{ (note: NSNotification!) -> Void in
					var outData: NSData = pipe.fileHandleForReading.availableData
					outString += NSString(data: outData, encoding: NSUTF8StringEncoding)!
					print(outString)
					if outString != ""
					{
						pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
					}
			})
			
			task.launch()
			task.waitUntilExit()
			
			var error: NSError = NSError()
			var regex: NSRegularExpression = NSRegularExpression(pattern: "\\s[\\x00-\\x7F^#]*#", options: NSRegularExpressionOptions.CaseInsensitive, error: nil)!
			
			self.packages.removeAll(keepCapacity: true)
			var rows = outString.componentsSeparatedByString("\n")
			
			println(rows)
			
			for row in rows
			{
				let rowLength = (NSString(string: row).length)
				var checkingResult = regex.matchesInString(row, options: nil, range: NSMakeRange(0, rowLength))
				
				if checkingResult.count > 0
				{
					let range = (checkingResult[0] as NSTextCheckingResult).range
					let strippedString = NSString(string: row).substringFromIndex(range.location)
					
					println(strippedString)
					
					var tokens = strippedString.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: "# "))
					let newPackage = Package()
					newPackage.name = tokens[1]
					newPackage.version = tokens[2]
					if tokens[3] != "extraneous"
					{
						newPackage.updateAvailable = true
					}
					self.packages += [newPackage]
				}
			}
			
			println("reload packages")
			
			dispatch_async(dispatch_get_main_queue()) {
				self.packagesTableView.reloadData()
			}
		}
	}
	
	@IBAction func searchPackages(sender: AnyObject?)
	{
		isSearchingForPackages = true
		
		dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
			let pipe = NSPipe()
			
			let task = NSTask()
			task.launchPath = "/usr/local/bin/node"
			task.currentDirectoryPath = (self.currentProject != nil) ? self.currentProject!.path : ""
			task.arguments = ["/usr/local/bin/bower", "search", self.packagesSearchField.stringValue]
			task.standardOutput = pipe
			
			println("search for \(self.packagesSearchField.stringValue)")
			
			if self.packagesSearchField.stringValue == ""
			{
				self.listPackages()
				return
			}
			
			var outString: String = ""
			pipe.fileHandleForReading.readInBackgroundAndNotify()
			
			NSNotificationCenter.defaultCenter().addObserverForName(
				NSFileHandleReadCompletionNotification,
				object: pipe.fileHandleForReading,
				queue: nil,
				usingBlock:
				{ (note: NSNotification!) -> Void in
					var outData: NSData = pipe.fileHandleForReading.availableData
					outString += NSString(data: outData, encoding: NSUTF8StringEncoding)!
					print(outString)
					//if outString != ""
					//{
						pipe.fileHandleForReading.readInBackgroundAndNotify()
					//}
			})
			
			task.launch()
			task.waitUntilExit()
			
			
			self.packages.removeAll(keepCapacity: true)
			var rows = outString.componentsSeparatedByString("\n")
			if rows[0] == "No results." || rows.count < 2
			{
				//TODO: somehow show there was no result
				self.packages.removeAll(keepCapacity: true)
			}
			else
			{
				rows.removeAtIndex(0)
				if rows.count > 1
				{
					rows.removeLast()
					
					for row in rows
					{
						var tokens = row.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " "))
						tokens.removeLast()
						let newPackage = Package()
						newPackage.name = tokens.last!
						newPackage.version = ""
						self.packages += [newPackage]
					}
				}
			}
			println("reload packages")
			
			dispatch_async(dispatch_get_main_queue()) {
				self.packagesTableView.reloadData()
			}
		}
	}
	
	/**************************************************************************
	// TODO: UITableViewSource and Delegate mark
	// MARK - UITableViewSource and Delegate
	**************************************************************************/
	
	func numberOfRowsInTableView(tableView: NSTableView!) -> Int {
		if tableView == projectsTableView
		{
			return projects.count
		}
		else if tableView == packagesTableView
		{
			return packages.count
		}
		
		return 0
	}
	
	func tableView(tableView: NSTableView!, viewForTableColumn tableColumn: NSTableColumn!, row: Int) -> NSView! {
		if tableView == projectsTableView
		{
			var result: ProjectTableCellView = tableView.makeViewWithIdentifier("projectTableView", owner: self) as ProjectTableCellView

			result.label?.stringValue = projects[row].name
			
			if tableView.selectedRow == row
			{
				result.label?.textColor = NSColor.alternateSelectedControlTextColor()
			}
			
			return result
		}
		else
		{
			if tableColumn.identifier == "infoColumn"
			{
				var result: PackageTableCellView = tableView.makeViewWithIdentifier("packageTableView", owner: self) as PackageTableCellView
				result.nameLabel?.stringValue = packages[row].name
				result.versionLabel?.stringValue = packages[row].version
				result.descriptionLabel?.stringValue = packages[row].description
				
				if isSearchingForPackages
				{
					result.versionLabel.hidden = true
					result.installButton.hidden = false
				}
				else
				{
					result.versionLabel.hidden = false
					result.installButton.hidden = true
				}
				
				return result
			}
			else if tableColumn.identifier == "homeColumn"
			{
				if isSearchingForPackages
				{
					return nil
				}
				var result: NSTableCellView = tableView.makeViewWithIdentifier("homeTableView", owner: self) as NSTableCellView
				return result
			}
			else// if tableColumn.identifier == "updateColumn"
			{
				if isSearchingForPackages
				{
					return nil
				}
				var result: NSTableCellView = tableView.makeViewWithIdentifier("updateTableView", owner: self) as NSTableCellView

				return result
			}
		}
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
			
			for var i = 0; i < packagesTableView.numberOfRows; i++
			{
				(packagesTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as PackageTableCellView).nameLabel.textColor = projectsTableTextColor
			}
			
			if(projectsTableView.selectedRow != -1)
			{
				projectView.project = projects[projectsTableView.selectedRow]
				
				(projectsTableView.viewAtColumn(0, row: projectsTableView.selectedRow, makeIfNecessary: true) as ProjectTableCellView).label.textColor = NSColor.whiteColor()
				currentProject = projectView.project
				listPackages()
			}
			else
			{
				currentProject = nil
			}
		}
		
		if notification.object as NSTableView == packagesTableView
		{
			for var i = 0; i < packagesTableView.numberOfRows; i++
			{
				(packagesTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as PackageTableCellView).nameLabel.textColor = projectsTableTextColor
			}
			
			if(packagesTableView.selectedRow != -1)
			{
				(packagesTableView.viewAtColumn(0, row: packagesTableView.selectedRow, makeIfNecessary: true) as PackageTableCellView).nameLabel.textColor = NSColor.whiteColor()
			}
		}
	}
	
	func tableViewSelectionIsChanging(notification: NSNotification!) {
		
		if notification.object as NSTableView == projectsTableView
		{
			for var i = 0; i < projectsTableView.numberOfRows; i++
			{
				(projectsTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as ProjectTableCellView).label.textColor = projectsTableTextColor
			}
			
			for var i = 0; i < packagesTableView.numberOfRows; i++
			{
				(packagesTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as PackageTableCellView).nameLabel.textColor = projectsTableTextColor
			}
			
			if(projectsTableView.selectedRow != -1)
			{
				projectView.project = projects[projectsTableView.selectedRow]
				
				(projectsTableView.viewAtColumn(0, row: projectsTableView.selectedRow, makeIfNecessary: true) as ProjectTableCellView).label.textColor = NSColor.whiteColor()
				currentProject = projectView.project
				listPackages()
			}
			else
			{
				currentProject = nil
			}
		}
		
		if notification.object as NSTableView == packagesTableView
		{
			for var i = 0; i < packagesTableView.numberOfRows; i++
			{
				(packagesTableView.viewAtColumn(0, row: i, makeIfNecessary: true) as PackageTableCellView).nameLabel.textColor = projectsTableTextColor
			}
			
			if(packagesTableView.selectedRow != -1)
			{	
				(packagesTableView.viewAtColumn(0, row: packagesTableView.selectedRow, makeIfNecessary: true) as PackageTableCellView).nameLabel.textColor = NSColor.whiteColor()
			}
		}
	}
}


