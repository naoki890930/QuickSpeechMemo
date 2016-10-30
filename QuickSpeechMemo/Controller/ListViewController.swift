//
//  ListViewController.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/24/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import UIKit
import RxSwift
import MapKit
import CoreLocation
import SwiftLocation

class ListViewController: UIViewController {
    
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    fileprivate var entryData = Variable([Entry]())
    fileprivate var sections = [String]()
    fileprivate var entries = [String: [Entry]]()
    
    private var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSegmentControl()
        setupTable()
        setupMap()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchList()
    }
    
    // MARK: Setup
    
    private func setupSegmentControl () {
        segmentControl.rx.controlEvent(.valueChanged)
            .asObservable()
            .subscribe(onNext: {
                let enableMap = self.segmentControl.selectedSegmentIndex == 1
                self.tableView.isHidden = enableMap
                self.mapView.isHidden = !enableMap
            })
            .addDisposableTo(disposeBag)
    }
    
    private func setupTable() {
        entryData.asObservable()
            .shareReplayLatestWhileConnected()
            .skip(1)
            .subscribe(onNext: { data in
                self.setupTableData(data: data)
                self.tableView.reloadData()
            })
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
    }
    
    private func setupMap() {
        entryData.asObservable()
            .shareReplayLatestWhileConnected()
            .skip(1)
            .subscribe(onNext: { data in
                data.enumerated().forEach { index, entry in
                    guard let latitude = entry.latitude.value,
                        let longitude = entry.longitude.value else { return }
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude)
                    annotation.title = entry.title
                    annotation.subtitle = entry.text
                    annotation.accessibilityValue = index.description
                    self.mapView.addAnnotation(annotation)
                }
            })
            .addDisposableTo(disposeBag)
        
        setupMapWithUserLocation()
    }
    
    private func setupMapWithUserLocation() {
        Location.rxGetLocation(withAccuracy: .block)
            .subscribe(onNext: { location in
                self.setMap(coordinate: location.coordinate)
            })
            .addDisposableTo(disposeBag)
    }
    
    private func setMap(coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpanMake(0.1, 0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        mapView.setRegion(region, animated: false)
    }
    
    // MARK: Access DB
    
    private func fetchList() {
        EntryInterface.rx.findAll()
            .subscribe(
                onNext: { entries in
                    self.entryData.value = entries
                },
                onError: { error in
                    log?.error(error)
                }
            )
            .addDisposableTo(disposeBag)
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

extension ListViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let pointAnnotation = annotation as? MKPointAnnotation,
            let identifier = pointAnnotation.accessibilityValue else { return nil }
        
        var view: MKAnnotationView
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) {
            view = annotationView
        } else {
            view = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: identifier)
        }
        
        let button = UIButton(type: .detailDisclosure)
        view.rightCalloutAccessoryView = button
        view.canShowCallout = true
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let identifier = view.reuseIdentifier,
            let index = Int(identifier),
            let entry = entryData.value[safe: index] else { return }
        
        let vc = EditViewController.instantiate(storyboardName: "Main")
        vc.entry = entry
        navigationController?.pushViewController(vc, animated: true)
    }
}
