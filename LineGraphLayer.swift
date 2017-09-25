//
//  LineGraph.swift
//  LevelSense
//
//  Created by Zoeb Sheikh on 9/4/17.
//  Copyright © 2017 Zoeb Sheikh. All rights reserved.
//

/*
 
 
 
 
 
'LineGraphLayer' is a main layer which contains every other layer (line graph)
 It is responsible for managing 'LineGraphChildLayer', 'VerticalLine', and 'HorizontalLine'
 It works on only the width and calculate its own height to consume least space. There is a delegate method where the views height should be updated as 'LineGraphLayer' will only update its own height.
 
 The 'values' are of type CGPoint, where x contains the values to be shown on x-axis and same for y
 
'LineGraphChildLayer' is a single graph.
 'LineGraphLayer' helps to add a layer with new values by calling :
    addLayerWith(stroke:CGColor?, fillColor:CGColor?, values: [CGPoint])
 
 
 
 
 
 */

import UIKit

@objc protocol LineGraphProtocol {
    
    /*
     point is CGPoint where user tapped
     indexes are the indexes of points selected in all the graphs. If the any point is in range then the index is appended in the indexes else Int.max is added to it, therefore mainting the size of indexes array equal to number of layer which eventually helps in mapping indexes to layer.
     inValues is a 2D array containing all the values of all the child layers or say graphs
     */
    func lineGraphTapped(atLocation point: CGPoint, withIndexs indexes: [Int], inValues:[[CGPoint]])
    
    /*
     It asks for any value which user wants to show as x and y aixs coodrinates
     */
    func getValueToShowOnXaxisFor(value: Any!) -> Any!
    func getValueToShowOnYaxisFor(value: Any!) -> Any!
    
    /*
     Whenever the height of layer is updated then this delegate can notify sender and therefore parent view height can be changed as well.
     */
    @objc optional func updatedHeightFor(lineGraphLayer: LineGraphLayer!)
}

//MARK: -

//This layer is a single graph layer
class LineGraphChildLayer: CAShapeLayer {

    var lineGraphLayer: LineGraphLayer!
    var values: [CGPoint]!
    var isFilled: Bool = false
    var points: [CGPoint]!
    
    var curvedGraph: Bool = false
    
    class func `init`(lineGraphLayer: LineGraphLayer, values: [CGPoint], stroke:CGColor?, fillColor:CGColor?) -> LineGraphChildLayer {
        
        let lineGraphChildLayer = LineGraphChildLayer()
        lineGraphChildLayer.lineGraphLayer = lineGraphLayer
        lineGraphChildLayer.values = values
        lineGraphChildLayer.strokeColor = stroke != nil ? stroke : UIColor.clear.cgColor
        lineGraphChildLayer.fillColor = fillColor != nil ? fillColor : UIColor.clear.cgColor
        lineGraphChildLayer.isFilled = fillColor != nil
        
        return lineGraphChildLayer
    }
    
    func drawGraph() {
        
        //These two values are added just to make the fillcolor actually color properly
        var newValues: [CGPoint] = [CGPoint]()
        
        newValues.append(CGPoint(x: (values.first?.x)!, y: lineGraphLayer.yValues[0]))
        for i in 0..<values.count {
            newValues.append(values[i])
        }
        newValues.append(CGPoint(x: (values.last?.x)!, y: lineGraphLayer.yValues[0]))
        
        //Make graph with dots on it
        var newPoints = getPointsForData(values: newValues, xValues: lineGraphLayer.xValues, yValues: lineGraphLayer.yValues, verticalLine: lineGraphLayer.verticalLine, horizontalLine: lineGraphLayer.horizontalLine)
        newPoints = getUpdatedPoints(points: newPoints)
        
        self.points = newPoints
        
        if newPoints.count >= 2 {
            var bezierPath: UIBezierPath!
            
            if curvedGraph {
                bezierPath = UIBezierPath.interpolateCGPoints(withHermite: newPoints, closed: false)
            } else {
                bezierPath = UIBezierPath()
                for i in 0..<newPoints.count {
                    if i == 0 {
                        bezierPath.move(to: newPoints[i])
                    } else {
                        bezierPath.addLine(to: newPoints[i])
                    }
                }
                bezierPath.lineWidth = 1
            }
                        
            let dotsPath = getPathForDotsWith(points: newPoints)
            bezierPath.append(dotsPath)
            
            self.path = bezierPath.cgPath
        } else if (newPoints.count == 1) {
            
        }
    }
    
