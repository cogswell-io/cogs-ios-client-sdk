
import Quick
import Nimble
import CogsSDK

class PubSubFullSweepTests: QuickSpec {
    
    override func spec() {
        let testChannel = "Test channel"
        let testMessage = "Test message"

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

        let defaultOptions = PubSubOptions.defaultOptions

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

            it("pubsub successfully connects, subscribes, lists subscribtions, publishes and receives message, closes the connection") {
                waitUntil(timeout: defaultTimeout) { done in
                    let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                    let connectionHandle = PubSubService.connect(socket: socket)

                    connectionHandle.onNewSession = { _ in
                        connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { outcome in
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

                                    connectionHandle.publish(channel: testChannel, message: testMessage) { _ in }

                                    connectionHandle.onMessage = { message in
                                        expect(message.action) == PubSubAction.message.rawValue
                                        expect(message.channel) == testChannel
                                        expect(message.message) == testMessage

                                        connectionHandle.unsubscribe(channel: testChannel) { outcome in
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

                                            connectionHandle.onClose = { (error) in
                                                expect(error).to(beNil())

                                                done()
                                            }
                                        }
                                    }
                                }

                            default:
                                fail("Expected success, got error response")

                                done()
                            }
                        }
                    }
                }
            }
        }

        describe("Interaction Test") {

            it("pubsub successfully interacts with two clients (each client connects, subscribes, publishes message, receives message)") {
                waitUntil(timeout: defaultTimeout) { done in
                    let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                    let clientOneConnectionHandle = PubSubService.connect(socket: socket)

                    clientOneConnectionHandle.onNewSession = { _ in
                        clientOneConnectionHandle.subscribe(channel: testChannel, messageHandler: { message in

                            expect(message).toNot(beNil())
                            expect(message.action) == PubSubAction.message.rawValue
                            expect(message.channel) == testChannel
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

                            clientOneConnectionHandle.publish(channel: testChannel, message: testMessage) { _ in }
                        })
                    }

                    clientOneConnectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannel
                        expect(message.message) == testMessage

                        clientOneConnectionHandle.close()
                        done()
                    }
                }

                waitUntil(timeout: defaultTimeout) { done in
                    let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                    let clientTwoConnectionHandle = PubSubService.connect(socket: socket)

                    clientTwoConnectionHandle.onNewSession = { _ in
                        clientTwoConnectionHandle.subscribe(channel: testChannel, messageHandler: { message in

                            expect(message).toNot(beNil())
                            expect(message.action) == PubSubAction.message.rawValue
                            expect(message.channel) == testChannel
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

                            clientTwoConnectionHandle.publish(channel: testChannel, message: testMessage) { _ in }
                        })
                    }

                    clientTwoConnectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannel
                        expect(message.message) == testMessage

                        clientTwoConnectionHandle.close()
                        done()
                    }
                }
            }
        }

        describe("Reconnect Test") {

            it("successfully restores current session with supplied UUID") {
                var sessionUUID: String!

                waitUntil(timeout: 15) { done in
                    let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                    let connectionHandle = PubSubService.connect(socket: socket)

                    connectionHandle.onNewSession = { _ in
                        getSessionUUID(connectionHandle) { uuid in
                            sessionUUID = uuid

                            connectionHandle.dropConnection()
                        }
                    }

                    connectionHandle.onReconnect = {
                        getSessionUUID(connectionHandle) { uuid in

                            expect(uuid == sessionUUID).to(beTruthy())

                            connectionHandle.close()
                            done()
                        }
                    }
                }
            }

            xit("successfully opens new session after session expire (5 min)") {
                var sessionUuid: String?

                waitUntil(timeout: 310) { done in
                    let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                    let connectionHandle = PubSubService.connect(socket: socket)

                    connectionHandle.onNewSession = { uuid in
                        if sessionUuid != nil {
                            expect(uuid != sessionUuid).to(beTruthy())

                            connectionHandle.close()
                            done()
                        } else {
                            sessionUuid = uuid

                            connectionHandle.dropConnection()
                            Thread.sleep(forTimeInterval: 300)
                        }
                    }
                }
            }
        }

        describe("Get Session Uuid Test") {

            it("returns the same uuid when session is restored") {
                waitUntil(timeout: 15) { done in
                    let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                    let connectionHandle = PubSubService.connect(socket: socket)

                    connectionHandle.onNewSession = { _ in
                        getSessionUUID(connectionHandle) { oldUuid in

                            connectionHandle.dropConnection()

                            connectionHandle.onReconnect = { 
                                getSessionUUID(connectionHandle) { newUuid in

                                    expect(oldUuid == newUuid).to(beTruthy())

                                    connectionHandle.close()
                                    done()
                                }
                            }
                        }
                    }
                }
            }
        }

        describe("Event Handlers Tests") {

            describe("onRawRecord Test") {

                it("receives text record") {
                    waitUntil(timeout: defaultTimeout) { done in
                        let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                        let connectionHandle = PubSubService.connect(socket: socket)

                        connectionHandle.onNewSession = { _ in
                            connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                connectionHandle.publish(channel: testChannel, message: testMessage) { _ in }
                            }
                        }

                        connectionHandle.onRawRecord = { record in
                            expect(record).toNot(beEmpty())

                            connectionHandle.close()
                            done()
                        }
                    }
                }
            }

            describe("onMessage Test") {

                it("receives only message records") {
                    waitUntil(timeout: defaultTimeout) { done in
                        let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                        let connectionHandle = PubSubService.connect(socket: socket)

                        connectionHandle.onNewSession = { _ in
                            connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                connectionHandle.publish(channel: testChannel, message: testMessage) { _ in }
                            }
                        }

                        connectionHandle.onMessage = { message in
                            expect (message.channel == testChannel).to(beTruthy())
                            expect(message.message == testMessage).to(beTruthy())

                            connectionHandle.close()
                            done()
                        }
                    }
                }
            }

            describe("onErrorResponse Test") {
                context("when read key is not supplied") {

                    var isEmitting: Bool = false
                    var error: PubSubErrorResponse?

                    it("emits error response record") {
                        waitUntil(timeout: defaultTimeout) { done in
                            let socket = PubSubSocket(keys: noReadKeys, options: defaultOptions)
                            let connectionHandle = PubSubService.connect(socket: socket)

                            connectionHandle.onNewSession = { _ in
                                connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in }
                            }

                            connectionHandle.onErrorResponse = { responseError in
                                isEmitting = true
                                error = responseError

                                connectionHandle.close()
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
                    var isEmitting: Bool = false
                    var error: PubSubErrorResponse?

                    it("emits error response record") {
                        waitUntil(timeout: defaultTimeout) { done in
                            let socket = PubSubSocket(keys: noWriteKeys, options: defaultOptions)
                            let connectionHandle = PubSubService.connect(socket: socket)

                            connectionHandle.onNewSession = { _ in
                                connectionHandle.publish(channel: testChannel, message: testMessage) { _ in }
                            }
                            
                            connectionHandle.onErrorResponse = { responseError in
                                isEmitting = true
                                error = responseError

                                connectionHandle.close()
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
                        let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                        let connectionHandle = PubSubService.connect(socket: socket)

                        connectionHandle.onNewSession = { _ in
                            connectionHandle.dropConnection()
                        }

                        connectionHandle.onReconnect = {
                            isEmitting = true

                            connectionHandle.close()
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
                
                it("emits close event") {
                    var isEmitting: Bool = false

                    waitUntil(timeout: defaultTimeout) { done in
                        let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                        let connectionHandle = PubSubService.connect(socket: socket)

                        connectionHandle.onNewSession = { _ in
                            connectionHandle.close()
                        }
                        
                        connectionHandle.onClose = { (error) in
                            isEmitting = true

                            connectionHandle.close()
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

                it("emits on new session event") {
                    var isEmitting: Bool = false

                    waitUntil(timeout: defaultTimeout) { done in
                        let socket = PubSubSocket(keys: allKeys, options: defaultOptions)
                        let connectionHandle = PubSubService.connect(socket: socket)
                        
                        connectionHandle.onNewSession = { _ in
                            isEmitting = true

                            connectionHandle.close()
                            done()
                        }
                    }
                    
                    waitUntil(timeout: 11) { done in
                        expect(isEmitting == true).to(beTruthy())
                        
                        done()
                    }
                }
            }
        }
    }
}
