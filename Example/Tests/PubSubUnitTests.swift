
import Quick
import Nimble
import CogsSDK

class PubSubUnitTests: QuickSpec {
    override func spec() {

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

        describe("Cogs PubSub Service") {

            describe("get sessionUUID") {
                it("returns sessionUUID") {

                    let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                    waitUntil(timeout: defaultTimeout) { done in
                        connectionHandle.connect(sessionUUID: nil) {
                            connectionHandle.getSessionUuid() { outcome in
                                switch outcome {
                                case .pubSubSuccess(let object):
                                    if let uuid = object as? String {
                                        expect(uuid).toNot(beNil())
                                        expect(uuid).toNot(beEmpty())
                                    } else {
                                        fail("Expected String, got \(object)")
                                    }

                                    done()

                                case .pubSubResponseError(let errorResponse):

                                    expect(errorResponse.action == PubSubAction.sessionUuid.rawValue).to(beTruthy())
                                    expect(errorResponse.code).toNot(equal(PubSubResponseCode.success.rawValue))

                                    done()
                                }
                            }
                        }
                    }
                }
            }

            describe("channel subcriptions") {
                let testChannelName = "Test"

                describe("subscribe to a channel") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                        it("returns subscribed channels list") {
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
                                            }

                                        default:
                                            fail("Expected success, got error response")
                                        }

                                        done()
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys, options: defaultOptions)

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.subscribe.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got success")
                                        }

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("list subcriptions") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                        it("returns subscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
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

                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys, options: defaultOptions)

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.listSubscriptions() { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.subscriptions.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got success")
                                        }

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from a channel") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                        it("returns subscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
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

                                            done()
                                        }
                                    }
                                }
                            }
                        }

                        it("returns not found") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
                                    switch outcome {
                                    case .pubSubResponseError(let errorResponse):
                                        expect(errorResponse.action) == PubSubAction.unsubscribe.rawValue
                                        expect(errorResponse.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                    default:
                                        fail("Expected error response, got success")
                                    }

                                    done()
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys, options: defaultOptions)

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.unsubscribe.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got object")
                                        }

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from all channels") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                        it("returns unsubscribed channels list") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: "Test", messageHandler: nil) { _ in
                                        connectionHandle.subscribe(channelName: "Test2", messageHandler: nil) { _ in
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

                                                done()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys, options: defaultOptions)

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.unsubscribeAll() { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorRespoinse):
                                            expect(errorRespoinse.action) == PubSubAction.unsubscribeAll.rawValue
                                            expect(errorRespoinse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        default:
                                            fail("Expected error response, got object")
                                        }

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            describe("publish messages") {
                let testChannelName = "Test channel"
                let testMessage = "Test message"

                describe("publish") {
                    context("when write key is supplied") {

                        let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                        afterEach {
                            connectionHandle.close()
                        }

                        it("returns published message") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                                    }
                                }

                                connectionHandle.onMessage = { message in
                                    expect(message.action) == PubSubAction.message.rawValue
                                    expect(message.channel) == testChannelName
                                    expect(message.message) == testMessage

                                    done()
                                }
                            }
                        }

                        xit("returns not found") {
                            let uniqueChannelName = UUID().uuidString

                            waitUntil { done in
                                connectionHandle.publishWithAck(channelName: uniqueChannelName, message: testMessage) { outcome in
                                    switch outcome {
                                    case .pubSubResponseError(let errorResponse):
                                        expect(errorResponse.action) == PubSubAction.publish.rawValue
                                        expect(errorResponse.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                    default:
                                        fail("Expected error response, got object")
                                    }

                                    done()
                                }
                            }
                        }
                    }

                    context("when write key in not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys, options: defaultOptions)

                        afterEach {
                            connectionHandle.close()
                        }

                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.publish(channelName: testChannelName, message: testMessage) { error in

                                            expect(error).toNot(beNil())
                                            expect(error!.action) == PubSubAction.publish.rawValue
                                            expect(error!.code) == PubSubResponseCode.unauthorised.rawValue

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
                        let connectionHandle = pubSubService.connnect(keys: allKeys, options: defaultOptions)

                        afterEach {
                            connectionHandle.close()
                        }

                        it("returns success ack") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { outcome in
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

                                            done()
                                        }
                                    }
                                }
                            }
                        }

                        xit("returns not found") {
                            let uniqueChannelName = UUID().uuidString

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.publishWithAck(channelName: uniqueChannelName, message: testMessage) { outcome in
                                        switch outcome {
                                        case .pubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.publish.rawValue
                                            expect(errorResponse.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                        default:
                                            fail("Expected error response, got success")
                                        }

                                        done()
                                    }
                                }
                            }
                        }
                    }

                    context("when write key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys, options: defaultOptions)

                        afterEach {
                            connectionHandle.close()
                        }
                        
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { outcome in
                                            switch outcome {
                                            case .pubSubResponseError(let errorResponse):
                                                expect(errorResponse.action) == PubSubAction.publish.rawValue
                                                expect(errorResponse.code) == PubSubResponseCode.unauthorised.rawValue
                                                
                                            default:
                                                fail("Expected error response, got success")
                                            }
                                            
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
