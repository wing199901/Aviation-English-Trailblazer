//
//  RasaModel.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 1/12/2021.
//

struct RasaRequest: Encodable {
    var message: String
    var sender: String
}

struct RasaResponse: Codable {
    let recipient_id: String
    let text: String
    let action: String?
    let callsign: String?
    let via_point: String?
    let holding_point: String?
    let runway: String?
    let degree: String?
    let knot: String?
    let degreesandknots: String?
    let information: String?
    let havepermission: Bool?
    let crossable: Bool?
}
