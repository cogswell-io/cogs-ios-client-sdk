// https://github.com/Quick/Quick

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

        let defaultTimeout: TimeInterval = 5

        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {

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

        pubSubService = PubSubService()

        /*
        describe("Cogs PubSub Service") {

            describe("get sessionUUID") {
                it("is successfull") {
                   let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                              options: PubSubOptions(url: url,
                                                                                     timeout: 30,
                                                                                     autoReconnect: false))
                    waitUntil(timeout: defaultTimeout) { done in
                        connectionHandle.connect(sessionUUID: nil) {
                            connectionHandle.getSessionUuid() { json, error in

                                expect(error).to(beNil())
                                expect(json).toNot(beNil())

                                let response = try! PubSubResponse(json: json!)
                                expect(response.action) == PubSubAction.sessionUuid.rawValue
                                expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                expect(response.uuid).toNot(beNil())
                                expect(response.uuid!).toNot(beEmpty())

                                done()
                            }
                        }
                    }
                }
            }

            describe("channel subcriptions") {
                let testChannelName = "Test"

                describe("subscribe to a channel") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                  options: PubSubOptions(url: url,
                                                                                         timeout: 30,
                                                                                         autoReconnect: false))

                        it("is successfull") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { json, error in

                                        expect(error).to(beNil())
                                        expect(json).toNot(beNil())

                                        let response = try! PubSubResponse(json: json!)
                                        expect(response.action) == PubSubAction.subscribe.rawValue
                                        expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                        expect(response.channels).toNot(beNil())
                                        expect(response.channels!).toNot(beEmpty())
                                        expect(response.channels!.count).to(equal(1))

                                        done()
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { json, error in

                                        expect(json).to(beNil())
                                        expect(error).toNot(beNil())
                                        expect(error!.action) == PubSubAction.subscribe.rawValue
                                        expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("list subcriptions") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))

                        it("is successfull") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _ in
                                        connectionHandle.listSubscriptions() { json, error in

                                            expect(error).to(beNil())
                                            expect(json).toNot(beNil())

                                            let response = try! PubSubResponse(json: json!)
                                            expect(response.action) == PubSubAction.subscriptions.rawValue
                                            expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                            expect(response.channels).toNot(beNil())
                                            expect(response.channels!).toNot(beEmpty())
                                            expect(response.channels!.count).to(equal(1))

                                            done()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.listSubscriptions() { json, error in

                                        expect(json).to(beNil())
                                        expect(error).toNot(beNil())
                                        expect(error!.action) == PubSubAction.subscriptions.rawValue
                                        expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from a channel") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))

                        it("is successfull") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _ in
                                        connectionHandle.unsubscribe(channelName: testChannelName) { json, error in

                                            expect(error).to(beNil())
                                            expect(json).toNot(beNil())

                                            let response = try! PubSubResponse(json: json!)
                                            expect(response.action) == PubSubAction.unsubscribe.rawValue
                                            expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                            expect(response.channels).toNot(beNil())
                                            expect(response.channels!).to(beEmpty())

                                            done()
                                        }
                                    }
                                }
                            }
                        }

                        it("returns not found") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.unsubscribe(channelName: testChannelName) { json, error in

                                    expect(json).to(beNil())
                                    expect(error).toNot(beNil())
                                    expect(error!.action) == PubSubAction.unsubscribe.rawValue
                                    expect(error!.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                    done()
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.unsubscribe(channelName: testChannelName) { json, error in

                                        expect(json).to(beNil())
                                        expect(error).toNot(beNil())
                                        expect(error!.action) == PubSubAction.unsubscribe.rawValue
                                        expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

                                        done()
                                    }
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from all channels") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("is successfull") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: "Test", channelHandler: nil) { _ in
                                        connectionHandle.subscribe(channelName: "Test2", channelHandler: nil) { _ in
                                            connectionHandle.unsubscribeAll() { json, error in
                                                let response = try! PubSubResponse(json: json!)

                                                expect(error).to(beNil())
                                                expect(response).toNot(beNil())
                                                expect(response.action) == PubSubAction.unsubscribeAll.rawValue
                                                expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                                expect(response.channels).toNot(beNil())
                                                expect(response.channels!).toNot(beEmpty())
                                                expect(response.channels!.count).to(equal(2))

                                                done()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    context("when read key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.unsubscribeAll() { json, error in

                                        expect(json).to(beNil())
                                        expect(error).toNot(beNil())
                                        expect(error!.action) == PubSubAction.unsubscribeAll.rawValue
                                        expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

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
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        xit("is succesfull") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: { (message) in

                                        expect(message).toNot(beNil())
                                        expect(message.action) == PubSubAction.message.rawValue
                                        expect(message.channel) == testChannelName
                                        expect(message.message) == testMessage

                                        done()
                                    }, completion: { (json, error) in
                                        connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                                    })
                                }
                            }
                        }

                        xit("returns not found") {
                            let uniqueChannelName = UUID().uuidString

                            waitUntil { done in
                                connectionHandle.publishWithAck(channelName: uniqueChannelName, message: testMessage) { json, error in

                                    expect(json).to(beNil())
                                    expect(error).toNot(beNil())
                                    expect(error!.action) == PubSubAction.publish.rawValue
                                    expect(error!.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                    done()
                                }
                            }
                        }
                    }

                    context("when write key in not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _ in
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
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("is successfull") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _, _ in
                                        connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { json, error in

                                            expect(error).to(beNil())
                                            expect(json).toNot(beNil())

                                            let response = try! PubSubResponse(json: json!)
                                            expect(response.action) == PubSubAction.publish.rawValue
                                            expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                            expect(response.messageUUID).toNot(beNil())
                                            expect(response.messageUUID).toNot(beEmpty())

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
                                    connectionHandle.publishWithAck(channelName: uniqueChannelName, message: testMessage) { json, error in

                                        expect(json).to(beNil())
                                        expect(error).toNot(beNil())
                                        expect(error!.action) == PubSubAction.publish.rawValue
                                        expect(error!.code).to(equal(PubSubResponseCode.notFound.rawValue))

                                        done()
                                    }
                                }
                            }
                        }
                    }

                    context("when write key is not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _, _ in
                                        connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { json, error in

                                            expect(json).to(beNil())
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
            }
        }*/
    }
}

