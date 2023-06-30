//
//  TimerManager.swift
//  MyPhotoReviewer
//
//  Created by Prem Pratap Singh on 29/06/23.
//

import Foundation

/**
 TimerManagerDelegate notifies other objects (delegates) about timer related events
 */
protocol TimerManagerDelegate: AnyObject {
    func onChangeTime(_ time: Double)
}

/**
 TimerManager provides API for working with timer for starting, pausing, resuming timers.
 */
class TimerManager {
    
    // MARK: Public properties
    
    weak var delegate: TimerManagerDelegate?
    
    var isTimerRunning: Bool {
        return self.timer != nil
    }
    
    var elapsedTime: TimeInterval {
        if let startDate = self.startDate {
            return self.accumulatedTime + Date().timeIntervalSince(startDate)
        } else {
            return self.accumulatedTime
        }
    }
    
    // MARK: Private properties
    
    private var timer: Timer?
    private var startDate: Date?
    private var accumulatedTime: TimeInterval = 0
    
    
    // MARK: Public methods
    
    func startTimer() {
        if self.timer == nil {
            self.startDate = Date()
            self.timer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(self.timerFired),
                userInfo: nil,
                repeats: true
            )
            self.timer?.tolerance = 0.01
        }
    }
    
    func pauseTimer() {
        guard let startDate = self.startDate else { return }
        self.accumulatedTime += Date().timeIntervalSince(startDate)
        self.invalidateTimer()
    }
    
    func resumeTimer() {
        if timer == nil {
            self.startDate = Date()
            self.timer = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(self.timerFired),
                userInfo: nil,
                repeats: true
            )
            self.timer?.tolerance = 0.01
        }
    }
    
    func stopTimer() {
        self.accumulatedTime = 0
        self.invalidateTimer()
    }
    
    func invalidate() {
        self.accumulatedTime = 0
        self.invalidateTimer()
    }
    
    // MARK: Private methods
    
    @objc private func timerFired() {
        self.delegate?.onChangeTime(self.accumulatedTime)
    }
    
    private func invalidateTimer() {
        self.timer?.invalidate()
        self.timer = nil
        self.accumulatedTime = 0
        self.startDate = nil
    }
}
