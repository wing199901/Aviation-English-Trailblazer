//
//  LevelSource.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 5/11/2021.
//

struct Level {
    let id: Int
    let description: String
    let planeQty: Int
}

struct Levels {
    func levels() -> [Level] {
        var array = [Level]()
        for dict in source() {
            let level = Level(
                id: dict["id"]! as! Int,
                description: dict["description"]! as! String,
                planeQty: dict["planeQty"]! as! Int
            )
            array.append(level)
        }
        return array
    }

    func source() -> [[String: Any]] {
        [["id": 1, "description": "This level introduces basic pilot-controller communication. A couple of arrival and departure scenarios will be presented, along with the necessary information for the controller to manage the flow of the incoming and outgoing aircrafts. These information include, but not limited to, taxiing instructions, simulated ATIS broadcast, and runway instructions. A script should be provided as an aid to this level.", "planeQty": 4],
//         ["id": 2, "description": "This level presents new scenarios with more complicated taxiing scenarios, one of which will include the waiting and crossing of a busy runway. A total of 7 aircrafts will be landing or departing through the airspace. To aid with this level, a script with missing keywords will be provided.", "planeQty": 7],
         ["id": 2, "description": "This level presents new scenarios with more complicated taxiing scenarios, one of which will include the waiting and crossing of a busy runway. A total of 7 aircrafts will be landing or departing through the airspace. To aid with this level, a script with missing keywords will be provided.", "planeQty": 4],
         ["id": 3, "description": "Knowledge learned from Level 1 and 2 are all present in this level, but with no scripts provided. A total of 7 aircrafts will be landing or departing through the airspace.", "planeQty": 7],
         ["id": 4, "description": "Under development", "planeQty": 0],
         ["id": 5, "description": "Under development", "planeQty": 0]]
    }
}
