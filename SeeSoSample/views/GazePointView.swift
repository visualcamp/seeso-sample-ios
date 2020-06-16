//
//  GazePointView.swift
//  SeeSoSample
//
//  Created by VisualCamp on 2020/06/12.
//  Copyright © 2020 VisaulCamp. All rights reserved.
//

import UIKit
import Foundation

class GazePointView : UIView {
    
    let verticalLine : UIView =  UIView()
    let horizontalLine : UIView = UIView()
    let pointView : UIView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        initSubviews()
        isUserInteractionEnabled = false
    }
    
    private func initSubviews(){
        verticalLine.frame.size = CGSize(width: 2.5, height: frame.height)
        verticalLine.backgroundColor = .red
        horizontalLine.frame.size = CGSize(width: frame.width, height: 2.5)
        horizontalLine.backgroundColor = .red
        pointView.frame.size = CGSize(width: 30, height: 30)
        pointView.layer.cornerRadius = 15
        pointView.backgroundColor = .red
        
        self.addSubview(verticalLine)
        self.addSubview(horizontalLine)
        self.addSubview(pointView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func moveView(x: Double, y: Double){
        let centerPoint = CGPoint(x: x, y: y)
        DispatchQueue.main.async {
            self.pointView.center = centerPoint
            self.verticalLine.frame.origin.x = centerPoint.x
            self.horizontalLine.frame.origin.y = centerPoint.y
        }
    }
    
    
}
