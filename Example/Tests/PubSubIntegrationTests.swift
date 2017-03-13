// https://github.com/Quick/Quick

import Quick
import Nimble
import CogsSDK

class PubSubIntegrationTests: QuickSpec {
    override func spec() {
        let testChannelName = "Test channel"
        let testMessage = "Test message"

        var pubSubService: PubSubService!

        var url: String!
        var readKey: String!
        var writeKey: String!
        var adminKey: String!

        var allKeys: [String]!
        var noReadKeys: [String]!
        var noWriteKeys: [String]!

        let defaultTimeout: TimeInterval = 10

        let bundle = Bundle(for: type(of: self))
        if let path = bundle.path(forResource: "Keys", ofType: "plist") {

            if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                url      = dict["url"] as? String
                readKey  = dict["readKey"] as? String
                writeKey = dict["writeKey"] as? String
                adminKey = dict["adminKey"] as? String
            }

            allKeys     = [readKey, writeKey, adminKey]
            noReadKeys  = [writeKey, adminKey]
            noWriteKeys = [readKey, adminKey]
        }

        let defaultOptions = PubSubOptions(url: url, connectionTimeout: 30, autoReconnect: true,
                                           minReconnectDelay: 5, maxReconnectDelay: 300, maxReconnectAttempts: -1)

        pubSubService = PubSubService()

        func getSessionUUID(_ connectionHandle: PubSubConnectionHandle, completion: @escaping (String) -> Void) {
            connectionHandle.getSessionUuid() { outcome in
                switch outcome {
                case .pubSubSuccess(let object):
                    if let uuid = object as? String {
                        expect(uuid).toNot(beNil())
                        expect(uuid).toNot(beEmpty())

                        completion(uuid)
                    } else {
                        fail("Expected String, got \(object)")
                    }

                default:
                    fail("Expected success, got error response")
                }
            }
        }

