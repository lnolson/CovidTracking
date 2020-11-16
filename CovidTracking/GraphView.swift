//
//  GraphView.swift
//  CovidTracking
//
//  Created by Loren Olson on 10/29/20.
//

import Cocoa

class GraphView: NSView {
    
    var values: [CovidGraphData] = []
    
    var graphBgColor = CGColor(red: 0.985, green: 0.985, blue: 0.985, alpha: 1)
    var rawPointColor = CGColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.2)
    var avgLineColor = CGColor(red: 0.1, green: 0.1, blue: 0.9, alpha: 0.8)
    
    var margin = CGFloat(0.0)
    var graphX = CGFloat(0.0)
    var graphY = CGFloat(0.0)
    var graphWidth = CGFloat(0.0)
    var graphHeight = CGFloat(0.0)
    
    var minimumValue = 1000000
    var maximumValue = 0
    
    var verticalTicks = 10
    
    var labelFont = NSFont(name: "Meno Regular", size: 12)
    var legendFont = NSFont.systemFont(ofSize: 13)
    
    var labelAttributes: [NSAttributedString.Key : Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1),
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.kern: 0,
            NSAttributedString.Key.font: labelFont ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        ]
        return attributes
    }
    var blueLegendAttributes: [NSAttributedString.Key : Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        let attributes: [NSAttributedString.Key : Any] = [
            NSAttributedString.Key.foregroundColor: NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.9, alpha: 0.8),
            NSAttributedString.Key.paragraphStyle: paragraphStyle,
            NSAttributedString.Key.kern: 0,
            NSAttributedString.Key.font: legendFont
        ]
        return attributes
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current else { return }
        let cg = context.cgContext
        
        // background fill
        cg.setFillColor(graphBgColor)
        let viewRect = CGRect(x: 0.0, y: 0.0, width: bounds.size.width, height: bounds.size.height)
        cg.fill(viewRect)
        
        margin = 75.0
        graphX = margin
        graphY = margin
        graphWidth = frame.width - (margin * 2.0)
        graphHeight = frame.height - (margin * 2.0)
        
        // draw outer rectangle
        let graphRect = CGRect(x: graphX, y: graphY, width: graphWidth, height: graphHeight)
        cg.setStrokeColor(red: 0, green: 0, blue: 0, alpha: 1)
        cg.stroke(graphRect)
        
        if values.count == 0 {
            return
        }
        
        // dateInterval is the distance in days (x-axis), used for mapping
        guard let firstDay = values.last, let lastDay = values.first else { return }
        let dateInterval = CGFloat(lastDay.date.timeIntervalSince(firstDay.date))
        
        // find the min and max data values (for y-axis)
        minimumValue = 1000000
        maximumValue = 0
        for day in values {
            if day.value < minimumValue {
                minimumValue = day.value
            }
            if day.value > maximumValue {
                maximumValue = day.value
            }
        }
        
        // Use Heckbert's loose label alg to find nice values for min and max and to place labels in between
        let verticalList = looseLabel(minimum: CGFloat(minimumValue), maximum: CGFloat(maximumValue), ticks: verticalTicks)
        minimumValue = Int(verticalList.first ?? 0)
        if minimumValue < 0 {  // this shouldn't really happen? But it did.
            minimumValue = 0
        }
        maximumValue = Int(verticalList.last ?? 0)
        
        // distance between min and max, used for mapping y-axis
        let valueInterval = maximumValue - minimumValue
        
        legendText(cg: cg, x: graphX, y: 10)
        horizontalLabels()
        verticalLabels()
        
        // Plot the raw points
        cg.setFillColor(rawPointColor)
        for day in values {
            let xValue = CGFloat(day.date.timeIntervalSince(firstDay.date))
            let yValue = day.value
            
            let xMapped = graphX + (xValue / dateInterval) * graphWidth
            let yMapped = graphY + (CGFloat(yValue - minimumValue) / CGFloat(valueInterval)) * graphHeight
            
            let point = CGRect(x: xMapped - 3, y: yMapped - 3, width: 6, height: 6)
            cg.fillEllipse(in: point)
        }
        
        // Draw a 7-day average
        cg.setStrokeColor(avgLineColor)
        let avgLine = NSBezierPath()
        avgLine.lineWidth = 2
        var i = 0
        while i < (values.count - 7) {
            let day = values[i]
            let xValue = CGFloat(day.date.timeIntervalSince(firstDay.date))
            var yValue = CGFloat(0)
            var j = 0
            while j < 7 {
                let nextDay = values[i + j]
                yValue += CGFloat(nextDay.value)
                j += 1
            }
            yValue = yValue / 7
            
            let xMapped = graphX + (xValue / dateInterval) * graphWidth
            let yMapped = graphY + ((yValue - CGFloat(minimumValue)) / CGFloat(valueInterval)) * graphHeight
            
            if i == 0 {
                avgLine.move(to: NSPoint(x: xMapped, y: yMapped))
            }
            else {
                avgLine.line(to: NSPoint(x: xMapped, y: yMapped))
            }
            
            i = i + 1
        }
        avgLine.stroke()
    }
    
    
    func legendText(cg: CGContext, x: CGFloat, y: CGFloat) {
        let str = NSAttributedString(string: "Blue line is 7-day average", attributes: blueLegendAttributes)
        let frameSetter = CTFramesetterCreateWithAttributedString(str as CFAttributedString)
        var fitRange = CFRangeMake(0, 0)
        let suggested = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0,str.length), nil, CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), &fitRange)
        
        let textPath = CGPath(rect: CGRect(x: x, y: y, width: suggested.width, height: suggested.height), transform: nil)
        let textFrame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: str.length), textPath, nil)
        CTFrameDraw(textFrame, cg)
    }
    
    func horizontalLabels() {
        guard let context = NSGraphicsContext.current else { return }
        let cg = context.cgContext
        guard let firstDay = values.last, let lastDay = values.first else { return }
        let dateInterval = CGFloat(lastDay.date.timeIntervalSince(firstDay.date))
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        
        let line = NSBezierPath()
        line.lineWidth = 2
        cg.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.75))
        
        line.move(to: NSPoint(x: graphX, y: graphY))
        line.line(to: NSPoint(x: graphX, y: graphY - 10))
        horizontalLabelText(cg: cg, msg: formatter.string(from: firstDay.date), x: graphX, y: graphY - 14)
        
        line.move(to: NSPoint(x: graphX + graphWidth, y: graphY))
        line.line(to: NSPoint(x: graphX + graphWidth, y: graphY - 10))
        horizontalLabelText(cg: cg, msg: formatter.string(from: lastDay.date), x: graphX + graphWidth, y: graphY - 14)
        
        
        
        let lightLine = NSBezierPath()
        lightLine.lineWidth = 1
        
        let horizontalTicks = 8
        let firstIndex = 0
        let lastIndex = values.count - 1
        
        let dx = (lastIndex - firstIndex) / horizontalTicks
        var i = lastIndex - dx
        var px = graphX
        while i > firstIndex {
            let day = values[i]
            let xValue = CGFloat(day.date.timeIntervalSince(firstDay.date))
            let xMapped = graphX + (xValue / dateInterval) * graphWidth
            
            if xMapped - px < 30.0 || (graphX + graphWidth - xMapped) < 30.0 {
                
                i -= dx
                continue
            }
            
            lightLine.move(to: NSPoint(x: xMapped, y: graphY))
            lightLine.line(to: NSPoint(x: xMapped, y: graphY + graphHeight))
            
            line.move(to: NSPoint(x: xMapped, y: graphY))
            line.line(to: NSPoint(x: xMapped, y: graphY - 10))
            horizontalLabelText(cg: cg, msg: formatter.string(from: day.date), x: xMapped, y: graphY - 14)
            
            px = xMapped
            i -= dx
        }
        line.stroke()
        
        cg.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.1))
        lightLine.stroke()
        
    }
    
    
    func horizontalLabelText(cg: CGContext, msg: String, x: CGFloat, y: CGFloat) {
        let str = NSAttributedString(string: msg, attributes: labelAttributes)
        let frameSetter = CTFramesetterCreateWithAttributedString(str as CFAttributedString)
        var fitRange = CFRangeMake(0, 0)
        let suggested = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0,str.length), nil, CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), &fitRange)
        
        let tx = x - suggested.width / 2.0  // horizontal center align
        let ty = y - suggested.height   // vertical top align
        let textPath = CGPath(rect: CGRect(x: tx, y: ty, width: suggested.width, height: suggested.height), transform: nil)
        let textFrame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: str.length), textPath, nil)
        CTFrameDraw(textFrame, cg)
    }
    
    
    func verticalLabels() {
        guard let context = NSGraphicsContext.current else { return }
        let cg = context.cgContext
        
        // The numbers and ticks along left side
        var line = NSBezierPath()
        line.lineWidth = 2
        cg.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.75))
        let valueInterval = maximumValue - minimumValue
        let verticalList = looseLabel(minimum: CGFloat(minimumValue), maximum: CGFloat(maximumValue), ticks: verticalTicks)
        for y in verticalList {
            let yMapped = graphY + ((y - CGFloat(minimumValue)) / CGFloat(valueInterval)) * graphHeight
            line.move(to: NSPoint(x: graphX, y: yMapped))
            line.line(to: NSPoint(x: graphX - 10, y: yMapped))
            verticalLabelText(cg: cg, msg: "\(Int(y))", x: graphX - 14, y: yMapped)
        }
        line.stroke()
        
        // Draw the light lines across the graph
        line = NSBezierPath()
        line.lineWidth = 1
        cg.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 0.1))
        var i = 1
        while i < verticalList.count - 1 {
            let y = verticalList[i]
            let yMapped = graphY + ((y - CGFloat(minimumValue)) / CGFloat(valueInterval)) * graphHeight
            line.move(to: NSPoint(x: graphX, y: yMapped))
            line.line(to: NSPoint(x: graphX + graphWidth, y: yMapped))
            i = i + 1
        }
        line.stroke()
    }
    
    
    func verticalLabelText(cg: CGContext, msg: String, x: CGFloat, y: CGFloat) {
        let str = NSAttributedString(string: msg, attributes: labelAttributes)
        let frameSetter = CTFramesetterCreateWithAttributedString(str as CFAttributedString)
        var fitRange = CFRangeMake(0, 0)
        let suggested = CTFramesetterSuggestFrameSizeWithConstraints(frameSetter, CFRangeMake(0,str.length), nil, CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude), &fitRange)
        
        let tx = x - suggested.width        // horizontal right align
        let ty = y - suggested.height / 2   // vertical center align
        let textPath = CGPath(rect: CGRect(x: tx, y: ty, width: suggested.width, height: suggested.height), transform: nil)
        let textFrame = CTFramesetterCreateFrame(frameSetter, CFRange(location: 0, length: str.length), textPath, nil)
        CTFrameDraw(textFrame, cg)
    }
    
    
    
    
    // idea from Graphics Gems: Nice Numbers for graph labels (Paul Heckbert)
    // find a "nice" number approximately equal to x.
    // round the number
    func findNiceNumber(x: CGFloat, round: Bool) -> CGFloat {
        let exp = floor(log10(x))
        let f = x / pow(10, exp)
        var nf: CGFloat
        if (round) {
            if f < 1.5 { nf = 1.0 }
            else if f < 3.0 { nf = 2.0 }
            else if f < 7.0 { nf = 5.0 }
            else { nf = 10.0 }
        }
        else {
            if f <= 1.0 { nf = 1.0 }
            else if f <= 2.0 { nf = 2.0 }
            else if f <= 5.0 { nf = 5.0 }
            else { nf = 10.0 }
        }
        return nf * pow( 10.0, exp )
    }
    
    func looseLabel(minimum: CGFloat, maximum: CGFloat, ticks: Int) -> [CGFloat] {
        let range = findNiceNumber(x: (maximum - minimum), round: false)
        let d = findNiceNumber(x: range / (CGFloat(ticks) - 1), round: true)
        let gmin = floor(minimum / d) * d
        let gmax = ceil(maximum / d) * d
        // nfrac is number of fractional digits to show
        //let nfrac = Int(max(-floor(log10(d)), 0.0))
        
        var list: [CGFloat] = []
        var x = gmin
        while x < gmax + 0.5 * d {
            list.append(x)
            x += d
        }
        
        return list
    }
    
    
}
