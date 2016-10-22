//
//  Entry.swift
//  QuickSpeechMemo
//
//  Created by Naoki Nishiya on 10/24/16.
//  Copyright © 2016 Naoki Nishiyama. All rights reserved.
//

import Foundation
import RealmSwift
import RxSwift

class Entry: Object {
    dynamic var text = ""
    dynamic var date = Date()
    let latitude = RealmOptional<Float>()
    let longitude = RealmOptional<Float>()
}

struct EntryInterface {
    
    struct Reactive {
        func findAll() -> Observable<[Entry]> {
            return Observable<[Entry]>.create { observer in
                do {
                    let data = try EntryInterface.findAll()
                    observer.onNext(data)
                    observer.onCompleted()
                } catch let error {
                    observer.onError(error)
                }
                
                return Disposables.create()
            }
        }
        
        func save(text: String, date: Date = Date(), latitude: Float? = nil, longitude: Float? = nil) -> Observable<Void> {
            return Observable<Void>.create { observer in
                do {
                    try EntryInterface.save(text: text, date: date, latitude: latitude, longitude: longitude)
                    observer.onNext()
                    observer.onCompleted()
                } catch let error {
                    observer.onError(error)
                }
                
                return Disposables.create()
            }
        }
        
        func update(object: Entry, text: String) -> Observable<Void> {
            return Observable<Void>.create { observer in
                do {
                    try EntryInterface.update(object: object, text: text)
                    observer.onNext()
                    observer.onCompleted()
                } catch let error {
                    observer.onError(error)
                }
                
                return Disposables.create()
            }
        }
        
        func delete(object: Entry) -> Observable<Void> {
            return Observable<Void>.create { observer in
                do {
                    try EntryInterface.delete(object: object)
                    observer.onNext()
                    observer.onCompleted()
                } catch let error {
                    observer.onError(error)
                }
                
                return Disposables.create()
            }
        }
        
    }
    
    static let rx = Reactive()
    
    static func findAll() throws -> [Entry] {
        let realm = try Realm()
        return realm.objects(Entry.self).sorted(byProperty: "date").map { $0 }
    }
    
    static func save(text: String, date: Date = Date(), latitude: Float? = nil, longitude: Float? = nil) throws {
        let object = Entry()
        object.text = text
        object.date = date
        object.latitude.value = latitude
        object.longitude.value = longitude
        
        let realm = try Realm()
        try realm.write {
            realm.add(object)
        }
    }
    
    static func update(object: Entry, text: String) throws {
        let realm = try Realm()
        try realm.write {
            object.text = text
        }
    }
    
    static func delete(object: Entry) throws {
        let realm = try Realm()
        try realm.write {
            realm.delete(object)
        }
    }
}