        describe("Full Sweep Test") {
            let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

            afterEach {
                connectionHandle.close()
            }

            it("is successfull") {
                waitUntil(timeout: defaultTimeout) { done in
                    connectionHandle.connect(sessionUUID: nil) {
                        connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { outcome in
                            switch outcome {
                            case .pubSubSuccess(let object):
                                if let channels = object as? [String] {
                                    expect(channels).toNot(beNil())
                                    expect(channels).toNot(beEmpty())
                                    expect(channels.count).to(equal(1))
                                } else {
                                    fail("Expected [String], got \(object)")

                                    done()
                                }

                                connectionHandle.listSubscriptions() { outcome in
                                    switch outcome {
                                    case .pubSubSuccess(let object):
                                        if let channels = object as? [String] {
                                            expect(channels).toNot(beNil())
                                            expect(channels).toNot(beEmpty())
                                            expect(channels.count).to(equal(1))
                                        } else {
                                            fail("Expected [String], got \(object)")

                                            done()
                                        }

                                    default:
                                        fail("Expected success, got error response")

                                        done()
                                    }

                                    connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                                }

                            default:
                                fail("Expected success, got error response")

                                done()
                            }
                        }
                    }

                    connectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannelName
                        expect(message.message) == testMessage

                        connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
                            switch outcome {
                            case .pubSubSuccess(let object):
                                if let channels = object as? [String] {
                                    expect(channels).toNot(beNil())
                                    expect(channels).to(beEmpty())
                                } else {
                                    fail("Expected [], got \(object)")

                                    done()
                                }

                            default:
                                fail("Expected success, got error response")

                                done()
                            }

                            connectionHandle.close()
                        }
                    }

                    connectionHandle.onClose = { (error) in
                        expect(error).to(beNil())

                        done()
                    }
                }
            }
        }

        describe("Interaction Test") {
            let clientOneConnectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

            let clientTwoConnectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

            afterEach {
                clientOneConnectionHandle.close()
                clientTwoConnectionHandle.close()
            }

            it("is successfull") {
                waitUntil(timeout: defaultTimeout) { done in
                    clientOneConnectionHandle.connect(sessionUUID: nil) {
                        clientOneConnectionHandle.subscribe(channelName: testChannelName, messageHandler: { message in

                            expect(message).toNot(beNil())
                            expect(message.action) == PubSubAction.message.rawValue
                            expect(message.channel) == testChannelName
                            expect(message.message) == testMessage

                        }, completion: { outcome in
                            switch outcome {
                            case .pubSubSuccess(let object):
                                if let channels = object as? [String] {
                                    expect(channels).toNot(beNil())
                                    expect(channels).toNot(beEmpty())
                                    expect(channels.count).to(equal(1))
                                } else {
                                    fail("Expected [String], got \(object)")

                                    done()
                                }

                            default:
                                fail("Expected success, got error response")

                                done()
                            }

                            clientOneConnectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }

                            done()
                        })
                    }
                }

                waitUntil(timeout: defaultTimeout) { done in
                    clientTwoConnectionHandle.connect(sessionUUID: nil) {
                        clientTwoConnectionHandle.subscribe(channelName: testChannelName, messageHandler: { message in

                            expect(message).toNot(beNil())
                            expect(message.action) == PubSubAction.message.rawValue
                            expect(message.channel) == testChannelName
                            expect(message.message) == testMessage

                        }, completion: { outcome in
                            switch outcome {
                            case .pubSubSuccess(let object):
                                if let channels = object as? [String] {
                                    expect(channels).toNot(beNil())
                                    expect(channels).toNot(beEmpty())
                                    expect(channels.count).to(equal(1))
                                } else {
                                    fail("Expected [String], got \(object)")

                                    done()
                                }

                            default:
                                fail("Expected success, got error response")

                                done()
                            }

                            clientTwoConnectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }

                            done()
                        })
                    }
                }

                waitUntil(timeout: 20) { done in
                    clientOneConnectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannelName
                        expect(message.message) == testMessage

                        done()
                    }
                }

                waitUntil(timeout: 22) { done in
                    clientTwoConnectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannelName
                        expect(message.message) == testMessage

                       done()
                    }
                }
            }
        }

        describe("Reconnect Test") {
            let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)
            var sessionUUID: String!

            afterEach {
                connectionHandle.close()
            }

            it("successfully restores current session") {
                waitUntil(timeout: 15) { done in
                    connectionHandle.connect(sessionUUID: nil) {
                        getSessionUUID(connectionHandle) { uuid in
                            sessionUUID = uuid

                            connectionHandle.dropConnection()
                        }
                    }

                    connectionHandle.onReconnect = {
                        getSessionUUID(connectionHandle) { uuid in

                            expect(uuid == sessionUUID).to(beTruthy())

                            done()
                        }
                    }
                }
            }

            xit("successfully opens new session after session expire") {
                var sessionUuid: String?

                waitUntil(timeout: 310) { done in
                    connectionHandle.connect(sessionUUID: nil) {
                        getSessionUUID(connectionHandle) { uuid in
                            sessionUUID = uuid

                            connectionHandle.dropConnection()
                            Thread.sleep(forTimeInterval: 300)
                            connectionHandle.connect(sessionUUID: uuid)
                        }
                    }

                    connectionHandle.onNewSession = { uuid in
                        if sessionUUID != nil {
                            expect(uuid != sessionUuid).to(beTruthy())

                            done()
                        } else {
                            sessionUuid = uuid
                        }
                    }
                }
            }
        }

        describe("Get Session Uuid Test") {
            let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

            afterEach {
                connectionHandle.close()
            }

            it("returns the same uuid when session is restored") {
                waitUntil(timeout: 10) { done in
                    connectionHandle.connect(sessionUUID: nil) {
                        getSessionUUID(connectionHandle) { oldUuid in

                            connectionHandle.close()

                            connectionHandle.connect(sessionUUID: oldUuid) {
                                getSessionUUID(connectionHandle) { newUuid in

                                    expect(oldUuid == newUuid).to(beTruthy())

                                    done()
                                }
                            }
                        }
                    }
                }
            }
        }

        describe("Event Handlers Tests") {
            let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

            afterEach {
                connectionHandle.close()
            }

            describe("onRawRecord Test") {

            }

            describe("onMessage Test") {
                it("receives only messages") {
                    waitUntil(timeout: defaultTimeout) { done in
                        connectionHandle.connect(sessionUUID: nil) {
                            connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                            }
                        }

                        connectionHandle.onMessage = { message in

                            expect (message.channel == testChannelName).to(beTruthy())
                            expect(message.message == testMessage).to(beTruthy())

                            done()
                        }
                    }
                }
            }

            describe("onErrorResponse Test") {
                context("when read key is not supplied") {
                    let connectionHandle = pubSubService.connnect(keys: noReadKeys, options: defaultOptions)
                    var isEmitting: Bool = false
                    var error: PubSubErrorResponse?

                    afterEach {
                        connectionHandle.close()
                    }

                    it("emits error response") {
                        waitUntil(timeout: defaultTimeout) { done in
                            connectionHandle.connect(sessionUUID: nil) {
                                connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in }
                            }

                            connectionHandle.onErrorResponse = { responseError in
                                isEmitting = true
                                error = responseError

                                done()
                            }
                        }

                        waitUntil(timeout: 11) { done in
                            expect(isEmitting == true).to(beTruthy())
                            expect(error).toNot(beNil())
                            expect(error!.action == PubSubAction.subscribe.rawValue).to(beTruthy())
                            expect(error!.code == PubSubResponseCode.unauthorised.rawValue).to(beTruthy())
                            
                            done()
                        }
                    }
                }
                
                context("when write key is not supplied") {
                    let connectionHandle = pubSubService.connnect(keys: noWriteKeys, options: defaultOptions)
                    var isEmitting: Bool = false
                    var error: PubSubErrorResponse?

                    afterEach {
                        connectionHandle.close()
                    }

                    it("emits error response") {
                        waitUntil(timeout: 10) { done in
                            connectionHandle.connect(sessionUUID: nil) {
                                connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                            }
                            
                            connectionHandle.onErrorResponse = { responseError in
                                isEmitting = true
                                error = responseError
                                
                                done()
                            }
                        }
                        
                        waitUntil(timeout: 11) { done in
                            expect(isEmitting == true).to(beTruthy())
                            expect(error).toNot(beNil())
                            expect(error!.action == PubSubAction.publish.rawValue).to(beTruthy())
                            expect(error!.code == PubSubResponseCode.unauthorised.rawValue).to(beTruthy())
                            
                            done()
                        }
                    }
                }
            }
            
            describe("onReconnect Test") {
                var isEmitting: Bool = false

                it("emits reconnect event") {
                    waitUntil(timeout: 15) { done in
                        connectionHandle.connect(sessionUUID: nil)

                        connectionHandle.onNewSession = { uuid in
                            connectionHandle.dropConnection()
                        }

                        connectionHandle.onReconnect = {
                            isEmitting = true

                            done()
                        }
                    }

                    waitUntil(timeout: 16) { done in
                        expect(isEmitting == true).to(beTruthy())

                        done()
                    }
                }
            }
            
            describe("onClose Test") {
                var isEmitting: Bool = false
                
                it("emits close event") {
                    waitUntil(timeout: defaultTimeout) { done in
                        connectionHandle.connect(sessionUUID: nil) {
                            connectionHandle.close()
                        }
                        
                        connectionHandle.onClose = { (error) in
                            isEmitting = true
                            
                            done()
                        }
                    }
                    
                    waitUntil(timeout: 11) { done in
                        expect(isEmitting == true).to(beTruthy())
                        
                        done()
                    }
                }
            }
            
            describe("onNewSession Test") {
                var isEmitting: Bool = false
                var sessionUuid: String?
                
                it("emits on new session event") {
                    waitUntil(timeout: defaultTimeout) { done in
                        
                        connectionHandle.connect(sessionUUID: nil)
                        
                        connectionHandle.onClose = { (error) in
                            connectionHandle.connect(sessionUUID: nil)
                        }
                        
                        connectionHandle.onNewSession = { uuid in

                            if sessionUuid != nil {
                                isEmitting = true

                                done()
                            } else {
                                sessionUuid = uuid
                                connectionHandle.close()
                            }
                        }
                    }
                    
                    waitUntil(timeout: 11) { done in
                        expect(isEmitting == true).to(beTruthy())
                        expect(sessionUuid).toNot(beNil())
                        expect(sessionUuid).toNot(beEmpty())
                        
                        done()
                    }
                }
            }
        }
    }
}