    func getPathForDotsWith(points: [CGPoint]) -> UIBezierPath {
        let bezierPathDots = UIBezierPath()
        
        for i in 0..<points.count {
            let dotPoint = CGPoint.init(x: points[i].x, y: points[i].y)
            bezierPathDots.move(to: dotPoint)
            bezierPathDots.addArc(withCenter: dotPoint, radius: 1, startAngle: 0, endAngle: 6, clockwise: true)
        }
        
        return bezierPathDots
    }
    
    func getUpdatedPoints(points: [CGPoint]) -> [CGPoint] {
        var newPoints = [CGPoint]()
        for i in 0..<points.count {
            newPoints.append(CGPoint.init(x: points[i].x + self.lineGraphLayer.origin.x, y: points[i].y + self.lineGraphLayer.origin.y))
            
//            NSLog("Pointtttttttttttttttt: %@", NSStringFromCGPoint(CGPoint.init(x: points[i].x + self.lineGraphLayer.origin.x, y: points[i].y + self.lineGraphLayer.origin.y)))
        }
        return newPoints
    }
    
    func getPointsForData(values: [CGPoint], xValues: [CGFloat], yValues: [CGFloat], verticalLine: VertialLine, horizontalLine: HorizontalLine) -> [CGPoint] {
        
        //Actual variables just check if xMin is set or not. If its set then use it else set the first and last element of xValues and yValues as min and max
        let actualXmin: CGFloat! = lineGraphLayer.xMin == -1 ? xValues[0] : lineGraphLayer.xMin
        let actualXmax: CGFloat! = lineGraphLayer.xMax == -1 ? xValues[0] : lineGraphLayer.xMax
        let actualYmin: CGFloat! = lineGraphLayer.yMin == -1 ? yValues[0] : lineGraphLayer.yMin
        let actualYmax: CGFloat! = lineGraphLayer.yMax == -1 ? yValues[0] : lineGraphLayer.yMax
        
        var points = [CGPoint]()
        
        for i in 0..<values.count {
            let xMultiple = ((values[i].x - actualXmin) / ((actualXmax - xValues[0]) / CGFloat(xValues.count-1)))
            let xPoint = (xMultiple * horizontalLine.oneValueDistance)
            
            let yMultiple = ((values[i].y - actualYmin) / ((actualYmax - yValues[0]) / CGFloat(yValues.count-1)))
            let yPoint = (yMultiple * verticalLine.oneValueDistance)
            
            points.append(CGPoint.init(x: xPoint, y: yPoint))
        }
        
        return points
    }
    
    func getIndexOfValueFor(locationOnLayer: CGPoint) -> Int {
        let point: CGPoint? = checkIf(point: locationOnLayer, isInRange: 30)
        
        var indexOfValue : Int!
        if point != nil {
            indexOfValue = (self.points as NSArray).index(of: point!)
            
            let isFilledValue: Int = isFilled == true ? 1 : 0
            print("\(indexOfValue - isFilledValue)")
            return indexOfValue - isFilledValue
        } else {
            return Int.max
        }
    }
    
    func checkIf(point: CGPoint!,isInRange range: CGFloat) -> CGPoint? {
        
        var closestRange: CGFloat = CGFloat(Int.max)
        var resultantPoint: CGPoint?
        
        for i in 0..<self.points.count {
            let distanceBetweenBothPoints = sqrt(pow((self.points[i]).x - (point?.x)!, 2) + pow(self.points[i].y - (point?.y)!, 2))
            print("Index: \(i) .... distance: \(distanceBetweenBothPoints)")
            if range > distanceBetweenBothPoints && distanceBetweenBothPoints < closestRange {
                closestRange = distanceBetweenBothPoints
                resultantPoint = self.points[i]
            }
        }
        if closestRange != CGFloat(Int.max) {
            return resultantPoint
        } else {
            return nil
        }
    }
    
}

//MARK: -

//This layer contain all the graph(s)
class LineGraphLayer: CAShapeLayer {
    
