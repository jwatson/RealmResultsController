//
//  File.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 6/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class CacheDelegateMock: RealmResultsCacheDelegate {
    
    static let sharedInstance = CacheDelegateMock()
    
    var index = -1
    var oldIndexPath: NSIndexPath?
    var indexPath: NSIndexPath?
    var object: Object?
    
    func reset() {
        index = -1
        oldIndexPath = nil
        indexPath = nil
        object = nil
    }
    
    func didInsertSection<T: Object>(section: Section<T>, index: Int) {
        self.index = index
    }
    
    func didDeleteSection<T: Object>(section: Section<T>, index: Int) {
        self.index = index
    }
    
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath) {
        self.object = object as Object
        self.indexPath = indexPath
    }
    func didDelete<T: Object>(object: T, indexPath: NSIndexPath) {
        self.indexPath = indexPath
        self.object = object
    }
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        self.object = object as Object
        self.oldIndexPath = oldIndexPath
        self.indexPath = newIndexPath
    }
}



class CacheSpec: QuickSpec {
    
    override func spec() {
        
        var cache: RealmResultsCache<Task>!
        var initialObjects: [Task]!
        var request: RealmRequest<Task>!
        var realm: Realm!
        var predicate: NSPredicate!
        var sortDescriptors: [SortDescriptor]!
        var resolvedTasks: [Task]!
        var notResolvedTasks: [Task]!
        
        func initWithKeypath() {
            predicate = NSPredicate(format: "id < %d", 50)
            sortDescriptors = [SortDescriptor(property: "name", ascending: true)]
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors)
            initialObjects = request.execute().toArray().sort { $0.name < $1.name }
            resolvedTasks = initialObjects.filter { $0.resolved }
            notResolvedTasks = initialObjects.filter { !$0.resolved }
            cache = RealmResultsCache<Task>(request: request, sectionKeyPath: "resolved")
            cache.populateSections(initialObjects)
            cache.delegate = CacheDelegateMock.sharedInstance
        }
        
