//
//  MainViewController.swift
//  Clicker
//
//  Created by Damir Kazbekov on 17.07.16.
//  Copyright © 2016 Damir Kazbekov. All rights reserved.
//

import UIKit
import Cartography
import Sugar
import FirebaseAuth
import FirebaseDatabase

private let finish = 10
private let leadersCountTitle = "Leaders"
private let totalScoreTitle = "Total"
private let myScoreTitle = "Your"

class MainViewController: UIViewController {
    private let ref = FIRDatabase.database().reference()
    
    private lazy var button: UIButton = {
        return UIButton().then {
            $0.setTitle("Click", forState: .Normal)
            $0.setTitleColor(.whiteColor(), forState: .Normal)
            $0.addTarget(self, action: #selector(didPressButton(_:)), forControlEvents: .TouchDown)
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.whiteColor().CGColor
            $0.layer.cornerRadius = 50
        }
    }()
    
    private lazy var myScoreLabel: UILabel = {
        return UILabel().then {
            $0.text = "\(myScoreTitle): -"
            $0.textColor = .whiteColor()
            $0.textAlignment = .Center
            $0.font = .systemFontOfSize(30)
        }
    }()
    
    private lazy var totalScoreLabel: UILabel = {
        return UILabel().then {
            $0.text = "\(totalScoreTitle): -"
            $0.textColor = .whiteColor()
            $0.textAlignment = .Center
            $0.font = .systemFontOfSize(30)
        }
    }()
    
    private lazy var leadersCountLabel: UILabel = {
        return UILabel().then {
            $0.text = "\(leadersCountTitle): -"
            $0.textColor = .whiteColor()
            $0.textAlignment = .Center
            $0.font = .systemFontOfSize(30)
        }
    }()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleClicks()
        setUpViews()
        setUpConstraints()
    }
    
    // MARK: - Action
    
    func didPressButton(sender: UIButton) {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            // TODO: - Reload the app, Check internet connection
            return
        }
        [ref.child("users/\(uid)"), ref.child("total")].enumerate().forEach{ (index, value) in
            value.runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                var click = currentData.value as? [String : AnyObject] ?? [:]
                var clicksCount = click["clicksCount"] as? Int ?? 0
                clicksCount += 1
                click["clicksCount"] = clicksCount
                if !(click["win"] as? Bool ?? false) && clicksCount >= finish && index == 0 {
                    click["win"] = true
                    self.capture()
                }
                currentData.value = click
                
                return FIRTransactionResult.successWithValue(currentData)
            }) { (error, committed, snapshot) in
                if let error = error {
                    // TODO: - Show Error
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Private
    
    private func capture() {
        ref.child("leaders").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            var leaders = currentData.value as? [String : AnyObject] ?? [:]
            var leadersCount = leaders["leadersCount"] as? Int ?? 0
            leadersCount += 1
            leaders["leadersCount"] = leadersCount
            currentData.value = leaders
            
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                // TODO: - Show Error
                print(error.localizedDescription)
            }
        }
    }
    
    private func handleClicks() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            // TODO: - Reload the app, Check internet connection
            return
        }
        ref.child("leaders").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            let click = snapshot.value as? [String : AnyObject] ?? [:]
            self.leadersCountLabel.text = "\(leadersCountTitle): \(click["leadersCount"] as? Int ?? 0)"
        })
        ref.child("total").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            let click = snapshot.value as? [String : AnyObject] ?? [:]
            self.totalScoreLabel.text = "\(totalScoreTitle): \(click["clicksCount"] as? Int ?? 0)"
        })
        ref.child("users/\(uid)").observeEventType(FIRDataEventType.Value, withBlock: { (snapshot) in
            let click = snapshot.value as? [String : AnyObject] ?? [:]
            let clicksCount = click["clicksCount"] as? Int ?? 0
            self.myScoreLabel.text = "\(myScoreTitle): \(clicksCount)"
        })
    }
    
    private func setUpViews() {
        view.backgroundColor = .blackColor()
        [leadersCountLabel, totalScoreLabel, myScoreLabel, button].forEach { view.addSubview($0) }
    }
    
    private func setUpConstraints() {
        constrain(leadersCountLabel, view) {
            $0.top == $1.top + 40
            $0.leading == $1.leading + 20
            $0.trailing == $1.trailing - 20
        }
        constrain(totalScoreLabel, leadersCountLabel) {
            $0.top == $1.bottom + 20
            $0.leading == $1.leading
            $0.trailing == $1.trailing
        }
        constrain(myScoreLabel, totalScoreLabel) {
            $0.top == $1.bottom + 20
            $0.leading == $1.leading
            $0.trailing == $1.trailing
        }
        constrain(button, view) {
            $0.bottom == $1.bottom - 40
            $0.centerX == $1.centerX
            $0.width == 100
            $0.height == 100
        }
    }
}
