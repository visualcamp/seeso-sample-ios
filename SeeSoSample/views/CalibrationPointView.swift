//
//  CalibrationPointView.swift
//  SeeSoSample
//
//  Created by VisualCamp on 2020/06/12.
//  Copyright © 2020 VisaulCamp. All rights reserved.
//

import UIKit

class CalibrationPointView : UILabel {
    override init(frame: CGRect) {
        super.init(frame : frame)
        layer.cornerRadius = frame.width/2
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 2
        textAlignment = .center
        textColor = .red
        adjustsFontSizeToFitWidth = true
        text = "0%"
    }
    
    func setProgress(progress : Double){
        let percent = Int(progress * 100)
        DispatchQueue.main.async {
            self.text = "\(percent)%"
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