    var verticalPadding: CGFloat = 40.0
    var horizontalPadding: CGFloat = 40.0
    var origin: CGPoint = CGPoint.init(x: 40, y: 40)
    var percentOfLineWhichShowsData: CGFloat = 0.9
    
    //The view's layer where the graphs are being made
    var parentView: UIView!
    
    //Axis values .. coordinates
    var xValues: [CGFloat] = [CGFloat]()
    var yValues: [CGFloat] = [CGFloat]()
    
    var bezierPath: UIBezierPath!
    
    var lineGraphDelegate: LineGraphProtocol?
    
    var horizontalLine: HorizontalLine!
    var verticalLine: VertialLine!
    
    //All the LineGraphChildLayer act as a single graph
    var childLayers: [LineGraphChildLayer] = [LineGraphChildLayer]()
    
    var xMin : CGFloat! = -1
    var xMax : CGFloat! = -1
    var yMin : CGFloat! = -1
    var yMax : CGFloat! = -1
    
    var isAxisDrawn: Bool = false
    
    var graphLayer: CAShapeLayer!
    var superTagLayer: CAShapeLayer!
    
    //Dynamic height is the updated height the layer has and the view should have
    var dynamicHeight: CGFloat!
    
    class func initWith(parentView: UIView) -> LineGraphLayer {
        let lineGraphLayer = LineGraphLayer()
        
        lineGraphLayer.parentView = parentView
        lineGraphLayer.frame.size = parentView.layer.frame.size
        lineGraphLayer.strokeColor = UIColor.clear.cgColor
        lineGraphLayer.fillColor = UIColor.clear.cgColor
        lineGraphLayer.masksToBounds = true
        parentView.layer.addSublayer(lineGraphLayer)
        
        //This will contain all graphs
        lineGraphLayer.graphLayer = CAShapeLayer()
        lineGraphLayer.graphLayer.masksToBounds = true
        lineGraphLayer.graphLayer.frame.origin = CGPoint(x: 0, y: 0)
        lineGraphLayer.graphLayer.frame.size = parentView.layer.frame.size
        
        lineGraphLayer.addSublayer(lineGraphLayer.graphLayer)
        
        //This will contains all the tags
        lineGraphLayer.superTagLayer = CAShapeLayer()
        lineGraphLayer.superTagLayer.frame.size = CGSize(width: parentView.layer.frame.size.width, height: 0)
        lineGraphLayer.addSublayer(lineGraphLayer.superTagLayer)
        
        let tapGesture = UITapGestureRecognizer(target: lineGraphLayer, action: #selector(LineGraphLayer.layerTapped(tapGesture:)))
        parentView.addGestureRecognizer(tapGesture)
        
        return lineGraphLayer
    }
    
    func drawAxisWith(xValues: [CGFloat], yValues: [CGFloat], xAxisName: String, yAxisName: String) {
        
        self.xValues = xValues
        self.yValues = yValues
        
        //Add vertical line and horizontal line
        verticalLine = VertialLine.init(values: yValues as NSArray, size: self.frame.size, origin: origin, withLineGraphLayer: self)
        horizontalLine = HorizontalLine.init(values: xValues as NSArray, size: self.frame.size, origin: origin, withLineGraphLayer: self)
        
        if verticalLine.oneValueDistance > horizontalLine.oneValueDistance {
            verticalLine.oneValueDistance = horizontalLine.oneValueDistance
        } else {
            horizontalLine.oneValueDistance = verticalLine.oneValueDistance
        }
        
        verticalLine.lineGraphDelegate = lineGraphDelegate
        horizontalLine.lineGraphDelegate = lineGraphDelegate
        
        verticalLine.doLayer()
        horizontalLine.doLayer()
        
        self.graphLayer.insertSublayer(verticalLine, at: 0)
        self.graphLayer.insertSublayer(horizontalLine, at: 0)
        
        isAxisDrawn = true
        
        self.graphLayer.frame.size.height = verticalLine.lineEndY + verticalPadding
        setDynamicHeight(height: verticalLine.lineEndY + verticalPadding)
        
        //Add names
        let axisNameLayer = AxisNameLayer.init(withXName: xAxisName, withYName: yAxisName, parentSize: self.superTagLayer.frame.size)
        axisNameLayer.frame.origin.x = self.superTagLayer.frame.size.width/2
        superTagLayer.frame.size.height = axisNameLayer.frame.size.height
        self.superTagLayer.insertSublayer(axisNameLayer, at: 2)
        
        self.setAffineTransform(CGAffineTransform.init(scaleX: 1, y: -1))
    }
    
