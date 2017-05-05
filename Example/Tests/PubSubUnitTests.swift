
import Quick
import Nimble
import CogsSDK

class PubSubUnitTests: QuickSpec {

    override func spec() {
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
                readKey  = dict["readKey"] as? String
                writeKey = dict["writeKey"] as? String
                adminKey = dict["adminKey"] as? String
            }

            allKeys     = [readKey, writeKey, adminKey]
            noReadKeys  = [writeKey, adminKey]
            noWriteKeys = [readKey, adminKey]
        }

        let defaultOptions = PubSubOptions.defaultOptions

        describe("Cogs PubSub Service") {

            describe("get sessionUUID") {

                it("returns sessionUUID") {
                    waitUntil(timeout: defaultTimeout) { done in
                        let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                        var connectionHandle: PubSubConnectionHandle! = PubSubService.connect(socket: socket)
                        connectionHandle.onNewSession = { _ in
                            connectionHandle.getSessionUuid() { outcome in
                                switch outcome {
                                case .pubSubSuccess(let object):
                                    if let uuid = object as? String {
                                        expect(uuid).toNot(beNil())
                                        expect(uuid).toNot(beEmpty())
                                    } else {
                                        fail("Expected String, got \(object)")
                                    }

                                    connectionHandle.close()
                                    connectionHandle = nil
                                    done()

                                case .pubSubResponseError(let errorResponse):

                                    expect(errorResponse.action == PubSubAction.sessionUuid.rawValue).to(beTruthy())
                                    expect(errorResponse.code).toNot(equal(PubSubResponseCode.success.rawValue))

                                    connectionHandle.close()
                                    connectionHandle = nil
                                    done()
                                }
                            }
                        }
                    }
                }
            }

            describe("channel subcriptions") {
                let testChannel = "Test"

                describe("subscribe to a channel") {

                    context("when read key is supplied") {

                        it("returns subscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
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
                                            }

                                        default:
                                            fail("Expected success, got error response")
                                        }

                                        connectionHandle.close()
                                        done()
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: noReadKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession =  { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.subscribe.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got success")
                                        }

                                        connectionHandle.close()
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("list subcriptions") {
                    context("when read key is supplied") {

                        it("returns subscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.listSubscriptions() { outcome in

                                            switch outcome {
                                            case .pubSubSuccess(let object):
                                                if let channels = object as? [String] {
                                                    expect(channels).toNot(beNil())
                                                    expect(channels).toNot(beEmpty())
                                                    expect(channels.count).to(equal(1))
                                                } else {
                                                    fail("Expected [String], got \(object)")
                                                }

                                            default:
                                                fail("Expected success, got error response")
                                            }

                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: noReadKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.listSubscriptions() { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.subscriptions.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got success")
                                        }

                                        connectionHandle.close()
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from a channel") {

                    context("when read key is supplied") {

                        it("returns subscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.unsubscribe(channel: testChannel) { outcome in
                                            switch outcome {
                                            case .pubSubSuccess(let object):
                                                if let channels = object as? [String] {
                                                    expect(channels).toNot(beNil())
                                                    expect(channels).to(beEmpty())
                                                } else {
                                                    fail("Expected [], got \(object)")
                                                }

                                            default:
                                                fail("Expected success, got error response")
                                            }

                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }

                        it("returns not found") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: UUID().uuidString, messageHandler: nil) { _ in
                                        connectionHandle.unsubscribe(channel: testChannel) { outcome in
                                            switch outcome {
                                            case .pubSubResponseError(let errorResponse):
                                                expect(errorResponse.action) == PubSubAction.unsubscribe.rawValue
                                                expect(errorResponse.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                            default:
                                                fail("Expected error response, got success")
                                            }

                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: noReadKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.unsubscribe(channel: testChannel) { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.unsubscribe.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got object")
                                        }

                                        connectionHandle.close()
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from all channels") {

                    context("when read key is supplied") {

                        it("returns unsubscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: "Test", messageHandler: nil) { _ in
                                        connectionHandle.subscribe(channel: "Test2", messageHandler: nil) { _ in
                                            connectionHandle.unsubscribeAll() { outcome in
                                                switch outcome {
                                                case.pubSubSuccess(let object):
                                                    if let channels = object as? [String] {
                                                        expect(channels).toNot(beNil())
                                                        expect(channels).toNot(beEmpty())
                                                        expect(channels.count).to(equal(2))
                                                    } else {
                                                        fail("Expected [String], got \(object)")
                                                    }

                                                default:
                                                    fail("Expected success, got error response")
                                                }

                                                connectionHandle.close()
                                                done()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: noReadKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.unsubscribeAll() { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorRespoinse):
                                            expect(errorRespoinse.action) == PubSubAction.unsubscribeAll.rawValue
                                            expect(errorRespoinse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got object")
                                        }

                                        connectionHandle.close()
                                        done()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            describe("publish messages") {
                let testChannel = "Test channel"
                let testMessage = "Test message"

                describe("publish") {

                    context("when write key is supplied") {

                        it("returns published message") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.publish(channel: testChannel, message: testMessage) { _ in }
                                    }
                                }

                                connectionHandle.onMessage = { message in
                                    expect(message.action) == PubSubAction.message.rawValue
                                    expect(message.channel) == testChannel
                                    expect(message.message) == testMessage

                                    connectionHandle.close()
                                    done()
                                }
                            }
                        }

                        xit("returns not found") {
                            let uniquechannel = UUID().uuidString

                            waitUntil { done in
                                let socket = MockPubSubSocket(keys: noReadKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channel: uniquechannel, message: testMessage) { outcome in
                                            switch outcome {
                                            case .pubSubResponseError(let errorResponse):
                                                expect(errorResponse.action) == PubSubAction.publish.rawValue
                                                expect(errorResponse.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                            default:
                                                fail("Expected error response, got object")
                                            }

                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when write key in not supplied") {

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: noWriteKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.publish(channel: testChannel, message: testMessage) { error in

                                            expect(error).toNot(beNil())
                                            expect(error!.action) == PubSubAction.publish.rawValue
                                            expect(error!.code) == PubSubResponseCode.unauthorised.rawValue

                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                describe("publish with ack") {

                    context("when write key is supplied") {

                        it("returns success ack") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channel: testChannel, message: testMessage) { outcome in
                                            switch outcome {
                                            case .pubSubSuccess(let object):
                                                if let messageUuid = object as? String {
                                                    expect(messageUuid).toNot(beNil())
                                                    expect(messageUuid).toNot(beEmpty())
                                                } else {
                                                    fail("Expected String, got \(object)")
                                                }

                                            default:
                                                fail("Expected success, got error response")
                                            }

                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }

                        xit("returns not found") {
                            let uniquechannel = UUID().uuidString

                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: allKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)

                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.publishWithAck(channel: uniquechannel, message: testMessage) { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.publish.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.notFound.rawValue))
                                            
                                        default:
                                            fail("Expected error response, got success")
                                        }
                                        
                                        connectionHandle.close()
                                        done()
                                    }
                                }
                            }
                        }
                    }
                    
                    context("when write key is not supplied") {
                        
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                let socket = MockPubSubSocket(keys: noWriteKeys, options: defaultOptions)
                                let connectionHandle = PubSubService.connect(socket: socket)
                                
                                connectionHandle.onNewSession = { _ in
                                    connectionHandle.subscribe(channel: testChannel, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channel: testChannel, message: testMessage) { outcome in
                                            switch outcome {
                                            case .pubSubResponseError(let errorResponse):
                                                expect(errorResponse.action) == PubSubAction.publish.rawValue
                                                expect(errorResponse.code) == PubSubResponseCode.unauthorised.rawValue
                                                
                                            default:
                                                fail("Expected error response, got success")
                                            }
                                            
                                            connectionHandle.close()
                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
