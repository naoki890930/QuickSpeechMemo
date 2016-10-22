//
//  TopViewController.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/22/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class TopViewController: UIViewController {
    
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var listButton: UIButton!

    private var disposeBag = DisposeBag()
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log?.warning("didReceiveMemoryWarning")
    }
    
    // MARK: Setup
    
    private func setup() {
        addButton.rx.tap
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: EditViewController.className, sender: self)
            })
            .addDisposableTo(disposeBag)
    }
}

