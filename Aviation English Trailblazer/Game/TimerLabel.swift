//
//  TimerLabel.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 18/11/2021.
//

import UIKit.UILabel

/// A UILabel count down time
class TimerLabel: UILabel {
    // MARK: - Properties
    private var seconds: Int = 0
    private var timer = Timer()

    private var isTimerRunning: Bool = false

    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        text = timeString(time: TimeInterval(seconds))
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - Funtions
    /// Start timer
    func runTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)

        RunLoop.current.add(timer, forMode: .common)

        isTimerRunning = true
    }

    @objc func updateTimer() {
        if seconds < 1 {
            timer.invalidate()
            isTimerRunning = false
            print("Time's up")
        } else {
            seconds -= 1 // Count down the seconds.
            text = timeString(time: TimeInterval(seconds)) // Update the text
        }
    }

    func pauseTimer() {
        timer.invalidate()
        isTimerRunning = false
        print("Timer pause")
    }

    func resetTimer(seconds: Int) {
        timer.invalidate()
        self.seconds = seconds
        text = timeString(time: TimeInterval(seconds))
        isTimerRunning = false
        print("Timer reset")
    }

    func isRunning() -> Bool {
        isTimerRunning
    }

    func timeString(time: TimeInterval) -> String {
        // let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60

        // return String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        return String(format: "%02i:%02i", minutes, seconds)
    }
}
