//
//  GameOverViewModel.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 4/11/2021.
//

protocol GameOverViewModelRepresentable {
    var senderIDArr: [String] { get }
}

struct GameOverViewModel: GameOverViewModelRepresentable {
    let senderIDArr: [String]

    init(senderIDArr: [String]) {
        self.senderIDArr = senderIDArr
    }
}
