//
//  ArrayExtension.swift
//  Bower
//
//  Created by Enie Weiß on 22.09.14.
//  Copyright (c) 2014 Enie. All rights reserved.
//

extension Array {
	func combine(separator: String) -> String{
		var str : String = ""
		for (idx, item) in enumerate(self) {
			str += "\(item)"
			if idx < self.count-1 {
				str += separator
			}
		}
		return str
	}
}