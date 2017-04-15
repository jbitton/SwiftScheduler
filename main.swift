//
//  main.swift
//  OSScheduler
//
//  Created by sphota on 10/2/16.
//  Copyright © 2016 Intellex. All rights reserved.
//

import Foundation

// runs FCFS
print("Starting to run FCFS.....\n\n")
let fcfs = FCFS("test.txt")
//runs SJF
print("Starting to run SJF.....\n\n")
let sjf = SJF("test.txt")
// runs MLFQ
print("Starting to run MLFQ.....\n\n")
let mlfq = MLFQ("test.txt", timeQuantum1: 6, timeQuantum2: 11)
