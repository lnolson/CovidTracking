//
//  CovidDaily.swift
//  CovidTracking
//
//  Created by Loren Olson on 9/30/20.
//

import Foundation


// Used to recieve Historic values for a single state
// eg. /v1/states/{state}/daily.json
struct CovidDaily: Codable {
    
    var date: Date
    var death: Int?
    var positiveIncrease: Int?
    var state: String
    
    var dataQualityGrade: String?
    var totalTestResults: Int?
    var totalTestResultsIncrease: Int?
    var deathIncrease: Int?
    var hospitalizedCurrently: Int?
    
}


// Used to recieve Historic US values
// eg. /v1/us/daily.json
struct CovidUSDaily: Codable {
    
    var date: Date
    var death: Int?
    var deathIncrease: Int?
    var hospitalizedCurrently: Int?
    var hospitalizedIncrease: Int?
    var inIcuCurrently: Int?
    var negativeIncrease: Int?
    var onVentilatorCurrently: Int?
    var positiveIncrease: Int?
    var recovered: Int?
    var states: Int?
    var totalTestResults: Int?
    var totalTestResultsIncrease: Int?
}


// Used by GraphView
struct CovidGraphData: Codable {
    var date: Date
    var value: Int
}