        func initWithoutKeypath() {
            predicate = NSPredicate(format: "id < %d", 50)
            sortDescriptors = [SortDescriptor(property: "name", ascending: true)]
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors)
            initialObjects = request.execute().toArray()
            resolvedTasks = initialObjects.filter { $0.resolved }
            notResolvedTasks = initialObjects.filter { !$0.resolved }
            cache = RealmResultsCache<Task>(request: request, sectionKeyPath: "")
            cache.populateSections(initialObjects)
            cache.delegate = CacheDelegateMock.sharedInstance
        }
        
        // Init with only one object with ID = 0
        func initEmpty() {
            predicate = NSPredicate(format: "id < %d", 1)
            sortDescriptors = [SortDescriptor(property: "name", ascending: true)]
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors)
            initialObjects = request.execute().toArray().sort { $0.name < $1.name }
            resolvedTasks = initialObjects.filter { $0.resolved }
            notResolvedTasks = initialObjects.filter { !$0.resolved }
            cache = RealmResultsCache<Task>(request: request, sectionKeyPath: "resolved")
            cache.populateSections(initialObjects)
            cache.delegate = CacheDelegateMock.sharedInstance
        }
        
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
        }
        
        describe("init") {
            context("request has no keypath") {
                beforeEach {
                    initWithoutKeypath()
                }
                it("inserts the received objects in one section") {
                    expect(cache.sections.count) == 1
                }
                it("section has all the objects") {
                    expect(cache.sections.first!.objects.count) == initialObjects.count
                }
            }
            
            context("request has keypath") {
                beforeEach {
                    initWithKeypath()
                }
                it("inserts the objects in 2 sections") {
                    expect(cache.sections.count) == 2
                }
            }
        }
        
        beforeEach {
            CacheDelegateMock.sharedInstance.reset()
        }
        
        describe("resetCache") {
            context("with empty array") {
                beforeEach() {
                    cache.reset([])
                }
                it("removes all sections") {
                    expect(cache.sections.count) == 0
                }
            }
            context("with a new array") {
                var newArray: [Task] = []

                it("beforeAll") {
                    let task1 = Task()
                    task1.id = -5
                    task1.resolved = false
                    
                    let task2 = Task()
                    task2.id = -6
                    task2.resolved = true
                    newArray.append(task1)
                    newArray.append(task2)
                    cache.reset(newArray)
                }
                
                it("has two sections") {
                    expect(cache.sections.count) == 2
                }
                it("section 1 has one item") {
                    expect(cache.sections.first!.objects.count) == 1
                }
                it("section 2 has one item") {
                    expect(cache.sections.last!.objects.count) == 1
                }
            }
        }
        
        describe("insert") {
            context("with section keypath") {
                var newTask: Task!
                var cacheIndexPath: NSIndexPath!
                var memoryIndex: Int!
                var object: Object!
                var resolvedTasksCopy: [Task]!

                it("beforeAll") {
                    //create and insert new item in cache
                    initWithKeypath()
                    
                    newTask = Task()
                    newTask.id = -1
                    newTask.name = "ccbbaa"
                    newTask.resolved = true
                    cache.insert([newTask])
                    
                    //replicate the behaviour (adding + sorting) in a copy array
                    resolvedTasksCopy = resolvedTasks
                    resolvedTasksCopy.append(newTask)
                    resolvedTasksCopy.sortInPlace {$0.name < $1.name}
                    memoryIndex = resolvedTasksCopy.indexOf { $0 == newTask }
                    
                    //Get the values from the delegate
                    cacheIndexPath = CacheDelegateMock.sharedInstance.indexPath
                    object = CacheDelegateMock.sharedInstance.object
                }
                it("indexPath is not nil") {
                    expect(cacheIndexPath).toNot(beNil())
                }
                it("indexpath.row is ordered") {
                    expect(cacheIndexPath.row) == memoryIndex
                }
                it("the received object is the same than inserted") {
                    expect(object) === newTask
                }
                it("section is resolved one") {
                    let section = cache.sections[cacheIndexPath.section]
                    expect(section.keyPath) == "1" //like this because its an optional boolean transformed to string
                }
                it("remove from cache") {
                    cache.delete([newTask])
                }
            }
            
            context("without section keypath") {
                var newTask: Task!
                var cacheIndexPath: NSIndexPath!
                var memoryIndex: Int!
                var object: Object!
                var tasksCopy: [Task]!
                
                it("beforeAll") {
                    //create and insert new item in cache
                    initWithoutKeypath()
                    newTask = Task()
                    newTask.id = -1
                    newTask.name = "ccbbaa"
                    newTask.resolved = true
                    cache.insert([newTask])
                    
                    //replicate the behaviour (adding + sorting) in a copy array
                    tasksCopy = initialObjects
                    tasksCopy.append(newTask)
                    tasksCopy.sortInPlace {$0.name < $1.name}
                    memoryIndex = tasksCopy.indexOf { $0 == newTask }
                    
                    //Get the values from the delegate
                    cacheIndexPath = CacheDelegateMock.sharedInstance.indexPath
                    object = CacheDelegateMock.sharedInstance.object
                }
                it("indexPath is not nil") {
                    expect(cacheIndexPath).toNot(beNil())
                }
                it("indexpath.row is ordered") {
                    expect(cacheIndexPath.row) == memoryIndex
                }
                it("the received object is the same than inserted") {
                    expect(object) === newTask
                }
                it("section is resolved one") {
                    let section = cache.sections[cacheIndexPath.section]
                    expect(section.keyPath) == cache.defaultKeyPathValue
                }
                it("remove from cache") {
                    cache.delete([newTask])
                }
                
            }
        }
        
        describe("delete") {
            context("object was in cache") {
                
                var object: Object!
                var indexPath: NSIndexPath!
                it("beforeAll") {
                    initWithoutKeypath()

                    cache.delete([getMirror(initialObjects[10])])
                    cache.insert([]) //call insert to commit the changes!
                    object = CacheDelegateMock.sharedInstance.object
                    indexPath = CacheDelegateMock.sharedInstance.indexPath
                }
                it("returns not nil") {
                    expect(object).toNot(beNil())
                }
                it("returns the index of the deleted object") {
                    expect(indexPath.row) == 10
                }
                it("section has one less item") {
                    expect(cache.sections[indexPath.section].objects.count) == initialObjects.count - 1
                }
                it("restore the object") {
                    cache.insert([initialObjects[10]])
                }
            }
            
            context("object was not in cache") {
                var object: Object?
                var indexPath: NSIndexPath?
                var newTask: Task!
                it("beforeAll") {
                    initWithoutKeypath()
                    newTask = Task()
                    newTask.id = 1500
                    
                    cache.delete([newTask])
                    object = CacheDelegateMock.sharedInstance.object
                    indexPath = CacheDelegateMock.sharedInstance.indexPath
                }
                it("returns the nil because no object was deleted") {
                    expect(object).to(beNil())
                }
                it("returns the index of the deleted object") {
                    expect(indexPath).to(beNil())
                }
                it("restore the object") {
                    cache.insert([initialObjects[10]])
                }
            }
            
            context("delete last object of section") {
                var object: Object?
                var indexPath: NSIndexPath?
                var newTask: Task!
                var deletedSection: Int = -1
                it("beforeAll") {
                    initEmpty()
                    newTask = Task()
                    newTask.id = 0
                    
                    cache.delete([newTask])
                    cache.insert([]) // call insert to commit the changes!
                    object = CacheDelegateMock.sharedInstance.object
                    indexPath = CacheDelegateMock.sharedInstance.indexPath
                    deletedSection = CacheDelegateMock.sharedInstance.index
                }
                it("returns object") {
                    expect(object) == object
                }
                it("deleted section at corret index") {
                    expect(deletedSection) == 0
                }
                it("returns the index of the deleted object") {
                    expect(indexPath!.row) == 0
                }
                it("section has been deleted") {
                    expect(cache.sections.count) == 0
                }
            }
        }
        
        describe("update") {
            context("an object that is already in cache (without section or position change)") {
                var object: Object!
                var indexPath: NSIndexPath?
                var oldIndexPath: NSIndexPath?
                it("beforeAll") {
                    initWithKeypath()
                    cache.update([resolvedTasks[5]])
                    object = CacheDelegateMock.sharedInstance.object
                    indexPath = CacheDelegateMock.sharedInstance.indexPath
                    oldIndexPath = CacheDelegateMock.sharedInstance.oldIndexPath
                }
                it("returns the updated object") {
                    expect(object) === resolvedTasks[5]
                }
                it("indexPath and oldIndexPath are the same") {
                    expect(indexPath!) == oldIndexPath!
                }
                it("the object didn't change order") {
                    expect(indexPath!.row) == 5
                }
            }
            
            
            context("an object that it is in cache with section change") {
                var object: Object!
                var indexPath: NSIndexPath?
                var oldIndexPath: NSIndexPath?
                var myTask: Task!
                var notResolvedTasksCopy: [Task]!
                var memoryIndex: Int!
                it("beforeAll") {
                    initWithKeypath()
                    myTask = resolvedTasks[5]
                    try! realm.write {
                        myTask.resolved = false
                    }
                    notResolvedTasksCopy = notResolvedTasks
                    notResolvedTasksCopy.append(myTask)
                    notResolvedTasksCopy.sortInPlace {$0.name < $1.name}
                    memoryIndex = notResolvedTasksCopy.indexOf { $0 == myTask }
                    cache.delete([myTask]) // an update changing sections is actually a delete and insert
                    cache.insert([myTask])
                    object = CacheDelegateMock.sharedInstance.object
                    indexPath = CacheDelegateMock.sharedInstance.indexPath
                    oldIndexPath = CacheDelegateMock.sharedInstance.oldIndexPath
                }
                it("returns the updated object") {
                    expect(object) === myTask
                }
                it("indexPath and oldIndexPath have different sections") {
                    expect(indexPath?.section) != oldIndexPath?.section
                }
                it("the object is inserted in the new section in the correct position") {
                    expect(indexPath!.row) == memoryIndex
                }
                it("original section has one less element") {
                    expect(cache.sections[oldIndexPath!.section].objects.count) == resolvedTasks.count - 1
                }
                it("new section has one more element") {
                    expect(cache.sections[indexPath!.section].objects.count) == notResolvedTasks.count + 1
                }
                it("restoreIt!") {
                    try! realm.write {
                        myTask.resolved = true
                    }
                }
            }
            
            context("an object that is not in the cache (insertion)") {
                var object: Object!
                var indexPath: NSIndexPath?
                var oldIndexPath: NSIndexPath?
                var myTask: Task!
                it("beforeAll") {
                    initWithKeypath()
                    myTask = Task()
                    myTask.resolved = true
                    myTask.id = -3
                    cache.update([myTask])
                    object = CacheDelegateMock.sharedInstance.object
                    indexPath = CacheDelegateMock.sharedInstance.indexPath
                    oldIndexPath = CacheDelegateMock.sharedInstance.oldIndexPath
                }
                it("returns the updated object") {
                    expect(object) === myTask
                }
                it("it is inserted in the correct section") {
                    let section = cache.sections[indexPath!.section]
                    expect(section.keyPath) == "1" //like this because its an optional boolean transformed to string
                }
                it("oldIndexPath is nil") {
                    expect(oldIndexPath).to(beNil())
                }
            }
        }
        describe("updateType:(object:T)") {
            var type: RealmCacheUpdateType!
            context("the object is not in the cache") {
                beforeEach {
                    initWithKeypath()
                    let task = Task()
                    task.id = -12314
                    type = cache.updateType(task)
                }
                it("returns type .Insert") {
                    expect(type) == RealmCacheUpdateType.Insert
                }
            }
            
            context("the object is in the cache and won't change sections") {
                beforeEach {
                    initWithKeypath()
                    let task = resolvedTasks[0]
                    type = cache.updateType(task)
                }
                it("returns type .Insert") {
                    expect(type) == RealmCacheUpdateType.Update
                }
            }
            
            context("the object is in the cache and will change sections") {
                beforeEach {
                    initWithKeypath()
                    let task = Task()
                    task.id = resolvedTasks[0].id
                    task.resolved = false
                    type = cache.updateType(task)
                }
                it("returns type .Insert") {
                    expect(type) == RealmCacheUpdateType.Move
                }
            }
           
        }
        describe("keyPathForObject") {
            context("in background") {
                var keyPath: String?
                beforeEach {
                    initWithKeypath()
                    waitUntil(timeout: 2) { done in
                        let queue = dispatch_queue_create("lock", DISPATCH_QUEUE_SERIAL)
                        dispatch_async(queue) {
                            let task = Task()
                            task.id = 1
                            keyPath = cache.keyPathForObject(task)
                        }
                        while keyPath != nil {}
                        done()
                    }
                }
                it("executes in main thread at the end and works") {
                    expect(keyPath).toNot(beNil())
                }
            }
            
            context("without keypath") {
                var keyPath: String?
                beforeEach {
                    initWithoutKeypath()
                    let task = Task()
                    task.id = 1
                    keyPath = cache.keyPathForObject(task)
                }
                it("returns the default keypath") {
                    expect(keyPath) == "default"
                }
            }
        }
    }
}

