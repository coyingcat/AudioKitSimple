// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/



import UIKit

/// Displays the values in the table into a nice graph
public class TableView: UIView {

    var table: Table
    var absmax: Double = 1.0

    /// Initialize the table view
    public init(_ table: Table, frame: CGRect = CGRect(x: 0, y: 0, width: 440, height: 150)) {
        self.table = table
        super.init(frame: frame)
        let max = Double(table.max() ?? 1.0)
        let min = Double(table.min() ?? -1.0)
        absmax = [max, abs(min)].max() ?? 1.0
    }

    /// Required initializer
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    /*
    /// Draw the table view
    
    
    public override func draw(_ rect: CGRect) {

        let width = Double(frame.width)
        let height = Double(frame.height) / 2.0
        let padding = 0.9

        let border = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        let bgcolor = UIColor.yellow
        bgcolor.setFill()
        border.fill()
        UIColor.black.setStroke()
        border.lineWidth = 1
        border.stroke()

        let midline = UIBezierPath()
        midline.move(to: CGPoint(x: 0, y: frame.height / 2))
        midline.addLine(to: CGPoint(x: frame.width, y: frame.height / 2))
        UIColor.black.setStroke()
        midline.lineWidth = 1
        midline.stroke()

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0.0, y: (1.0 - Double(table[0]) / absmax) * height))
        print(table.count)
        
      // let cnt = min(table.count, 175000)
      //  let offset = 50000
        
        
      // let cnt = min(table.count, 100000)
      //  let offset = 500
        
     //   let cnt = min(table.count, 375)
      //  let offset = 50000
        
        let cnt = table.count
        let offset = 0
        for index in 1..<cnt {
            let xPoint = Double(index) / Double(cnt) * width
            let idx = offset + index
            let yPoint = (1.0 - Double(table[idx]) / absmax * padding) * height

            bezierPath.addLine(to: CGPoint(x: xPoint, y: yPoint))
        }

        bezierPath.addLine(to: CGPoint(x: Double(frame.width), y: (1.0 - Double(table[0]) / absmax * padding) * height))

        UIColor.green.setStroke()
        bezierPath.lineWidth = 1
        bezierPath.stroke()
    }
    
    */
    
    
    
    public override func draw(_ rect: CGRect) {

        let width = Double(frame.width)
        let height = Double(frame.height) / 2.0
        let padding = 0.9

        let border = UIBezierPath(rect: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        let bgcolor = UIColor.black
        bgcolor.setFill()
        border.fill()
        UIColor.black.setStroke()
        border.lineWidth = 1
        border.stroke()

        let midline = UIBezierPath()
        midline.move(to: CGPoint(x: 0, y: frame.height / 2))
        midline.addLine(to: CGPoint(x: frame.width, y: frame.height / 2))
        UIColor.black.setStroke()
        midline.lineWidth = 1
        midline.stroke()

        let bezierPath = UIBezierPath()
        bezierPath.move(to: CGPoint(x: 0.0, y: (1.0 - Double(table[0]) / absmax) * height))

        for index in 1..<table.count {

            let xPoint = Double(index) / Double(table.count) * width
            if xPoint < 1{
               // print(index)
            }
            let yPoint = (1.0 - Double(table[index]) / absmax * padding) * height

            bezierPath.addLine(to: CGPoint(x: xPoint, y: yPoint))
        }

        bezierPath.addLine(to: CGPoint(x: Double(frame.width), y: (1.0 - Double(table[0]) / absmax * padding) * height))

        UIColor.green.setStroke()
        bezierPath.lineWidth = 1
        bezierPath.stroke()
    }
}

