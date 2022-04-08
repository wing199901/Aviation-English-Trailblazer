//
//  pronunciationAssessmentResult.swift
//  Aviation English Trailblazer
//
//  Created by Steven Siu  on 21/1/2022.
//

// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let pronunciationAssessmentResult = try? newJSONDecoder().decode(PronunciationAssessmentResult.self, from: jsonData)

import Foundation

// MARK: - PronunciationAssessmentResult
struct PronunciationAssessmentResult: Codable {
    let recognitionStatus: String
    let offset: Int
    let duration: Int
    let nBest: [NBest]

    enum CodingKeys: String, CodingKey {
        case recognitionStatus = "RecognitionStatus"
        case offset = "Offset"
        case duration = "Duration"
        case nBest = "NBest"
    }
}

// MARK: - NBest
struct NBest: Codable {
    let confidence: Double
    let lexical: String
    let itn: String
    let maskedITN: String
    let display: String
    let pronunciationAssessment: NBestPronunciationAssessment
    let words: [Word]

    enum CodingKeys: String, CodingKey {
        case confidence = "Confidence"
        case lexical = "Lexical"
        case itn = "ITN"
        case maskedITN = "MaskedITN"
        case display = "Display"
        case pronunciationAssessment = "PronunciationAssessment"
        case words = "Words"
    }
}

// MARK: - NBestPronunciationAssessment
struct NBestPronunciationAssessment: Codable {
    let pronScore: Double
    let accuracyScore: Double
    let fluencyScore: Double
    let completenessScore: Double

    enum CodingKeys: String, CodingKey {
        case pronScore = "PronScore"
        case accuracyScore = "AccuracyScore"
        case fluencyScore = "FluencyScore"
        case completenessScore = "CompletenessScore"
    }
}

// MARK: - Word
struct Word: Codable {
    let word: String
    let offset: Int
    let duration: Int
    let pronunciationAssessment: WordPronunciationAssessment

    enum CodingKeys: String, CodingKey {
        case word = "Word"
        case offset = "Offset"
        case duration = "Duration"
        case pronunciationAssessment = "PronunciationAssessment"
    }
}

// MARK: - WordPronunciationAssessment
struct WordPronunciationAssessment: Codable {
    let accuracyScore: Double
    let errorType: String

    enum CodingKeys: String, CodingKey {
        case accuracyScore = "AccuracyScore"
        case errorType = "ErrorType"
    }
}
