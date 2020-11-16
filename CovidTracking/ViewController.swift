//
//  ViewController.swift
//  CovidTracking
//
//  Created by Loren Olson on 9/30/20.
//

import Cocoa


enum GraphSubject {
    case newTests
    case newCases
    case currentHospitalizations
    case newDeaths
}

class ViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var dataTableColumn: NSTableColumn!
    
    @IBOutlet weak var graphView: GraphView!
    
    @IBOutlet weak var statePopUp: NSPopUpButton!
    
    @IBOutlet weak var subjectPopUp: NSPopUpButton!
    
    var subject = GraphSubject.newCases
    
    var historicValues: [CovidDaily] = []
    var states: [CovidTrackingState] = []
    let dateFormatter = DateFormatter()
    
    var historicUSValues: [CovidUSDaily] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        switch subject {
        case .newTests:
            subjectPopUp.selectItem(at: 0)
        case .newCases:
            subjectPopUp.selectItem(at: 1)
        case .currentHospitalizations:
            subjectPopUp.selectItem(at: 2)
        case .newDeaths:
            subjectPopUp.selectItem(at: 3)
        }
        
        dateFormatter.timeStyle = .none
        dateFormatter.dateStyle = .short
        
        tableView.delegate = self
        tableView.dataSource = self
        
        requestStateInfo()

        historicValuesForState(state: "AZ")
    }


    func historicValuesForState(state: String) {
        let session = URLSession.shared
        
        guard let url = URL(string: "https://api.covidtracking.com/v1/states/\(state)/daily.json") else {
            return;
        }
        
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error as NSError? {
                // There was an error. Report it to the user, and done.
                print(error)
                self.reportError(error: error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                // Something has gone terribly wrong, there was no HTTP response.
                print("unknown response")
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                // The HTTP status code is an error. Report it to the user, and done.
                print("http response code \(httpResponse.statusCode)")
                self.reportStatus(code: httpResponse.statusCode)
                return
            }
            
            //print("***** Here is the HttpResponse: ******")
            //print(httpResponse)
            
            // Unwrap the data object.
            guard let data = data else {
                print("unable to unwrap response data.")
                return
            }
            
            // Decode the JSON response.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom({(dateDecoder) -> Date in
                let dateAsNumber = try dateDecoder.singleValueContainer().decode(Int.self)
                let dateAsString = String(dateAsNumber)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                if let date = formatter.date(from: dateAsString) {
                    return date
                }
                return Date()
            })
            var values: [CovidDaily] = []
            do {
                values = try decoder.decode([CovidDaily].self, from: data)
            }
            catch {
                self.reportError(error: error)
                return
            }
            self.historicValues = values
            
            //print("***** Decoded Data *****")
            print("State: \(state) has \(self.historicValues.count) historic values.")
            
            let graphValues = self.gatherSubjectData()
            
            
            DispatchQueue.main.async {
                // Update the UI on the main thread.
                self.graphView.values = graphValues
                self.graphView.needsDisplay = true
                self.tableView.reloadData()
            }
            
        })
        
        task.resume()
    }
    
    
    func historicValuesForUS() {
        let session = URLSession.shared
        
        guard let url = URL(string: "https://api.covidtracking.com/v1/us/daily.json") else {
            return;
        }
        
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error as NSError? {
                // There was an error. Report it to the user, and done.
                print(error)
                self.reportError(error: error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                // Something has gone terribly wrong, there was no HTTP response.
                print("unknown response")
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                // The HTTP status code is an error. Report it to the user, and done.
                print("http response code \(httpResponse.statusCode)")
                self.reportStatus(code: httpResponse.statusCode)
                return
            }
            
            //print("***** Here is the HttpResponse: ******")
            //print(httpResponse)
            
            // Unwrap the data object.
            guard let data = data else {
                print("unable to unwrap response data.")
                return
            }
            
            // Decode the JSON response.
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom({(dateDecoder) -> Date in
                let dateAsNumber = try dateDecoder.singleValueContainer().decode(Int.self)
                let dateAsString = String(dateAsNumber)
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd"
                if let date = formatter.date(from: dateAsString) {
                    return date
                }
                return Date()
            })
            var values: [CovidUSDaily] = []
            do {
                values = try decoder.decode([CovidUSDaily].self, from: data)
            }
            catch {
                self.reportError(error: error)
                return
            }
            self.historicUSValues = values
            
            //print("***** Decoded Data *****")
            print("Historic US data has \(self.historicUSValues.count) historic values.")
            
            let graphValues = self.gatherSubjectDataUS()
            
            
            DispatchQueue.main.async {
                // Update the UI on the main thread.
                self.graphView.values = graphValues
                self.graphView.needsDisplay = true
                self.tableView.reloadData()
            }
            
        })
        
        task.resume()
    }
    
    
    func gatherSubjectData() -> [CovidGraphData] {
        var graphData: [CovidGraphData]
        switch subject {
        case .newTests:
            graphData = historicValues.map { CovidGraphData(date: $0.date, value: $0.totalTestResultsIncrease ?? 0) }
        case .newCases:
            graphData = historicValues.map { CovidGraphData(date: $0.date, value: $0.positiveIncrease ?? 0) }
        case .currentHospitalizations:
            graphData = historicValues.map { CovidGraphData(date: $0.date, value: $0.hospitalizedCurrently ?? 0) }
        case .newDeaths:
            graphData = historicValues.map { CovidGraphData(date: $0.date, value: $0.deathIncrease ?? 0) }
        }
        return graphData
    }
    
    
    func gatherSubjectDataUS() -> [CovidGraphData] {
        var graphData: [CovidGraphData]
        switch subject {
        case .newTests:
            graphData = historicUSValues.map { CovidGraphData(date: $0.date, value: $0.totalTestResultsIncrease ?? 0) }
        case .newCases:
            graphData = historicUSValues.map { CovidGraphData(date: $0.date, value: $0.positiveIncrease ?? 0) }
        case .currentHospitalizations:
            graphData = historicUSValues.map { CovidGraphData(date: $0.date, value: $0.hospitalizedCurrently ?? 0) }
        case .newDeaths:
            graphData = historicUSValues.map { CovidGraphData(date: $0.date, value: $0.deathIncrease ?? 0) }
        }
        return graphData
    }
    
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.graphView.values.count
    }
    
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard let column = tableColumn else { return nil }
        
        let data = self.graphView.values[row]
        
        switch column.title {
        case "Date":
            return dateFormatter.string(from: data.date)
        default:
            return "\(data.value)"
        }
    }
    
    @IBAction func selectionUpdate(_ sender: NSPopUpButton) {
        let i = sender.indexOfSelectedItem
        if i == 0 {
            historicValuesForUS()
        }
        else {
            let s = states[i-1]
            historicValuesForState(state: s.state)
        }
    }
    
    
    @IBAction func subjectUpdate(_ sender: NSPopUpButton) {
        switch sender.titleOfSelectedItem {
        case "New tests":
            subject = .newTests
            dataTableColumn.title = "Results Increase"
        case "New cases":
            subject = .newCases
            dataTableColumn.title = "Positive Increase"
        case "Current hospitalizations":
            subject = .currentHospitalizations
            dataTableColumn.title = "Hospitalizations"
        case "New deaths":
            subject = .newDeaths
            dataTableColumn.title = "Death Increase"
        default:
            subject = .newCases
        }
        let i = statePopUp.indexOfSelectedItem
        if i == 0 {
            let graphValues = gatherSubjectDataUS()
            graphView.values = graphValues
        }
        else {
            let graphValues = gatherSubjectData()
            graphView.values = graphValues
        }
        graphView.needsDisplay = true
        tableView.reloadData()
    }
    
    
    // Report the status code to the user.
    // In production, you should provide better info.
    func reportStatus(code: Int) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "HTTP Status Code \(code)"
            alert.informativeText = "The HTTP server returned an error status code."
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Ok")
            alert.runModal()
        }
    }
    
    
    // Report the error directly to the user.
    func reportError(error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert(error: error)
            alert.runModal()
        }
    }
    
    
    
    
    
    func requestStateInfo() {
        let session = URLSession.shared
        
        guard let url = URL(string: "https://api.covidtracking.com/v1/states/info.json") else {
            return;
        }
        
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            if let error = error as NSError? {
                // There was an error. Report it to the user, and done.
                print("***** Error *****")
                print(error)
                self.reportError(error: error)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse else {
                // Something has gone terribly wrong, there was no HTTP response.
                print("unknown response")
                return
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                // The HTTP status code is an error. Report it to the user, and done.
                print("http response code \(httpResponse.statusCode)")
                self.reportStatus(code: httpResponse.statusCode)
                return
            }
            
            // Unwrap the data object.
            guard let data = data else {
                print("Unable to unwrap StatesInfo data from response.")
                return
            }
            
            // Decode the JSON response.
            let decoder = JSONDecoder()
            guard let statesInfo = try? decoder.decode([CovidTrackingState].self, from: data) else {
                print("StatesInfo Decoding failed.")
                return
            }
            self.states = statesInfo
            
            DispatchQueue.main.async {
                print("There are \(self.states.count) state info entries.")
                self.setupStatesPopUp()
            }
            
        })
        
        task.resume()
    }
    
    
    func setupStatesPopUp() {
        statePopUp.removeAllItems()
        
        statePopUp.addItem(withTitle: "United States")
        
        for s in states {
            statePopUp.addItem(withTitle: s.name)
        }
        
        statePopUp.selectItem(withTitle: "Arizona")
    }


}

