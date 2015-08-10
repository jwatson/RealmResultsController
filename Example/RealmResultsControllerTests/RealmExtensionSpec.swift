//
//  RealmExtensionSpec.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class Dummy: Object {
    dynamic var id: Int = 0
}


class RealmExtensionSpec: QuickSpec {
    
    func cleanLoggers() {
        RealmNotification.sharedInstance.loggers = []
    }
    
    override func spec() {
        
        var realm: Realm!
        var taskToTest: Task!
        var manager: RealmNotification!
        var myTask: Task!

        beforeSuite {
            manager = RealmNotification.sharedInstance
            realm = Realm(inMemoryIdentifier: "testingRealm")
            taskToTest = Task()
            taskToTest.id = 1500
            taskToTest.name = "testingName1"
            realm.write {
                realm.add(taskToTest)
            }
            
            myTask = Task()
            myTask.id = 123456
            myTask.name = "23424"
//            print((myTask.dynamicType as Object.Type).className())
            realm.write {
                realm.addNotified(myTask)
                //                        realm.addNotified(object, update: true)
            }
        }
    
        describe("addNotified (array)") {
            it("task is inserted") {
                expect(taskToTest.realm).toNot(beNil())
            }
            it("crates a logger for this realm") {
                expect(RealmNotification.sharedInstance.loggers.count) == 1
            }
            it("clean") {
                self.cleanLoggers()
            }
            
            
//            context("the object does not have a valid primaryKey setted") {
//                var myTask: User!
//                beforeEach {
//                    self.cleanLoggers()
////                    myTask = User()
////                    myTask.id = 123456
////                    myTask.name = "23424"
////                    realm.write {
////                        realm.addNotified(myTask)
////                        //                        realm.addNotified(object, update: true)
////                    }
//                    
//                }
//                it("trying to add the same object again, will update it") {
//                    expect(myTask.realm).toNot(beNil())
//                }
//                it("clean") {
//                    self.cleanLoggers()
//                }
//            }
            
            context("the Model does not have primaryKey") {
                var object: Dummy!
                beforeEach {
                    self.cleanLoggers()
                    object = Dummy()
                    object.id = 1
                    realm.write {
                        realm.addNotified(object)
                    }
                }
                it("will add it to the realm") {
                    expect(object.realm).toNot(beNil())
                }
                it("won't use a logger") {
                    expect(RealmNotification.sharedInstance.loggers.count) == 0
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }
            
            
        }
        
        describe("createNotified") {
            var refetchedTask: Task!
            it("beforeAll") {
                realm.write {
                    realm.createNotified(Task.self, value: ["id":1500, "name": "testingName2"], update: true)
                }
                refetchedTask = realm.objectForPrimaryKey(Task.self, key: 1500)
            }
            it("task is updated") {
                expect(refetchedTask.name) == "testingName2"
            }
            it("still one logger") {
                expect(RealmNotification.sharedInstance.loggers.count) == 1
            }
            it("clean") {
                self.cleanLoggers()
            }
        }
        
        describe("deleteNotified (array)") {
            var refetchedTask: Task!

            beforeEach {
                refetchedTask = realm.objectForPrimaryKey(Task.self, key: 1500)
                realm.write {
                    realm.deleteNotified([refetchedTask])
                }
            }
            it("object in DB is invalidated") {
                expect(refetchedTask.invalidated).to(beTruthy())
            }
            afterEach {
                self.cleanLoggers()
            }
        }
        
        
        describe("execute") {
            var request: RealmRequest<Task>!
            var result: Task!
            beforeEach {
                realm.write {
                    let task = Task()
                    task.id = 1600
                    realm.addNotified([task])
                }
                let predicate = NSPredicate(format: "id == %d", 1600)
                request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: [])
                result = realm.execute(request).toArray(Task.self).first!
            }
            it("returns the correct element") {
                expect(result.id) == 1600
            }
            afterEach {
                realm.write {
                    realm.delete(result)
                }
                self.cleanLoggers()
            }
        }
    }
}