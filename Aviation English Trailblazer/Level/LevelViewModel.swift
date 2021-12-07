//
//  MenuViewModel.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

protocol LevelViewModelRepresentable {
    var source: [Level] { get }
}

struct LevelViewModel: LevelViewModelRepresentable {
    var source = [Level]()

    init() {
        for level in levels {
            source.append(level)
        }
    }

    fileprivate var levels: [Level] {
        Levels().levels()
    }
}
