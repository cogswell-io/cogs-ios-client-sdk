<!-- toc -->
- [Cogs Pub/Sub Service](#cogs-pubsub-service)
- [Cogs Pub/Sub ConnectionHandle API](#cogs-pubsub-connectionhandle-api)
  - [connection.getSessionUuid(completion:)](#connectiongetsessionuuidcompletion)
  - [connection.subscribe(channelName:messageHandler:completion:)](#connectionsubscribechannelnamemessagehandlercompletion)
  - [connection.connection.unsubscribe(channelName:completion:)](#connectionunsubscribechannelnamecompletion)
  - [connection.unsubscribeAll(completion:)](#connectionunsubscribeallcompletion)
  - [connection.listSubscriptions(completion:)](#connectionlistsubscriptionscompletion)
  - [connection.publish(channelName:message:failure:)](#connectionpublishchannelnamemessagefailure)
  - [connection.publishWithAck(channelName:message:completion:)](#connectionpublishwithackchannelnamemessagecompletion)
  - [connection.dropConnection()](#connectiondropconnection)
  - [connection.close()](#connectionclose)
  - [Connection Events](#connection-events)
    - [Event: onRawRecord](#event-onrawrecord)
    - [Event: onMessage](#event-onmessage)
    - [Event: onError](#event-onerror)
    - [Event: onReconnect](#event-onreconnect)
    - [Event: onClose](#event-onclose)
    - [Event: onNewSession](#event-onnewsession)
<!-- tocstop -->

# Cogs Pub/Sub Service
Create a ```PubSubService``` object to obtain a connection handle. The created ```PubSubConnectionHandle``` object creates and initializes a web socket but doesn't establish a connection until its own ```connect``` method is called. The reason is that event handlers should be set before that.  

```swift
let keys: [String] = ["read key", "write key", "admin key"]
        
let pubSubService = PubSubService()
let connection = pubSubService.connnect(keys: keys,
                                              options: PubSubOptions(url: url,
                                                                     timeout: 30,
                                                                     autoReconnect: true))
```

# Cogs Pub/Sub ConnectionHandle API
This is a summary of all functions exposed by the ```PubSubConnectionHandle``` object, and examples of their usage.

## connection.connect(sessionUUID:completion:)
Starts the connection with the websocket. If no ```sessionUUID``` is provided a new connection will be established else the previous session will be restored if possible.
 
```swift
connection.connect(sessionUUID: nil)
or
connectionHandler.connect(sessionUUID: "aeabb570-050a-11e7-8ee5-8ff1f5240fbb")
```

## connection.getSessionUuid(completion:)
Fetch the session UUID from the server. The successful result contains the UUID associated with this connection's session.

```swift
connection.getSessionUuid { outcome in
    switch outcome {
        case .pubSubSuccess(let uuid):
            print("Session uuid \(uuid)")

        case .pubSubResponseError(let error):
            print(error)
    }
}
```

## connection.subscribe(channelName:messageHandler:completion:)
Subscribes the connection to a channel, supplying a handler which will be called with each message received from this channel. The successful result contains a list of the subscribed channels.The connection needs read permissions in order to subscribe to a channel.

```swift
connection.subscribe(channelName: channelName,
                  messageHandler: { (message) in
                    print("\(message.id) | \(message.message)")
        }) { outcome in
            switch outcome {
            case .pubSubSuccess(let subscribedChannels):
                print(subscribedChannels)
                
            case .pubSubResponseError(let error):
                print(error)
            }
        }
```

## connection.unsubscribe(channelName:completion:)
Unsubscribes the connection from a particular channel. The successful result contains an array with currently subscribed channels without the channel just unsubscribed from. The connection needs read permission in order to unsubscribe from the channel.

```swift
connection.unsubscribe(channelName: channelName){ outcome in
    switch outcome {
    case .pubSubSuccess(let subscribedChannels):
        print(subscribedChannels) //The list won't include the channel to unsubscribe from

    case .pubSubResponseError(let error):
        print(error)
    }
}
```
## connection.unsubscribeAll(completion:)
Unsubscribes connection from all channels. The successful result should be an empty array. The connection needs read permission in order to unsubscribe from all channels.

```swift
connection.unsubscribeAll(){ outcome in
    switch outcome {
    case .pubSubSuccess(let subscribedChannels):
        print(subscribedChannels)
        // This is the list of channels to which we were subscribed prior to running this operation.

    case .pubSubResponseError(let error):
        print(error)
    }
}
```

## connection.listSubscriptions(completion:)
Gets all subscriptions. The successful result contains an array with currently subscribed channels.

```swift
connection.listSubscriptions(){ outcome in
    switch outcome {
    case .pubSubSuccess(let subscribedChannels):
        print(subscribedChannels)

    case .pubSubResponseError(let error):
        print(error)
    }
}
```

## connection.publish(channelName:message:failure:)
Publishes a message to a channel. The connection must have write permissions to successfully publish a message. The message string is limited to 64KiB. Messages that exceed this limit will result in the termination of the websocket connection.

```swift
connection.publish(channelName: channel, message: messageText){ error in
    print(error as Any)
}
```

## connection.publishWithAck(channelName:message:completion:)
Publishes a message to a channel. The successful result contains the UUID of the published message.

```swift
connection.publishWithAck(channelName: channel, message: messageText){ outcome in
    switch outcome {
    case .pubSubSuccess(let messadeUuid):
        print(messadeUuid)

    case .pubSubResponseError(let error):
        print(error)
    }
}
```

## connection.dropConnection()
Drops connection.

```swift
connection.dropConnection()
```

## connection.close()
Closes the pub/sub connection handle by closing the WebSocket.

```swift
connection.close()
```

## Connection Events

### Event: onRawRecord
The ```onRawRecord``` event is emitted for every raw record received from the server, whether a response to a request or a message. This is mostly useful for debugging issues with server communication.

```swift
connection.onRawRecord = { (record) in
  print (record)
}
```

### Event: onMessage
The ```onMessage``` event is emitted whenever the socket receives messages from any channel.

```swift
connection.onMessage = { (receivedMessage) in
    print (receivedMessage)
}
```

### Event: onError
The ```onError``` event is emitted on any connection errors, failed publishes, or when any exception is thrown.

```swift
connection.onError = { (error) in
    print(error.localizedDescription)
}
```

### Event: onErrorResponse
The ```onErrorResponse``` event is emitted whenever a message is sent to the user with an error status code.

```swift
connection.onErrorResponse = { (responseError) in
  print("\(responseError.message) \n \(responseError.code)")
}
```

### Event: onReconnect
The ```onReconnect``` event is emitted on socket reconnection if it disconnected for any reason.

```swift
connection.onReconnect = {
    print("Session is restored")
}
```

### Event: onClose
The ```onClose``` event is emitted whenever the socket connection closes.

```swift
connection.onClose = { (error) in
    if let err = error {
        print(err.localizedDescription)
    } else {
        print("Session is closed")
    }
}
```

### Event: onNewSession
The ```onNewSession``` event indicates that the session associated with this connection is not a resumed session, therefore there are no subscriptions associated with this session. If there had been a previous session and the connection was replaced by an auto-reconnect, the previous session was not restored resulting in all subscriptions being lost.

```swift
connection.onNewSession = { sessionUUID in
    print("New session \(sessionUUID) is opened."
}
```

