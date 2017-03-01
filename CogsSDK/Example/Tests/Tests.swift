// https://github.com/Quick/Quick

import Quick
import Nimble
import CogsSDK

class PubSubSpec: QuickSpec {
    override func spec() {

        describe("Cogs PubSub Service") {
            var pubSubService: PubSubService!
            var connectionHandle: PubSubConnectionHandle!

            var url: String!
            var readKey: String!
            var writeKey: String!
            var adminKey: String!

            var keys: [String]!

            if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {

                if let dict = NSDictionary(contentsOfFile: path) as? [String: Any] {
                    url = dict["url"] as? String
                    readKey = dict["readKey"] as? String
                    writeKey = dict["writeKey"] as? String
                    adminKey = dict["adminKey"] as? String
                }

                keys = [readKey, writeKey, adminKey]
            }

            pubSubService = PubSubService()
//            connectionHandle = pubSubService.connnect(keys: keys,
//                                                       options: PubSubOptions(url: url,
//                                                                              timeout: 30,
//                                                                              autoReconnect: false))
            //connectionHandle.connect(sessionUUID: nil)

            describe("get sessionUUID") {
                it("is successfull") {
                    connectionHandle = pubSubService.connnect(keys: keys,
                                                              options: PubSubOptions(url: url,
                                                                                     timeout: 30,
                                                                                     autoReconnect: false))
                    connectionHandle.connect(sessionUUID: nil)

                    //connectionHandle.onNewSession = { _ in
                        waitUntil() { done in
                            connectionHandle.getSessionUuid() { json, error in
                                let response = try! PubSubResponse(json: json!)

                                expect(error).to(beNil())
                                expect(response).toNot(beNil())
                                expect(response.action) == PubSubAction.sessionUuid.rawValue
                                expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                expect(response.uuid).toNot(beNil())
                                expect(response.uuid!).toNot(beEmpty())

                                done()
                            }
                        }
                   // }
                }
            }

            describe("channel subcriptions") {
                let testChannelName = "Test"
                beforeEach {
                    connectionHandle.close()
                }

//                afterEach {
//                    connectionHandle.unsubscribeAll() { _ in }
//                }

                describe("subscribe to a channel") {
                    context("when read key is supplied") {
                        it("is successfull") {
                            connectionHandle = pubSubService.connnect(keys: keys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil { done in
                                connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { json, error in
                                    let response = try! PubSubResponse(json: json!)

                                    expect(error).to(beNil())
                                    expect(response).toNot(beNil())
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

                    context("when read key is not supplied") {
                        it("returns unauthorised") {
                            let testKeys: [String] = [writeKey, adminKey]

                            connectionHandle = pubSubService.connnect(keys: testKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil { done in
                                connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { json, error in

                                    expect(json).to(beNil())
                                    expect(error).toNot(beNil())
                                    expect(error!.action) == PubSubAction.subscribe.rawValue
                                    expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))
                                }
                            }
                        }
                    }
                }

                describe("list subcriptions") {
                    context("when read key is supplied") {
                        it("is successfull") {
                            connectionHandle = pubSubService.connnect(keys: keys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil { done in
                                connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _ in
                                    connectionHandle.listSubscriptions() { json, error in
                                        let response = try! PubSubResponse(json: json!)

                                        expect(error).to(beNil())
                                        expect(response).toNot(beNil())
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

                    context("when read key is not supplied") {
                        it("returns unauthorised") {
                            let testKeys: [String] = [writeKey, adminKey]

                            connectionHandle = pubSubService.connnect(keys: testKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil { done in
                                connectionHandle.listSubscriptions() { json, error in

                                    expect(json).to(beNil())
                                    expect(error).toNot(beNil())
                                    expect(error!.action) == PubSubAction.subscriptions.rawValue
                                    expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from a channel") {
                    context("when read key is supplied") {
                        beforeEach {
                            connectionHandle = pubSubService.connnect(keys: keys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)
                        }
                        
                        it("is successfull") {


                            waitUntil { done in
                                connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _ in
                                    connectionHandle.unsubscribe(channelName: testChannelName) { json, error in
                                        let response = try! PubSubResponse(json: json!)

                                        expect(error).to(beNil())
                                        expect(response).toNot(beNil())
                                        expect(response.action) == PubSubAction.unsubscribe.rawValue
                                        expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                        expect(response.channels).toNot(beNil())
                                        expect(response.channels!).to(beEmpty())

                                        done()
                                    }
                                }
                            }
                        }

                        it("returns not found") {
                            waitUntil { done in
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
                        it("returns unauthorised") {
                            let testKeys: [String] = [writeKey, adminKey]

                            connectionHandle = pubSubService.connnect(keys: testKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil { done in
                                connectionHandle.unsubscribe(channelName: testChannelName) { json, error in

                                    expect(json).to(beNil())
                                    expect(error).toNot(beNil())
                                    expect(error!.action) == PubSubAction.unsubscribe.rawValue
                                    expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))
                                }
                            }
                        }
                    }
                }

                describe("unsubscribe from all channels") {
                    context("when read key is supplied") {
                        it("is successfull") {
                            connectionHandle = pubSubService.connnect(keys: keys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil(timeout: 2) { done in
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

                    context("when read key is not supplied") {
                        it("returns unauthorised") {
                            let testKeys: [String] = [writeKey, adminKey]

                            connectionHandle = pubSubService.connnect(keys: testKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                            connectionHandle.connect(sessionUUID: nil)

                            waitUntil { done in
                                connectionHandle.unsubscribeAll() { json, error in

                                    expect(json).to(beNil())
                                    expect(error).toNot(beNil())
                                    expect(error!.action) == PubSubAction.unsubscribe.rawValue
                                    expect(error!.code).to(equal(PubSubResponseCode.unauthorised.rawValue))
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
                        xit("is succesfull") {
                            waitUntil(timeout: 2) { done in
                                connectionHandle.subscribe(channelName: testChannelName, channelHandler: nil) { _ in
                                    connectionHandle.publish(channelName: testChannelName, message: testMessage) { json, error in
                                        let response = try! PubSubMessage(json: json!)

                                        expect(error).to(beNil())
                                        expect(response).toNot(beNil())
                                        expect(response.action) == PubSubAction.message.rawValue
                                        expect(response.channel) == testChannelName
                                        expect(response.message) == testMessage

                                        done()
                                    }
                                }
                            }
                        }

                        xit("returns not found") {
                            let uniqueChannelName = UUID().uuidString

                            waitUntil { done in
                                connectionHandle.publish(channelName: uniqueChannelName, message: testMessage) { json, error in

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
                        it("returns unauthorised") {

                        }
                    }
                }

                describe("publish with ack") {
                    context("when write key is supplied") {
                        xit("is successfull") {
                            waitUntil { done in
                                connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { json, error in
                                    let response = try! PubSubResponse(json: json!)

                                    expect(error).to(beNil())
                                    expect(response).toNot(beNil())
                                    expect(response.action) == PubSubAction.publish.rawValue
                                    expect(response.code).to(equal(PubSubResponseCode.success.rawValue))
                                    expect(response.messageUUID).toNot(beNil())
                                    expect(response.messageUUID).toNot(beEmpty())

                                    done()
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

                    context("when write key is not supplied") {
                        it("returns unauthorised") {
                            
                        }
                    }

                }
            }
        }
    }
}