class PubSubIntegrationTests: QuickSpec {
    override func spec() {
        var pubSubService: PubSubService!

        var url: String!
        var readKey: String!
        var writeKey: String!
        var adminKey: String!

        var allKeys: [String]!
        var noReadKeys: [String]!
        var noWriteKeys: [String]!

        var receivedMessage: PubSubMessage!

        let defaultTimeout: TimeInterval = 5

        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {

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
        
        pubSubService = PubSubService()

        /*
        describe("Full Sweep Test") {
            let testChannelName = "Test channel"
            let testMessage = "Test message"

            let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                          options: PubSubOptions(url: url,
                                                                                 timeout: 30,
                                                                                 autoReconnect: false))
            connectionHandle.connect(sessionUUID: nil)

            connectionHandle.onMessage = { message in
                receivedMessage = message
            }

            it("is successfull") {
                waitUntil(timeout: defaultTimeout) { done in
                    connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { json, error in
                        expect(error).to(beNil())
                        expect(json).toNot(beNil())

                        let response = try! PubSubResponse(json: json!)
                        expect(response.action) == PubSubAction.subscribe.rawValue
                        expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                        expect(response.channels).toNot(beNil())
                        expect(response.channels!).toNot(beEmpty())
                        expect(response.channels!.count).to(equal(1))

                        done()
                    }
                }

                waitUntil(timeout: defaultTimeout) { done in
                    connectionHandle.listSubscriptions() { json, error in
                        expect(error).to(beNil())
                        expect(json).toNot(beNil())

                        let response = try! PubSubResponse(json: json!)
                        expect(response.action) == PubSubAction.subscriptions.rawValue
                        expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                        expect(response.channels).toNot(beNil())
                        expect(response.channels!).toNot(beEmpty())
                        expect(response.channels!.count).to(equal(1))

                        done()
                    }
                }

                waitUntil(timeout: defaultTimeout) { done in
                    connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in
                        expect(receivedMessage.action) == PubSubAction.message.rawValue
                        expect(receivedMessage.channel) == testChannelName
                        expect(receivedMessage.message) == testMessage

                        done()
                    }
                }
            }
        }*/
    }
}