    func addLayerWith(stroke:CGColor?, fillColor:CGColor?, values: [CGPoint], graphOf: String) {
        let lineGraphChildLayer: LineGraphChildLayer! = LineGraphChildLayer.init(lineGraphLayer: self, values: values, stroke: stroke, fillColor: fillColor)
        lineGraphChildLayer.frame.size = self.graphLayer.frame.size
        lineGraphChildLayer.drawGraph()
        
        let tagLayer = TagLayer.init(withName: graphOf, lineColor: stroke, parentSize: self.frame.size)
        tagLayer.frame.origin.y = CGFloat(self.childLayers.count) * tagLayer.frame.size.height
        
        var superTagLayerHeight = CGFloat(self.childLayers.count + 1) * tagLayer.frame.size.height
        
        superTagLayerHeight = superTagLayerHeight > self.superTagLayer.frame.size.height ? superTagLayerHeight: self.superTagLayer.frame.size.height
        
        let superTagLayerY = self.graphLayer.frame.size.height
        superTagLayer.frame = CGRect(x: 0, y: superTagLayerY, width: self.frame.size.width, height: superTagLayerHeight)
        superTagLayer.addSublayer(tagLayer)
        
        self.childLayers.append(lineGraphChildLayer)
        self.addSublayer(lineGraphChildLayer)
        
        setDynamicHeight(height: superTagLayer.frame.size.height + graphLayer.frame.size.height)
    }
    
    func setDynamicHeight(height: CGFloat) {
        self.dynamicHeight = height
        self.frame.size.height = height
        
        self.lineGraphDelegate?.updatedHeightFor?(lineGraphLayer: self)
    }
    
    //MARK: Gestures
    
    func layerTapped(tapGesture: UITapGestureRecognizer) {
        let location: CGPoint = tapGesture.location(in: tapGesture.view)
//        let layer: CALayer? = (tapGesture.view?.layer.hitTest(location))
        
        //Mirror location is passed in becuase the layer is actually transformed (fliped vertically) so, what appears on screen is not the reality
        let mirrorLocation = mirrorXOf(point: location, inFrameSize: self.frame.size)
        var indexesSelected: [Int] = [Int]()
        var values: [[CGPoint]] = []
        for i in 0..<self.childLayers.count {
            let childLayer: LineGraphChildLayer! = self.childLayers[i]
            indexesSelected.append(childLayer.getIndexOfValueFor(locationOnLayer: mirrorLocation))
            values.append(childLayer.values)
        }
        print("location: \(location)... mirror: \(mirrorLocation)..... selectedIndex: \(indexesSelected) size: \(self.frame.size)")
        self.lineGraphDelegate?.lineGraphTapped(atLocation: mirrorLocation, withIndexs: indexesSelected, inValues: values)
    }
    
    func mirrorXOf(point: CGPoint, inFrameSize size: CGSize) -> CGPoint {
        return CGPoint(x: point.x, y: size.height - point.y)
    }
    
}

//MARK: -

class CustomShapeLayer: CAShapeLayer {
    
    func getTextLayerWith(text: String) -> CATextLayer {
        let label = CATextLayer()
        //        label.font = UIFont(name: "Helvetica", size: 5)
        //        label.contentsScale =  UIScreen.main.scale
        label.font = 5 as CFTypeRef
        label.foregroundColor = UIColor.black.cgColor
        label.string = text
        
        label.setAffineTransform(CGAffineTransform.init(scaleX: 1, y: -1))
        
        return label
    }
    
    func getWidthOf(text: String) -> CGFloat {
        let label: UILabel! = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 5)
        
        return label.intrinsicContentSize.width
    }
    
    func getHeightOf(text: String) -> CGFloat {
        let label: UILabel! = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 5)
        
        return label.intrinsicContentSize.height
    }
    
}

//MARK: -

