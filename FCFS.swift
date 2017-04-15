//
//  FCFS.swift
//  OSScheduler

import Foundation

// class for the FCFS algorithm
final class FCFS {
	// private variables for this class
	private var fcfsQueue: ProcessQueue<CPUProcess>?
	private var fcfsProcesses: [CPUProcess]?
	private var currentTime: Int
	private var timeIdle: Int
	
	private init() {
		self.fcfsProcesses = [CPUProcess]()
		self.fcfsQueue = ProcessQueue<CPUProcess>()
		self.currentTime = 0
		self.timeIdle = 0
	}
	
	public convenience init(_ filename: String) {
		self.init()
		self.initializeProcesses(filename)
	}
	
	private func initializeProcesses(_ fileName: String) {
		do {
			var bursts = [[String]]()
			// read contents of the file
			let dstr = try String(contentsOfFile: fileName)
			// separate each by new line
			let burstData = dstr.components(separatedBy: .newlines)
			// separate strings by commas
			for s in burstData {
				let a = s.components(separatedBy: ",")
				bursts.append(a)
			}
			// traverse 2d array of bursts & io and separate them into different arrays
			for processArray in bursts {
				var bursts = [Int]()
				var ioTimes = [Int]()
				for i in 1..<processArray.count {
					if i % 2 == 0 {
						ioTimes.append(Int(processArray[i])!)
					} else {
						bursts.append(Int(processArray[i])!)
					}
				}
				// create a process and initialize with its default values
				var process: CPUProcess = CPUProcess(isDone: false,
				                                     firstTimeExecution: true,
				                                     id: processArray[0][1],
				                                     bursts: [Int](),
				                                     burstIndex: 0,
				                                     currentBurst: 0,
				                                     currentIO: 0,
				                                     ioTimes: [Int](),
				                                     ioIndex: 0,
				                                     response: nil,
				                                     priority: nil,
				                                     timeFinished: 0,
				                                     arrivalTime: 0)
				// set burst & ioTimes array to equal the array created
				process.bursts = bursts
				process.ioTimes = ioTimes
				// set current burst & io
				process.currentBurst = process.bursts[process.burstIndex]
				process.currentIO = process.ioTimes[process.ioIndex]
				// add process to array of processes
				self.fcfsProcesses?.append(process)
			}
		} catch _ {
			print("Error: File not found")
		}
		self.startProcesses()
	}

	
	private func startProcesses() {
		// add all processes to fcfs queue
		for p in self.fcfsProcesses! {
			self.fcfsQueue?.enqueue(p)
		}
		// clear fcfs array so it can be used for calculateTimes
		self.fcfsProcesses = [CPUProcess]()

		// call executeProcesses until there are no items left in our queue
		while !self.fcfsQueue!.isEmpty {
			self.executeProcesses()
		}
		// call function to determine response time, turnarount time, et cetera
		self.calculateTimes()
	}
	
