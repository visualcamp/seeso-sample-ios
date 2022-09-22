//
//  UserStatusLabel.swift
//  SeeSoSample
//
//  Created by david on 2021/05/25.
//  Copyright © 2021 VisualCamp. All rights reserved.
//

import UIKit
import SeeSo

class UserStatusLabel : UIView {
  let attentionLabel : UILabel = UILabel()
  let blinkLabel : UILabel = UILabel()
  let drowsinessLabel : UILabel = UILabel()
  
  var lastDrowsiness : Bool = false
  var lastBlink : Bool = false
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    
  }
  
  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    activateSubView()
  }
  
  func activateSubView(){
    initLabels()
    setLabelTextParameters()
    attentionLabel.text = "attention : None"
    blinkLabel.text = "blink : None"
    drowsinessLabel.text = "drowsiness : None"
  }
  
  
  func initLabels(){
    self.addSubview(attentionLabel)
    self.addSubview(blinkLabel)
    self.addSubview(drowsinessLabel)
    attentionLabel.translatesAutoresizingMaskIntoConstraints = false
    let attentionConstraints : [NSLayoutConstraint] =  [attentionLabel.widthAnchor.constraint(equalTo: self.widthAnchor), attentionLabel.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.33), attentionLabel.topAnchor.constraint(equalTo: self.topAnchor), attentionLabel.leftAnchor.constraint(equalTo: self.leftAnchor)]
    
    blinkLabel.translatesAutoresizingMaskIntoConstraints = false
    let blinkConstraints : [NSLayoutConstraint] =  [blinkLabel.widthAnchor.constraint(equalTo: self.widthAnchor), blinkLabel.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.33), blinkLabel.topAnchor.constraint(equalTo: self.attentionLabel.bottomAnchor), blinkLabel.leftAnchor.constraint(equalTo: self.leftAnchor)]
    
    drowsinessLabel.translatesAutoresizingMaskIntoConstraints = false
    let drowsinessConstraints : [NSLayoutConstraint] =  [drowsinessLabel.widthAnchor.constraint(equalTo: self.widthAnchor), drowsinessLabel.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: 0.33), drowsinessLabel.topAnchor.constraint(equalTo: self.blinkLabel.bottomAnchor), drowsinessLabel.leftAnchor.constraint(equalTo: self.leftAnchor)]
    for subConstraints in [attentionConstraints, blinkConstraints, drowsinessConstraints]{
      for constraint in subConstraints {
        constraint.isActive = true
      }
    }
  }
  
  func setLabelTextParameters(){
    for label in [attentionLabel, blinkLabel, drowsinessLabel] {
      label.textAlignment = .center
      label.textColor = .blue
      label.adjustsFontSizeToFitWidth = true
      label.lineBreakMode = .byWordWrapping
    }
  }
  
  
  func setLabelText(attentionText : String? = nil, blinkText : String? = nil, drowsinessText : String? = nil) {
    if let attention = attentionText {
      DispatchQueue.main.async {
        self.attentionLabel.text = "attention : \(attention)"
      }
    }
    
    if let blink = blinkText {
      DispatchQueue.main.async {
        self.blinkLabel.text = "blink : \(blink)"
      }
      
    }
    
    if let drowsiness = drowsinessText {
      DispatchQueue.main.async {
        self.drowsinessLabel.text = "drowsiness : \(drowsiness)"
      }
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension UserStatusLabel : UserStatusDelegate {
  
  func onAttention(timestampBegin: Int, timestampEnd: Int, score: Double) {
    self.setLabelText(attentionText: String(Double(round(1000 * score)/1000)))
    print("\(#function) \(timestampBegin) ~ \(timestampEnd) : \(score)")
  }
  func onBlink(timestamp: Int, isBlinkLeft: Bool, isBlinkRight: Bool, isBlink: Bool, leftOpenness: Double, rightOpenness: Double) {
    if lastBlink != isBlink || self.blinkLabel.text == nil || self.blinkLabel.text!.count <= 0 {
      self.setLabelText(blinkText: String(isBlink))
    }
    lastBlink = isBlink
  }
  
  func onDrowsiness(timestamp: Int, isDrowsiness: Bool) {
    if lastDrowsiness != isDrowsiness || self.drowsinessLabel.text == nil || self.drowsinessLabel.text!.count <= 0 {
      self.setLabelText(drowsinessText: String(isDrowsiness))
    }
    lastDrowsiness = isDrowsiness
  }
}
