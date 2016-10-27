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
import RealmSwift
import Async

class TopViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        log?.warning("didReceiveMemoryWarning")
    }
    
    // MARK: Setup
    
    private func setup() {
        addButton.rx.tap
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: EditViewController.className, sender: nil)
            })
            .addDisposableTo(disposeBag)
        
        listButton.rx.tap
            .subscribe(onNext: { _ in
                self.performSegue(withIdentifier: ListViewController.className, sender: nil)
            })
            .addDisposableTo(disposeBag)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(TopViewController.clearRealm(_:)))
        gesture.numberOfTapsRequired = 2
        titleLabel.isUserInteractionEnabled = true
        titleLabel.addGestureRecognizer(gesture)
    }
    
    func clearRealm(_ sender: UITapGestureRecognizer) {
        guard let url = Realm.Configuration.defaultConfiguration.fileURL else { return }
        do {
            try FileManager().removeItem(at: url)
            
            titleLabel.textColor = UIColor.lightGray
            Async.main(after: 1) { [weak self] in
                self?.titleLabel.textColor = UIColor.white
            }
        } catch let error {
            log?.error(error)
        }
    }
}
