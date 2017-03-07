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

        describe("Cogs PubSub Service") {

            describe("get sessionUUID") {
                it("is successfull") {
                    let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                  options: PubSubOptions(url: url,
                                                                                         timeout: 30,
                                                                                         autoReconnect: false))
                    waitUntil(timeout: defaultTimeout) { done in
                        connectionHandle.connect(sessionUUID: nil) {
                            connectionHandle.getSessionUuid() { outcome in
                                switch outcome {
                                case .PubSubSuccess(let success):
                                    let successResponse = success as! PubSubResponse

                                    expect(successResponse.action == PubSubAction.sessionUuid.rawValue).to(beTruthy())
                                    expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                    expect(successResponse.uuid).toNot(beNil())
                                    expect(successResponse.uuid!).toNot(beEmpty())
                                case .PubSubResponseError(let errorResponse):

                                    expect(errorResponse.action == PubSubAction.sessionUuid.rawValue).to(beTruthy())
                                    expect(errorResponse.code).toNot(equal(PubSubResponseCode.success.rawValue))
                                }

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
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { outcome in
                                        switch outcome {
                                        case .PubSubSuccess(let success):
                                            let successResponse = success as! PubSubResponse

                                            expect(successResponse.action == PubSubAction.subscribe.rawValue).to(beTruthy())
                                            expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                            expect(successResponse.channels).toNot(beNil())
                                            expect(successResponse.channels!).toNot(beEmpty())
                                            expect(successResponse.channels!.count).to(equal(1))

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
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { outcome in
                                        switch outcome {
                                        case .PubSubResponseError(let errorResponse):
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
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))

                        it("is successfull") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.listSubscriptions() { outcome in

                                            switch outcome {
                                            case .PubSubSuccess(let success):
                                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                                expect(successResponse.action) == PubSubAction.subscriptions.rawValue
                                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                                expect(successResponse.channels).toNot(beNil())
                                                expect(successResponse.channels!).toNot(beEmpty())
                                                expect(successResponse.channels!.count).to(equal(1))

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
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.listSubscriptions() { outcome in
                                        switch outcome {
                                        case .PubSubResponseError(let errorResponse):
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
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))

                        it("is successfull") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
                                            switch outcome {
                                            case .PubSubSuccess(let success):
                                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                                expect(successResponse.action) == PubSubAction.unsubscribe.rawValue
                                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                                expect(successResponse.channels).toNot(beNil())
                                                expect(successResponse.channels!).to(beEmpty())

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
                                    case .PubSubResponseError(let errorResponse):
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
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
                                        switch outcome {
                                        case .PubSubResponseError(let errorResponse):
                                            expect(errorResponse.action) == PubSubAction.unsubscribe.rawValue
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

                describe("unsubscribe from all channels") {
                    context("when read key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("is successfull") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: "Test", messageHandler: nil) { _ in
                                        connectionHandle.subscribe(channelName: "Test2", messageHandler: nil) { _ in
                                            connectionHandle.unsubscribeAll() { outcome in
                                                switch outcome {
                                                case.PubSubSuccess(let success):
                                                    guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                                    expect(successResponse.action) == PubSubAction.unsubscribeAll.rawValue
                                                    expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                                    expect(successResponse.channels).toNot(beNil())
                                                    expect(successResponse.channels!).toNot(beEmpty())
                                                    expect(successResponse.channels!.count).to(equal(2))

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
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {

                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.unsubscribeAll() { outcome in
                                        switch outcome {
                                        case .PubSubResponseError(let errorRespoinse):
                                            expect(errorRespoinse.action) == PubSubAction.unsubscribeAll.rawValue
                                            expect(errorRespoinse.code).to(equal(PubSubResponseCode.unauthorised.rawValue))

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

            describe("publish messages") {
                let testChannelName = "Test channel"
                let testMessage = "Test message"

                describe("publish") {
                    context("when write key is supplied") {
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("is succesfull") {

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
                                    case .PubSubResponseError(let errorResponse):
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

                    context("when write key in not supplied") {
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
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
                        let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        xit("is successfull") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { outcome in
                                            switch outcome {
                                            case .PubSubSuccess(let success):
                                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                                expect(successResponse.action) == PubSubAction.publish.rawValue
                                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                                expect(successResponse.messageUUID).toNot(beNil())
                                                expect(successResponse.messageUUID).toNot(beEmpty())

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
                                        case .PubSubResponseError(let errorResponse):
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
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        it("returns unauthorised") {
                            waitUntil(timeout: defaultTimeout) { done in
                                connectionHandle.connect(sessionUUID: nil) {
                                    connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { _ in
                                        connectionHandle.publishWithAck(channelName: testChannelName, message: testMessage) { outcome in
                                            switch outcome {
                                            case .PubSubResponseError(let errorResponse):
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

        func getSessionUUID(_ connectionHandle: PubSubConnectionHandle, completion: @escaping (String) -> Void) {
            connectionHandle.getSessionUuid() { outcome in
                switch outcome {
                case .PubSubSuccess(let success):
                    guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                    expect(successResponse.action) == PubSubAction.sessionUuid.rawValue
                    expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                    expect(successResponse.uuid).toNot(beNil())
                    expect(successResponse.uuid!).toNot(beEmpty())

                    completion(successResponse.uuid!)

                default:
                    fail("Expected success, got error response")
                }
            }
        }

        describe("Full Sweep Test") {
            let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                          options: PubSubOptions(url: url,
                                                                                 timeout: 30,
                                                                                 autoReconnect: false))

            it("is successfull") {
                waitUntil(timeout: defaultTimeout) { done in
                    connectionHandle.connect(sessionUUID: nil) {
                        connectionHandle.subscribe(channelName: testChannelName, messageHandler: nil) { outcome in
                            switch outcome {
                            case .PubSubSuccess(let success):
                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                expect(successResponse.action) == PubSubAction.subscribe.rawValue
                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                expect(successResponse.channels).toNot(beNil())
                                expect(successResponse.channels!).toNot(beEmpty())
                                expect(successResponse.channels!.count).to(equal(1))

                            default:
                                fail("Expected success, got error response")
                            }

                            connectionHandle.listSubscriptions() { outcome in
                                switch outcome {
                                case .PubSubSuccess(let success):
                                    guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                    expect(successResponse.action) == PubSubAction.subscriptions.rawValue
                                    expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                    expect(successResponse.channels).toNot(beNil())
                                    expect(successResponse.channels!).toNot(beEmpty())
                                    expect(successResponse.channels!.count).to(equal(1))

                                default:
                                    fail("Expected success, got error response")
                                }

                                connectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                            }
                        }
                    }

                    connectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannelName
                        expect(message.message) == testMessage

                        connectionHandle.unsubscribe(channelName: testChannelName) { outcome in
                            switch outcome {
                            case .PubSubSuccess(let success):
                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                expect(successResponse.action) == PubSubAction.unsubscribe.rawValue
                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                expect(successResponse.channels).toNot(beNil())
                                expect(successResponse.channels!).to(beEmpty())

                            default:
                                fail("Expected success, got error response")
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
            var firstFinished: Bool = false
            var secondFinished: Bool = false

            let clientOneConnectionHandle = pubSubService.connnect(keys: allKeys,
                                                                   options: PubSubOptions(url: url,
                                                                                          timeout: 30,
                                                                                          autoReconnect: false))

            let clientTwoConnectionHandle = pubSubService.connnect(keys: allKeys,
                                                                   options: PubSubOptions(url: url,
                                                                                          timeout: 30,
                                                                                          autoReconnect: false))

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
                            case .PubSubSuccess(let success):
                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                expect(successResponse.action) == PubSubAction.subscribe.rawValue
                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                expect(successResponse.channels).toNot(beNil())
                                expect(successResponse.channels!).toNot(beEmpty())
                                expect(successResponse.channels!.count).to(equal(1))

                            default:
                                fail("Expected success, got error response")
                            }

                            clientOneConnectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                        })
                    }

                    clientTwoConnectionHandle.connect(sessionUUID: nil) {
                        clientTwoConnectionHandle.subscribe(channelName: testChannelName, messageHandler: { message in

                            expect(message).toNot(beNil())
                            expect(message.action) == PubSubAction.message.rawValue
                            expect(message.channel) == testChannelName
                            expect(message.message) == testMessage

                        }, completion: { outcome in
                            switch outcome {
                            case .PubSubSuccess(let success):
                                guard let successResponse = success as? PubSubResponse  else { fail("Could not cast to PubSubResponse"); return }

                                expect(successResponse.action) == PubSubAction.subscribe.rawValue
                                expect(successResponse.code).to(equal(PubSubResponseCode.success.rawValue))
                                expect(successResponse.channels).toNot(beNil())
                                expect(successResponse.channels!).toNot(beEmpty())
                                expect(successResponse.channels!.count).to(equal(1))

                            default:
                                fail("Expected success, got error response")
                            }

                            clientTwoConnectionHandle.publish(channelName: testChannelName, message: testMessage) { _ in }
                        })
                    }

                    clientOneConnectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannelName
                        expect(message.message) == testMessage

                        firstFinished = true

                        if firstFinished && secondFinished {
                            clientOneConnectionHandle.close()
                            clientTwoConnectionHandle.close()

                            done()
                        }
                    }

                    clientTwoConnectionHandle.onMessage = { message in
                        expect(message.action) == PubSubAction.message.rawValue
                        expect(message.channel) == testChannelName
                        expect(message.message) == testMessage

                        secondFinished = true

                        if firstFinished && secondFinished {
                            clientOneConnectionHandle.close()
                            clientTwoConnectionHandle.close()

                            done()
                        }
                    }
                }
            }
        }

        describe("Reconnect Test") {
            var sessionUUID: String!
            let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                          options: PubSubOptions(url: url,
                                                                                 timeout: 30,
                                                                                 autoReconnect: true))
            afterEach {
                connectionHandle.close()
            }

            it("successfully restores current session") {
                waitUntil(timeout: 10) { done in
                    connectionHandle.connect(sessionUUID: nil) {
                        getSessionUUID(connectionHandle) { uuid in
                            sessionUUID = uuid

                            connectionHandle.close()
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

            xit("successfully opens new session") {
                waitUntil(timeout: 310) { done in
                    getSessionUUID(connectionHandle) { uuid in
                        sessionUUID = uuid

                        connectionHandle.close()
                        sleep(300)
                    }

                    connectionHandle.onReconnect = {
                        getSessionUUID(connectionHandle) { uuid in

                            expect(uuid != sessionUUID).to(beTruthy())

                            done()
                        }
                    }
                }
            }
        }

        describe("Get Session Uuid Test") {
            let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                          options: PubSubOptions(url: url,
                                                                                 timeout: 30,
                                                                                 autoReconnect: false))
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
            let connectionHandle = pubSubService.connnect(keys: allKeys,
                                                          options: PubSubOptions(url: url,
                                                                                 timeout: 30,
                                                                                 autoReconnect: false))
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
                    var isEmitting: Bool = false
                    var error: PubSubErrorResponse?

                    fit("emits an error") {
                        let connectionHandle = pubSubService.connnect(keys: noReadKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
                        waitUntil(timeout: 10) { done in
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
                    var isEmitting: Bool = false
                    var error: PubSubErrorResponse?
                    
                    fit("emits an error") {
                        let connectionHandle = pubSubService.connnect(keys: noWriteKeys,
                                                                      options: PubSubOptions(url: url,
                                                                                             timeout: 30,
                                                                                             autoReconnect: false))
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
                
            }
            
            describe("onClose Test") {
                var isEmitting: Bool = false
                
                it("emits close event") {
                    waitUntil(timeout: 10) { done in
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
                
                it("on new session event") {
                    waitUntil(timeout: 10) { done in
                        
                        connectionHandle.connect(sessionUUID: nil) {
                            connectionHandle.close()
                        }
                        
                        connectionHandle.onClose = { (error) in
                            connectionHandle.connect(sessionUUID: nil)
                        }
                        
                        connectionHandle.onNewSession = { uuid in
                            isEmitting = true
                            sessionUuid = uuid
                            
                            done()
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
