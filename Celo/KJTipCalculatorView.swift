//
//  KJTipCalculatorView.swift
//  Celo
//
//  Created by Santanu Karar on 17/09/15.
//  Copyright (c) 2015 Santanu Karar. All rights reserved.
//

import UIKit

extension UIStepper
{
    // Set value if proposed new value is within minimumValue...maximumValue
    @objc(kjtc_ifInRangeSetValue:)
    func ifInRangeSetValue(_ proposedValue: NSNumber) -> Bool {
        let proposed = proposedValue.doubleValue
        if minimumValue <= proposed && proposed <= maximumValue {
            value = proposed
            return true
        }
        else {
            return false
        }
    }
}

class KJTipCalculatorView: UIView
{
    @IBOutlet weak var tfSubtotal: UITextField!
    @IBOutlet weak var tfTipPercent: UITextField!
    @IBOutlet weak var tfHeads: UITextField!
    @IBOutlet weak var stepPercentage: UIStepper!
    @IBOutlet weak var stepHeads: UIStepper!
    @IBOutlet weak var lblTip: OutputLabel!
    @IBOutlet weak var lblTotal: OutputLabel!
    @IBOutlet weak var lblSplit: OutputLabel!
    @IBOutlet weak var imgCeloIcon: UIImageView!
    @IBOutlet weak var btnHelp: UIButton!
    
    let currencyFormat: NSString = "%.2f"
    let minTipPercentage     = 1
    let defaultTipPercentage = 20
    let maxTipPercentage     = 99
    let minNumberInParty     = 1
    let defaultNumberInParty = 1
    let maxNumberInParty     = 99
    
    var integerTextFieldDelegate = NumericTextFieldDelegate(maxLength: 2)
    var subtotalTextFieldDelegate = NumericTextFieldDelegate(maxLength: 7, allowDecimal: true)
    
    func setupUI()
    {   
        /*if !ConstantsVO.isUserHelpAchieved
        {
            imgCeloIcon.isHidden = true
        }
        else
        {
            btnHelp.isUserInteractionEnabled = false
            btnHelp.isHidden = true
            if imgCeloIcon.isHidden
            {
                imgCeloIcon.isHidden = false
            }
        }*/
        
        tfSubtotal.text = ""
        tfSubtotal.delegate = subtotalTextFieldDelegate
        tfSubtotal.addTarget(self, action: #selector(KJTipCalculatorView.tfSubtotalDidChange(_:)), for: UIControlEvents.editingChanged)
        
        tfTipPercent.setTextNumericValue(defaultTipPercentage as NSNumber)
        tfTipPercent.delegate = integerTextFieldDelegate
        tfTipPercent.addTarget(self, action: #selector(KJTipCalculatorView.tfSubtotalDidChange(_:)), for: UIControlEvents.editingChanged)
        
        stepPercentage.minimumValue = Double(minTipPercentage)
        stepPercentage.maximumValue = Double(maxTipPercentage)
        stepPercentage.value = Double(defaultTipPercentage)
        
        tfHeads.setTextNumericValue(defaultNumberInParty as NSNumber)
        tfHeads.delegate = integerTextFieldDelegate
        tfHeads.addTarget(self, action: #selector(KJTipCalculatorView.tfSubtotalDidChange(_:)), for: UIControlEvents.editingChanged)
        
        stepHeads.minimumValue = Double(minNumberInParty)
        stepHeads.maximumValue = Double(maxNumberInParty)
        stepHeads.value = Double(defaultNumberInParty)
    }
    
    func dispose()
    {
        tfSubtotal.removeTarget(self, action: #selector(KJTipCalculatorView.tfSubtotalDidChange(_:)), for: UIControlEvents.editingChanged)
        tfTipPercent.removeTarget(self, action: #selector(KJTipCalculatorView.tfSubtotalDidChange(_:)), for: UIControlEvents.editingChanged)
        tfHeads.removeTarget(self, action: #selector(KJTipCalculatorView.tfSubtotalDidChange(_:)), for: UIControlEvents.editingChanged)
    }
    
    func updateOutput()
    {
        // If all text fields have valid values, then we can calculate results.
        // Otherwise, set result fields empty.
        switch (tfSubtotal.textDoubleValue(), tfTipPercent.textIntegerValue(), tfHeads.textIntegerValue())
        {
        case let (.some(subtotal), .some(tipPercentage), .some(numberInParty))
            where (subtotal > 0) && (tipPercentage > 0) && (numberInParty > 0):
            
            let calc = TipCalculation(
                subtotal: subtotal,
                tipPercentage: tipPercentage,
                numberInParty: numberInParty)
            
            setText(lblTip, currencyValue: calc.tip)
            setText(lblTotal, currencyValue: calc.total)
            setText(lblSplit, currencyValue: calc.perPerson)
            
        default:
            lblTip.text = "0"
            lblTotal.text = "0"
            lblSplit.text = "0"
        }
    }
    
    func setText(_ textSettable: TextSettable, currencyValue: Double)
    {
        setNumericValueForText(textSettable, value: currencyValue as NSNumber, doubleFormat: currencyFormat);
    }
    
    func tfSubtotalDidChange(_ sender: UITextField)
    {
        if case (tfTipPercent, let value) = (sender, sender.textIntegerValue())
        {
            _ = stepPercentage.ifInRangeSetValue(value! as NSNumber)
        }
        
        if case (tfHeads, let value) = (sender, sender.textIntegerValue())
        {
            _ = stepHeads.ifInRangeSetValue(value! as NSNumber)
        }
        
        updateOutput()
    }
    
    @IBAction func onClear(_ sender: AnyObject)
    {
        tfSubtotal.text = ""
        updateOutput()
    }
    
    @IBAction func onTipStepChanged(_ sender: UIStepper)
    {
        tfTipPercent.setTextNumericValue(sender.value as NSNumber)
        updateOutput()
    }
    
    @IBAction func onHeadStepChanged(_ sender: UIStepper)
    {
        tfHeads.setTextNumericValue(sender.value as NSNumber)
        updateOutput()
    }
    
    @IBAction func onHelp(_ sender: AnyObject)
    {
        /*let help = Bundle.main.loadNibNamed("CeloHelpView", owner: self, options: nil)![0] as! CeloHelpView
        DispatchQueue.main.async
        {
            self.addSubview(help)
            help.show()
        }*/
    }
}

//--------------------------------------------------------------------------
//
//  IMPLEMENTATION
//  @UITextField
//
//--------------------------------------------------------------------------

extension KJTipCalculatorView: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
        return false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        super.touchesBegan(touches, with: event)
        self.endEditing(true)
    }
}