class TagLayer: CustomShapeLayer {
    
    class func `init`(withName name: String,lineColor: CGColor?, parentSize: CGSize) -> TagLayer {
        let tagLayer = TagLayer()
        tagLayer.frame = CGRect(x: 0, y: 0, width: parentSize.width/2, height: 20)
        tagLayer.masksToBounds = true
        
        let colorLayer = CAShapeLayer()
        colorLayer.fillColor = lineColor
        colorLayer.strokeColor = lineColor
        colorLayer.backgroundColor = lineColor
        colorLayer.frame = CGRect(x: 20, y: tagLayer.frame.height/2, width: 20, height: 2)
        colorLayer.cornerRadius = 1
        tagLayer.addSublayer(colorLayer)
        
        let textLayer = tagLayer.getTextLayerWith(text: name)
        let textX = colorLayer.frame.size.width + colorLayer.frame.origin.x + 5
        let textY = CGFloat(0)
        let textWidth = tagLayer.frame.size.width - textX - colorLayer.frame.size.width
        let textHeight = tagLayer.frame.size.height
        
        textLayer.frame = CGRect(x: textX, y: textY, width: textWidth, height: textHeight)
        tagLayer.addSublayer(textLayer)
        
        tagLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.backgroundColor = UIColor.clear.cgColor
        
        return tagLayer
    }
    
}


class AxisNameLayer: CustomShapeLayer {
    
    class func `init`(withXName xName: String, withYName yName: String, parentSize: CGSize) -> AxisNameLayer {
        let top = CGFloat(5)
        let height = CGFloat(20)
        let axisNameLayer = AxisNameLayer()
        axisNameLayer.frame = CGRect(x: 0, y: 0, width: parentSize.width/2, height: 0)
        
        let yTextLayer = axisNameLayer.getTextLayerWith(text: "Y-axis: \(yName)")
        yTextLayer.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: axisNameLayer.frame.size.width, height: height)
        axisNameLayer.addSublayer(yTextLayer)
        
        let xTextLayer = axisNameLayer.getTextLayerWith(text: "X-axis: \(xName)")
        xTextLayer.frame = CGRect(x: CGFloat(0), y: yTextLayer.frame.origin.y + yTextLayer.frame.size.height, width: axisNameLayer.frame.size.width, height: height)
        axisNameLayer.addSublayer(xTextLayer)
        
        axisNameLayer.backgroundColor = UIColor.clear.cgColor
        xTextLayer.backgroundColor = UIColor.clear.cgColor
        yTextLayer.backgroundColor = UIColor.clear.cgColor
        
        axisNameLayer.frame.size.height = yTextLayer.frame.size.height + xTextLayer.frame.size.height + top
        
        return axisNameLayer
    }
    
}

//MARK: -

class VertialLine: CustomShapeLayer {
    
    var oneValueDistance: CGFloat!
    var startPoint: CGPoint!
    var endPoint: CGPoint!
    
    var lineStartX: CGFloat!
    var lineStartY: CGFloat!
    var lineEndX: CGFloat!
    var lineEndY: CGFloat!
    
    var values : NSArray?
    var lineGraphDelegate: LineGraphProtocol?
    
    class func `init`(values: NSArray?, size: CGSize, origin: CGPoint, withLineGraphLayer lineGraphLayer: LineGraphLayer) -> VertialLine {
        let layer = VertialLine()
        
        if values?.count != 0 {
            layer.lineStartX = origin.x
            layer.lineEndX = origin.x
            layer.lineStartY = origin.y
            layer.lineEndY = origin.y + (size.width - origin.x - lineGraphLayer.horizontalPadding) // |----layer----|
            
            let lineDistance = (layer.lineEndY - layer.lineStartY) * lineGraphLayer.percentOfLineWhichShowsData
            let oneValueDistance = lineDistance/CGFloat((values?.count)!-1 >= 1 ? (values?.count)!-1: 1)
            layer.oneValueDistance = oneValueDistance
            layer.values = values
        }
        return layer
    }
    