	private func executeProcesses () {
		print("Current time: " + String(self.currentTime) + "\n")
		// dequeue first process in queue
		var currentProcess = (self.fcfsQueue?.dequeue())!
		// check for idle time
		if currentProcess.arrivalTime > self.currentTime {
			self.timeIdle += currentProcess.arrivalTime - self.currentTime
			self.currentTime += currentProcess.arrivalTime - self.currentTime
		}
		// set currentBurst
		currentProcess.currentBurst = currentProcess.bursts[currentProcess.burstIndex]
		// set response time
		if currentProcess.firstTimeExecution {
			currentProcess.response = self.currentTime
		}
		// set i/o time & current i/o if there is more i/o time available
		if currentProcess.ioIndex < currentProcess.ioTimes.count {
			currentProcess.currentIO = currentProcess.ioTimes[currentProcess.ioIndex]
			currentProcess.ioIndex = currentProcess.ioIndex + 1
		}
		print("Now running: " + "P" + String(currentProcess.id))
		print("..................................................")
		print("Ready Queue:\tProcess\tBurst")
		for p in self.fcfsQueue!.processes {
			if p.arrivalTime <= self.currentTime {
				if p.firstTimeExecution {
					print("\t\t\tP" + String(p.id) + "\t\t" + String(p.currentBurst))
				} else {
					print("\t\t\tP" + String(p.id) + "\t\t" + String(p.bursts[p.burstIndex]))
				}
			}
		}
		print("Now in I/O:\tProcess\tRemaining I/O time")
		for p in self.fcfsQueue!.processes {
			if p.arrivalTime > self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.arrivalTime - self.currentTime))
			}
		}
		// update firstTimeExecution
		currentProcess.firstTimeExecution = false
		// increment burst index and guard to make sure we are not accessing an index out of range
		currentProcess.burstIndex = currentProcess.burstIndex + 1
		guard currentProcess.burstIndex < currentProcess.bursts.count else {
			currentProcess.isDone = true
			print("\n\n-------P" + String(currentProcess.id) + " has finished executing-------\n")
			// add to current time the process' last burst
			self.currentTime += currentProcess.currentBurst
			// set end time
			currentProcess.timeFinished = self.currentTime
			// add process to array of processes (not the queue - used for calculateTimes)
			fcfsProcesses!.append(currentProcess)
			return
		}
		// update current time
		self.currentTime += currentProcess.currentBurst
		// update arrival time with i/o time
		currentProcess.arrivalTime = self.currentTime + currentProcess.currentIO
		// enqueue process again
		self.fcfsQueue?.enqueue(currentProcess)
		// sort fcfs queue to reflect new addition (sorts based on arrival time and id)
		self.fcfsQueue?.setProcess(p: (self.fcfsQueue?.processes.sorted(by: {
			if (($0 as CPUProcess).arrivalTime == ($1 as CPUProcess).arrivalTime) {
				return ($0 as CPUProcess).id < ($1 as CPUProcess).id
			} else {
				return ($0 as CPUProcess).arrivalTime < ($1 as CPUProcess).arrivalTime
			}
		}))!)
		print("\n::::::::::::::::::::::::::::::::::::::::::::::::::\n\n")
	}

	// function used to find the turnaround, waiting, & response time, etc
	private func calculateTimes () {
		// sort array of processes by id
		self.fcfsProcesses?.sort { ($0 as CPUProcess).id < ($1 as CPUProcess).id }
		print("FCFS Simulation Results:\n")
		print("Total Time: " + String(self.currentTime) + "\n")
		print("..................................................\n")
		// find cpu utilization by subtracting idle time from total time and dividing by total time
		print("CPU Utilization: " + String(((Float(self.currentTime) - Float(self.timeIdle))/Float(self.currentTime)) * 100.0) + "%\n")
		print("..................................................")
		print("\nWaiting times: \n")
		var burstSum: Int = 0
		var ioSum: Int = 0
		var waitingTime: Int = 0
		var waitingSum: Int = 0
		// adding up all of the bursts and io times
		for p in self.fcfsProcesses! {
			for burst in p.bursts {
				burstSum += burst
			}

			for io in p.ioTimes {
				ioSum += io
			}
			// find waiting time
			waitingTime = (p.timeFinished! - burstSum - ioSum)
			print("CPUProcess: P" + String(p.id) + "\t\tWaiting Time: " + String(waitingTime) + "\n")
			// add to sum of waiting time
			waitingSum += waitingTime
			// clear values for next iteration
			ioSum = 0
			burstSum = ioSum
			waitingTime = 0
		}
		print("\nAverage Waiting time: " + String(waitingSum/8) + "\n")
		print("..................................................")
		print("\nTurnaround Times: \n")
		var turnAroundSum: Int = 0
		// find turn around sum by adding together all the processes' end times
		for p in self.fcfsProcesses! {
			print("CPUProcess: P" + String(p.id) + "\t\tTurnaround Time: " + String(p.timeFinished!) + "\n")
			turnAroundSum += p.timeFinished!
		}
		print("\nAverage Turnaround time: " + String(turnAroundSum/8) + "\n")
		print("..................................................")
		print("\nResponse times:\n")
		var responseSum: Int = 0
		// find response sum by adding together all the processes' response time
		for p in self.fcfsProcesses! {
			print("CPUProcess: P" + String(p.id) + "\t\tResponse Time: " + String(p.response!) + "\n")
			responseSum += p.response!
		}
		print("\nAverage Response time: " + String(responseSum/8) + "\n")
		print("..................................................\n")
	}
}
