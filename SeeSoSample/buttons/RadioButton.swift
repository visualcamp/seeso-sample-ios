//
//  RadioButton.swift
//  SeeSoSample
//
//  Created by VisualCamp on 2020/06/15.
//  Copyright © 2020 VisaulCamp. All rights reserved.
//

import UIKit

class RadioButton: UIButton {
    var alternateButton:Array<RadioButton>?

    override func awakeFromNib() {
        self.setTitleColor(.green, for: .selected)
        self.setTitleColor(.gray, for: .normal)
        self.setTitleColor(.darkGray, for: .disabled)
    }

    func unselectAlternateButtons() {
        if alternateButton != nil {
            self.isSelected = true

            for aButton:RadioButton in alternateButton! {
                aButton.isSelected = false
            }
        } else {
            toggleButton()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        unselectAlternateButtons()
        super.touchesBegan(touches, with: event)
    }

    func toggleButton() {
        self.isSelected = !isSelected
    }

    override var isSelected: Bool {
        didSet {
        }
    }
}