    func doLayer() {
        let bezierPathAxis = UIBezierPath()
        
        //Create line
        bezierPathAxis.move(to: CGPoint.init(x: lineStartX, y: lineStartY))
        bezierPathAxis.addLine(to: CGPoint.init(x: lineEndX, y: lineEndY))
        bezierPathAxis.lineWidth = 2.0
        
        //Create dots
        let bezierPathDots = UIBezierPath()
        
        for i in 0..<(values?.count)! {
            let yValue = lineStartY + oneValueDistance * CGFloat(i)
            let dotPoint = CGPoint.init(x: lineStartX, y: yValue)
            bezierPathDots.move(to: dotPoint)
            bezierPathDots.addArc(withCenter: dotPoint, radius: 2, startAngle: 0, endAngle: 6, clockwise: true)
            if i == 0 {
                startPoint = dotPoint
            }
            if i == (values?.count)! - 1 {
                endPoint = dotPoint
            }
            
            let text: String = "\(lineGraphDelegate?.getValueToShowOnYaxisFor(value: values![i]) ?? values![i])"
            let decimalPlaces2 : String = CGFloat(Double(text)!).rounded(toPlaces: 2)
            let textLayer = getTextLayerWith(text: decimalPlaces2)
            textLayer.frame = CGRect(x: 0, y: yValue-10, width: lineStartX-3, height: 30)
            textLayer.alignmentMode = "right"
            addSublayer(textLayer)
        }
        
        bezierPathAxis.append(bezierPathDots)
        
        
        
        
        strokeColor = UIColor.black.cgColor
        path = bezierPathAxis.cgPath
    }
    
}

//MARK: -

class HorizontalLine: CustomShapeLayer {
    
    var oneValueDistance: CGFloat!
    var startPoint: CGPoint!
    var endPoint: CGPoint!
    
    var lineStartX: CGFloat!
    var lineStartY: CGFloat!
    var lineEndX: CGFloat!
    var lineEndY: CGFloat!
    
    var values : NSArray?
    var lineGraphDelegate: LineGraphProtocol?
    
    class func `init`(values: NSArray?, size: CGSize, origin: CGPoint, withLineGraphLayer lineGraphLayer: LineGraphLayer) -> HorizontalLine {
        let layer = HorizontalLine()
        
        if values?.count != 0 {
            
            layer.lineStartX = origin.x
            layer.lineEndX = size.width - lineGraphLayer.horizontalPadding
            layer.lineStartY = origin.y
            layer.lineEndY = origin.y
            
            let lineDistance = (layer.lineEndX - layer.lineStartX) * lineGraphLayer.percentOfLineWhichShowsData
            let oneValueDistance = lineDistance/CGFloat((values?.count)! - 1 >= 1 ? (values?.count)! - 1: 1)
            layer.oneValueDistance = oneValueDistance
            layer.values = values
        }
        return layer
    }
    
    func doLayer() {
        let bezierPathAxis = UIBezierPath()
        
        //Create line
        bezierPathAxis.move(to: CGPoint.init(x: lineStartX, y: lineStartY))
        bezierPathAxis.addLine(to: CGPoint.init(x: lineEndX, y: lineEndY))
        bezierPathAxis.lineWidth = 2.0
        
        //Create dots
        let bezierPathDots = UIBezierPath()
        
        for i in 0..<(values?.count)! {
            let xValue = lineStartX + oneValueDistance * CGFloat(i)
            let dotPoint = CGPoint.init(x: xValue, y: lineStartY)
            bezierPathDots.move(to: dotPoint)
            bezierPathDots.addArc(withCenter: dotPoint, radius: 2, startAngle: 0, endAngle: 6, clockwise: true)
            
            if i == 0 {
                startPoint = dotPoint
            }
            if i == (values?.count)! - 1 {
                endPoint = dotPoint
            }
            
            let text: String = lineGraphDelegate?.getValueToShowOnXaxisFor(value: values![i]) as! String 
            let textLayer = getTextLayerWith(text: "\(text)")
            let height: CGFloat = 30.0
            textLayer.frame = CGRect(x: xValue - self.oneValueDistance/2, y: lineStartY-height-2, width: self.oneValueDistance, height: height)
            textLayer.alignmentMode = "center"
            addSublayer(textLayer)
        }
        
        bezierPathAxis.append(bezierPathDots)
        
        strokeColor = UIColor.black.cgColor
        path = bezierPathAxis.cgPath
    }
    
}






