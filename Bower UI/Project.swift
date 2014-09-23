//
//  Project.swift
//  Bower UI
//
//  Created by Enie Weiß on 20.09.14.
//  Copyright (c) 2014 Enie. All rights reserved.
//

import Foundation

class Project {
	var name: String = "NO NAME"
	var path: String = "~/"
	
	var version: String = "0.0.0"
	var description: String = ""
	var mainFile: String = ""
	var keywords: [String] = []
	var authors: [String] = []
	var license: String = ""
	var homepage: String = ""
	
	var packages: [Package] = []
	
	init() {
		
	}
}