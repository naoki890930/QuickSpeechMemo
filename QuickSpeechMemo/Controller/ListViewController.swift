//
//  ListViewController.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/24/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import UIKit
import RxSwift

class ListViewController: UIViewController {
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var data = [Entry]()
    
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchList()
    }
    
    private func fetchList() {
        EntryInterface.rx.findAll()
            .subscribe(
                onNext: { entries in
                    self.data = entries
                    self.tableView.reloadData()
                },
                onError: { error in
                    log?.error(error)
                }
            )
            .addDisposableTo(disposeBag)
    }
}

extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        guard let entry = data[safe: indexPath.row] else { return cell }
        
        cell.textLabel?.text = entry.title
        cell.detailTextLabel?.text = entry.text
        
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let entry = data[safe: indexPath.row] else { return }
        let vc = EditViewController.instantiate(storyboardName: "Main")
        vc.entry = entry
        navigationController?.pushViewController(vc, animated: true)
    }
}
