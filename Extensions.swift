//
//  Extensions.swift
//  OSScheduler

import Foundation
 
// function necessary to use a string like an array of characters
extension String {
	subscript (i: Int) -> Character {
		return self[self.index(self.startIndex, offsetBy: i)]
	}
}
