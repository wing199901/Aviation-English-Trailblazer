//
//  LevelDetailViewModel.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 5/11/2021.
//

protocol LevelDetailViewModelRepresentable {
    var id: Int { get }
    var description: String { get }
    var planeQty: Int { get }
}

struct LevelDetailViewModel: LevelDetailViewModelRepresentable {
    let id: Int
    let description: String
    let planeQty: Int

    init(level: Level) {
        self.id = level.id
        self.description = level.description
        self.planeQty = level.planeQty
    }
}
