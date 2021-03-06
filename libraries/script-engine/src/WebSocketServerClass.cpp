//
//  WebSocketServerClass.cpp
//  libraries/script-engine/src/
//
//  Created by Thijs Wenker on 8/10/15.
//  Copyright (c) 2015 High Fidelity, Inc. All rights reserved.
//
//  Making WebSocketServer accessible through scripting.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

#include "ScriptEngine.h"
#include "WebSocketServerClass.h"

WebSocketServerClass::WebSocketServerClass(QScriptEngine* engine, const QString& serverName, const quint16 port) :
    _webSocketServer(serverName, QWebSocketServer::SslMode::NonSecureMode),
    _engine(engine)
{
    if (_webSocketServer.listen(QHostAddress::Any, port)) {
        connect(&_webSocketServer, &QWebSocketServer::newConnection, this, &WebSocketServerClass::onNewConnection);
    }
}

QScriptValue WebSocketServerClass::constructor(QScriptContext* context, QScriptEngine* engine) {
    // the serverName is used in handshakes
    QString serverName = QStringLiteral("HighFidelity - Scripted WebSocket Listener");
    // port 0 will auto-assign a free port
    quint16 port = 0;
    QScriptValue callee = context->callee();
    if (context->argumentCount() > 0) {
        QScriptValue options = context->argument(0);
        QScriptValue portOption = options.property(QStringLiteral("port"));
        if (portOption.isValid() && portOption.isNumber()) {
            port = portOption.toNumber();
        }
        QScriptValue serverNameOption = options.property(QStringLiteral("serverName"));
        if (serverNameOption.isValid() && serverNameOption.isString()) {
            serverName = serverNameOption.toString();
        }
    }
    return engine->newQObject(new WebSocketServerClass(engine, serverName, port), QScriptEngine::ScriptOwnership);
}

WebSocketServerClass::~WebSocketServerClass() {
    if (_webSocketServer.isListening()) {
        close();
    }
    _clients.empty();
}

void WebSocketServerClass::onNewConnection() {
    WebSocketClass* newClient = new WebSocketClass(_engine, _webSocketServer.nextPendingConnection());
    _clients << newClient;
    connect(newClient->getWebSocket(), &QWebSocket::disconnected, [newClient, this]() {
        _clients.removeOne(newClient);
    });
    emit newConnection(newClient);
}

void WebSocketServerClass::close() {
    foreach(WebSocketClass* client, _clients) {
        if (client->getReadyState() != WebSocketClass::ReadyState::CLOSED) {
            client->close(QWebSocketProtocol::CloseCode::CloseCodeGoingAway, "Server closing.");
        }
    }
    _webSocketServer.close();
}
