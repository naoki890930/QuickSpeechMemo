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
    
    fileprivate var sections = [String]()
    fileprivate var entries = [String: [Entry]]()
    
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
                    self.setupTableData(data: entries)
                },
                onError: { error in
                    log?.error(error)
                }
            )
            .addDisposableTo(disposeBag)
    }
    
    private func setupTableData(data: [Entry]) {
        sections = [String]()
        entries = [String: [Entry]]()
        
        data.forEach { entry in
            let dateString = entry.date.format("yyyy年MM月dd日")
            if !sections.contains(dateString) { sections.append(dateString) }
            if let _ = entries[dateString] {
                entries[dateString]!.append(entry)
            } else {
                entries[dateString] = [entry]
            }
        }
        
        tableView.reloadData()
    }
}

extension ListViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[safe: section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let key = sections[safe: section], let data = entries[key] else { return 0 }
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        guard let key = sections[safe: indexPath.section],
            let data = entries[key],
            let entry = data[safe: indexPath.row] else { return cell }
        
        cell.textLabel?.text = entry.title
        cell.detailTextLabel?.text = entry.text
        
        return cell
    }
}

extension ListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let key = sections[safe: indexPath.section],
            let data = entries[key],
            let entry = data[safe: indexPath.row] else { return }
        
        let vc = EditViewController.instantiate(storyboardName: "Main")
        vc.entry = entry
        navigationController?.pushViewController(vc, animated: true)
    }
}
