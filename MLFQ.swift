//
//  MLFQ.swift
//  SwiftScheduler

import Foundation

// class for the MLFQ algorithm
final class MLFQ {
	// private variables for this class
	private var rrQ1: ProcessQueue<CPUProcess>?
	private var rrQ2: ProcessQueue<CPUProcess>?
	private var fcfsQueue: ProcessQueue<CPUProcess>?
	private var mlfqProcesses: [CPUProcess]?
	private var currentTime: Int
	private var timeQuantum1: Int
	private var timeQuantum2: Int
	private var timeIdle: Int
	
	private init() {
		self.currentTime = 0
		self.mlfqProcesses = [CPUProcess]()
		self.rrQ1 = ProcessQueue<CPUProcess>()
		self.rrQ2 = ProcessQueue<CPUProcess>()
		self.fcfsQueue = ProcessQueue<CPUProcess>()
		self.timeQuantum1 = 0
		self.timeQuantum2 = 0
		self.timeIdle = 0
	}
	
	public convenience init(_ filename: String, timeQuantum1: Int, timeQuantum2: Int) {
		self.init()
		self.timeQuantum1 = timeQuantum1
		self.timeQuantum2 = timeQuantum2
		self.initializeProcesses(filename)
	}
	
	private func initializeProcesses(_ fileName: String) {
		do {
			var bursts = [[String]]()
			// read contents of file
			let dstr = try String(contentsOfFile: fileName)
			// separate by new line
			let burstData = dstr.components(separatedBy: .newlines)
			// separate by commas
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
				                                     priority: 1,
				                                     timeFinished: 0,
				                                     arrivalTime: 0)
				// set burst & ioTimes array to equal the array created
				process.bursts = bursts
				process.ioTimes = ioTimes
				// set current burst & io
				process.currentBurst = process.bursts[process.burstIndex]
				process.currentBurst = process.ioTimes[process.ioIndex]
				// add process to array of processes
				self.mlfqProcesses?.append(process)
			}
		} catch _ {
			print("Error: File not found")
			exit(0)
		}
		self.startProcesses()
	}
	
	private func startProcesses() {
		// add all processes to the first round robin queue
		for p in self.mlfqProcesses! {
			self.rrQ1?.enqueue(p)
		}

		// clear array of processes so it can be used for the calculations
		self.mlfqProcesses = [CPUProcess]()
		
		// call executeProcesses until all of the queues are empty
		while !fcfsQueue!.isEmpty || !rrQ1!.isEmpty || !rrQ2!.isEmpty {
			self.executeProcesses()
		}
		
		// call calculateTimes to calculate response time, turnaround time, et cetera
		self.calculateTimes()
	}
	
	private func sortProcesses(_ queue: inout ProcessQueue<CPUProcess>?) {
		queue?.setProcess(p: (queue?.processes.sorted(by: {
			if (($0 as CPUProcess).arrivalTime == ($1 as CPUProcess).arrivalTime) {
				return ($0 as CPUProcess).id < ($1 as CPUProcess).id
			} else {
				return ($0 as CPUProcess).arrivalTime < ($1 as CPUProcess).arrivalTime
			}
		}))!)
	}
	
	private func logCpuData(currentProcess: CPUProcess) {
		print("Now running: " + "P" + String(currentProcess.id))
		print("..................................................")
		print("Ready Queue:\tProcess\tBurst\tQueue")
		for p in self.rrQ1!.processes {
			if p.arrivalTime <= self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.bursts[p.burstIndex]) + "\t\tQ1")
			}
		}
		for p in self.rrQ2!.processes {
			if p.arrivalTime <= self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.bursts[p.burstIndex]) + "\t\tQ2")
			}
		}
		for p in self.fcfsQueue!.processes {
			if p.arrivalTime <= self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.bursts[p.burstIndex]) + "\t\tQ3")
			}
		}
		print("Now in I/O:\tProcess\tRemaining I/O time")
		for p in self.rrQ1!.processes {
			if p.arrivalTime > self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.arrivalTime - self.currentTime))
			}
		}
		for p in self.rrQ2!.processes {
			if p.arrivalTime > self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.arrivalTime - self.currentTime))
			}
		}
		for p in self.fcfsQueue!.processes {
			if p.arrivalTime > self.currentTime {
				print("\t\t\tP" + String(p.id) + "\t\t" + String(p.arrivalTime - self.currentTime))
			}
		}
	}

	private func executeProcesses() {
		var currentProcess: CPUProcess
		// check if this is the first time the process is executing
		if !self.rrQ1!.isEmpty && self.rrQ1!.peek()!.firstTimeExecution {
			// dequeue first process
			currentProcess = (rrQ1?.dequeue())!
			// set response time
			currentProcess.response = self.currentTime
			self.logCpuData(currentProcess: currentProcess)
			// update firstTimeExecution to be false
			currentProcess.firstTimeExecution = false
			// set current burst
			currentProcess.currentBurst = currentProcess.bursts[currentProcess.burstIndex]
			// check if current burst is less than or equal to time quantum
			if currentProcess.currentBurst <= self.timeQuantum1 {
				// update current time
				self.currentTime += currentProcess.currentBurst
				// update i/o time and current i/o only if there are more values available
				if currentProcess.ioIndex < currentProcess.ioTimes.count {
					currentProcess.currentIO = currentProcess.ioTimes[currentProcess.ioIndex]
					currentProcess.ioIndex = currentProcess.ioIndex + 1
					// update arrival time
					currentProcess.arrivalTime = self.currentTime + currentProcess.currentIO
				} else {
					// update arrival time
					currentProcess.arrivalTime = self.currentTime
				}
				// update burst index and guard to make sure we are not accessing an index out of range
				currentProcess.burstIndex = currentProcess.burstIndex + 1
				guard currentProcess.burstIndex < currentProcess.bursts.count else {
					print("\n\nCurrent time: " + String(self.currentTime))
					currentProcess.isDone = true
					print("\n\n-------P" + String(currentProcess.id) + " has finished executing-------\n")
					// set end time to equal current time
					currentProcess.timeFinished = self.currentTime
					// add finished process to array of processes
					mlfqProcesses!.append(currentProcess)
					return
				}
				// enqueue process back onto first queue
				self.rrQ1?.enqueue(currentProcess)
				// set priority to equal one
				currentProcess.priority! = 1
				self.sortProcesses(&self.rrQ1)
				print("\n\nCurrent time: " + String(self.currentTime))
			} else {
				// otherwise, currentBurst is larger than timeQuantum1...
				// update current time, arrival time, and burst array
				self.currentTime += self.timeQuantum1
				currentProcess.arrivalTime = self.currentTime
				currentProcess.bursts[currentProcess.burstIndex] -= self.timeQuantum1
				// downgrade process to Q2, enqueue it
				self.rrQ2?.enqueue(currentProcess)
				// reset priority to 2
				currentProcess.priority! = 2
				self.sortProcesses(&self.rrQ2)
				print("\n\nCurrent time: " + String(self.currentTime))
			}
			
		} else {
			// if you are here, it means that this is not a first-time execution
			var currentProcess: CPUProcess
			// checks if there are any processes that can be executed from Q1
			if !self.rrQ1!.isEmpty && self.rrQ1!.peek()!.arrivalTime <= self.currentTime {
				// dequeue first process
				currentProcess = (self.rrQ1?.dequeue())!
				self.logCpuData(currentProcess: currentProcess)
				// sets current burst
				currentProcess.currentBurst = currentProcess.bursts[currentProcess.burstIndex]
				// checks if the current burst is less than or equal to the time quantum
				if currentProcess.currentBurst <= self.timeQuantum1 {
					// updates current time
					self.currentTime += currentProcess.currentBurst
					// updates i/o time and current i/o if there are any more values
					if currentProcess.ioIndex < currentProcess.ioTimes.count {
						currentProcess.currentIO = currentProcess.ioTimes[currentProcess.ioIndex]
						currentProcess.ioIndex = currentProcess.ioIndex + 1
						// update arrival time
						currentProcess.arrivalTime = self.currentTime + currentProcess.currentIO
					} else {
						// update arrival time
						currentProcess.arrivalTime = self.currentTime
					}
					// update burst index, and then guard against segmentation fault [index out of range]
					currentProcess.burstIndex = currentProcess.burstIndex + 1
					guard currentProcess.burstIndex < currentProcess.bursts.count else {
						print("\n\nCurrent time: " + String(self.currentTime))
						currentProcess.isDone = true
						print("\n\n-------P" + String(currentProcess.id) + " has finished executing-------\n")
						// set end time to equal current time
						currentProcess.timeFinished = self.currentTime
						// add process to process array
						mlfqProcesses!.append(currentProcess)
						return
					}
					// enqueue process back onto first queue
					self.rrQ1?.enqueue(currentProcess)
					// set priority
					currentProcess.priority! = 1
					self.sortProcesses(&self.rrQ1)
					print("\n\nCurrent time: " + String(self.currentTime))
				} else {
					// else, the process is too large for the time quantum
					// update current time
					self.currentTime += self.timeQuantum1
					// update arrival time
					currentProcess.arrivalTime = self.currentTime
					// update burst array
					currentProcess.bursts[currentProcess.burstIndex] -= self.timeQuantum1
					// downgrade process to Q2, and enqueue onto Q2
					self.rrQ2?.enqueue(currentProcess)
					// update priority
					currentProcess.priority! = 2
					self.sortProcesses(&self.rrQ2)
					print("\n\nCurrent time: " + String(self.currentTime))
				}
			} else if !self.rrQ2!.isEmpty && self.rrQ2!.peek()!.arrivalTime <= self.currentTime {
				// no available processes in Q1, but there are in Q2
				// dequeue first process
				currentProcess = (self.rrQ2?.dequeue())!
				self.logCpuData(currentProcess: currentProcess)
				// update current burst
				currentProcess.currentBurst = currentProcess.bursts[currentProcess.burstIndex]
				// check for the case of preemption from Q1
				if !self.rrQ1!.isEmpty && self.rrQ1!.peek()!.arrivalTime < self.currentTime + min(self.timeQuantum2, currentProcess.currentBurst) {
					// find the amount of time before preemption
					let preempt = self.rrQ1!.peek()!.arrivalTime - self.currentTime
					// update current time
					self.currentTime += preempt
					// update burst array
					currentProcess.bursts[currentProcess.burstIndex] -= preempt
					// update arrival time
					currentProcess.arrivalTime = self.currentTime
					// enqueue process back onto the second round robin queue
					self.rrQ2?.enqueue(currentProcess)
					// set priority
					currentProcess.priority! = 2
					self.sortProcesses(&self.rrQ2)
					print("\n\nCurrent time: " + String(self.currentTime))
					// check if the current burst is less than the time quantum
				} else if currentProcess.currentBurst <= self.timeQuantum2 {
					// update current time
					self.currentTime += currentProcess.currentBurst
					// update i/o time and current i/o if there are more values
					if currentProcess.ioIndex < currentProcess.ioTimes.count {
						currentProcess.currentIO = currentProcess.ioTimes[currentProcess.ioIndex]
						currentProcess.ioIndex = currentProcess.ioIndex + 1
						// update arrival time
						currentProcess.arrivalTime = self.currentTime + currentProcess.currentIO
					} else {
						// update arrival time
						currentProcess.arrivalTime = self.currentTime
					}
					// update burst index and then guard against segmentation fault
					currentProcess.burstIndex = currentProcess.burstIndex + 1
					guard currentProcess.burstIndex < currentProcess.bursts.count else {
						print("\n\nCurrent time: " + String(self.currentTime))
						currentProcess.isDone = true
						print("\n\n-------P" + String(currentProcess.id) + " has finished executing-------\n")
						// set end time of process
						currentProcess.timeFinished = self.currentTime
						// add process to array of processes
						mlfqProcesses!.append(currentProcess)
						return
					}
					// enqueue process back onto round robin queue
					self.rrQ2?.enqueue(currentProcess)
					// set priority
					currentProcess.priority! = 2
					self.sortProcesses(&self.rrQ2)
					print("\n\nCurrent time: " + String(self.currentTime))
				} else {
					// else, could not finish burst in time quantum
					// update current time
					self.currentTime += self.timeQuantum2
					// update arrival time
					currentProcess.arrivalTime = self.currentTime
					// update burst array
					currentProcess.bursts[currentProcess.burstIndex] -= self.timeQuantum2
					// downgrade process priority, enqueue onto Q3
					self.fcfsQueue?.enqueue(currentProcess)
					// update priority
					currentProcess.priority! = 3
					self.sortProcesses(&self.fcfsQueue)
					print("\n\nCurrent time: " + String(self.currentTime))
				}
				// check if the fcfs queue has any available processes if Q1 & Q2 don't
			} else if !self.fcfsQueue!.isEmpty && self.fcfsQueue!.peek()!.arrivalTime <= self.currentTime {
				// dequeue first process
				currentProcess = (self.fcfsQueue?.dequeue())!
				self.logCpuData(currentProcess: currentProcess)
				// update burst array
				currentProcess.currentBurst = currentProcess.bursts[currentProcess.burstIndex]
				// check for preemption with Q1
				if !self.rrQ1!.isEmpty && self.rrQ1!.peek()!.arrivalTime < self.currentTime + currentProcess.currentBurst {
					// find at what time unit preemption occurs
					let preempt = self.rrQ1!.peek()!.arrivalTime - self.currentTime
					// update current time
					self.currentTime += preempt
					// update burst array
					currentProcess.bursts[currentProcess.burstIndex] -= preempt
					// update arrival time
					currentProcess.arrivalTime = self.currentTime
					// enqueue back onto fcfs queue
					self.fcfsQueue?.enqueue(currentProcess)
					// set priority
					currentProcess.priority! = 3
					self.sortProcesses(&self.fcfsQueue)
					print("\n\nCurrent time: " + String(self.currentTime))
					// check for preemption with Q2
				} else if !self.rrQ2!.isEmpty && self.rrQ2!.peek()!.arrivalTime < self.currentTime + currentProcess.currentBurst {
					// find at what time unit preemption occurs
					let preempt = self.rrQ2!.peek()!.arrivalTime - self.currentTime
					// update current time
					self.currentTime += preempt
					// update burst array
					currentProcess.bursts[currentProcess.burstIndex] -= preempt
					// update arrival time
					currentProcess.arrivalTime = self.currentTime
					// enqueue process back onto fcfs queue
					self.fcfsQueue?.enqueue(currentProcess)
					// set priority
					currentProcess.priority! = 3
					self.sortProcesses(&self.fcfsQueue)
					print("\n\nCurrent time: " + String(self.currentTime))
				} else {
					// if no preemption occurs....
					// update current time
					self.currentTime += currentProcess.currentBurst
					// update i/o and current i/o if there are any more
					if currentProcess.ioIndex < currentProcess.ioTimes.count {
						currentProcess.currentIO = currentProcess.ioTimes[currentProcess.ioIndex]
						currentProcess.ioIndex = currentProcess.ioIndex + 1
						// update arrival time
						currentProcess.arrivalTime = self.currentTime + currentProcess.currentIO
					} else {
						// update arrival time
						currentProcess.arrivalTime = self.currentTime
					}
					// update burst index and then guard against segmentation fault
					currentProcess.burstIndex = currentProcess.burstIndex + 1
					guard currentProcess.burstIndex < currentProcess.bursts.count else {
						print("\n\nCurrent time: " + String(self.currentTime))
						currentProcess.isDone = true
						print("\n\n-------P" + String(currentProcess.id) + " has finished executing-------\n")
						// set end time to equal current time
						currentProcess.timeFinished = self.currentTime
						// add process to array of processes
						mlfqProcesses!.append(currentProcess)
						return
					}
					// enqueue process back onto fcfs queue
					self.fcfsQueue?.enqueue(currentProcess)
					// set priority
					currentProcess.priority! = 3
					self.sortProcesses(&self.fcfsQueue)
					print("\n\nCurrent time: " + String(self.currentTime))
				}
			} else {
				// if you are here, we are in an idle state.
				// next available arrival times of each queue
				let minRR1 = rrQ1?.peek()?.arrivalTime ?? Int(INT_MAX)
				let minRR2 = rrQ2?.peek()?.arrivalTime ?? Int(INT_MAX)
				let minFCFS = fcfsQueue?.peek()?.arrivalTime ?? Int(INT_MAX)
				// add the minimum value of idle time to the idle time variable
				self.timeIdle += (min(minRR1, minRR2, minFCFS) - self.currentTime)
				// update current time to be out of the idle state
				self.currentTime = min(minRR1, minRR2, minFCFS)
			}
		}
	}
	
	// function used to find turnaround time, response time, et cetera
	private func calculateTimes () {
		// sort array of processes by id
		self.mlfqProcesses?.sort { ($0 as CPUProcess).id < ($1 as CPUProcess).id }
		print("MLFQ Simulation Results:\n")
		print("Total Time: " + String(self.currentTime) + "\n")
		print("..................................................\n")
		// find cpu utilization time by subtracting current time by idle time and then dividing by current time
		print("CPU Utilization: " +  String((Float(self.currentTime) - Float(self.timeIdle)) / Float(self.currentTime) * 100) + "%\n")
		print("..................................................")
		print("\nWaiting times: \n")
		var burstSum: Int = 0
		var ioSum: Int = 0
		var waitingTime: Int = 0
		var waitingSum: Int = 0
		// adding up all the burst and io times
		for p in self.mlfqProcesses! {
			for burst in p.bursts {
				burstSum += burst
			}
			
			for io in p.ioTimes {
				ioSum += io
			}
			// find waiting time
			waitingTime = (p.timeFinished! - burstSum - ioSum)
			print("CPUProcess: P" + String(p.id) + "\t\tWaiting Time: " + String(waitingTime) + "\n")
			// add waiting time to sum of waiting time
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
		// find the sum of turnaround times by adding together all the processes' end times
		for p in self.mlfqProcesses! {
			print("CPUProcess: P" + String(p.id) + "\t\tTurnaround Time: " + String(p.timeFinished!) + "\n")
			turnAroundSum += p.timeFinished!
		}
		print("\nAverage Turnaround time: " + String(turnAroundSum/8) + "\n")
		print("..................................................")
		print("\nResponse times:\n")
		var responseSum: Int = 0
		// find the sum of response times by adding together all the processes' response times
		for p in self.mlfqProcesses! {
			print("CPUProcess: P" + String(p.id) + "\t\tResponse Time: " + String(p.response!) + "\n")
			responseSum += p.response!
		}
		print("\nAverage Response time: " + String(responseSum/8) + "\n")
		print("..................................................\n")
	}
}
