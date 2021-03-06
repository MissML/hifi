//
//  UsernameCollisionBody.qml
//
//  Created by Clement on 7/18/16
//  Copyright 2015 High Fidelity, Inc.
//
//  Distributed under the Apache License, Version 2.0.
//  See the accompanying file LICENSE or http://www.apache.org/licenses/LICENSE-2.0.html
//

import Hifi 1.0
import QtQuick 2.4
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.4 as OriginalStyles

import "../controls-uit"
import "../styles-uit"

Item {
    id: usernameCollisionBody
    clip: true
    width: root.pane.width
    height: root.pane.height

    function create() {
        mainTextContainer.visible = false
        loginDialog.createAccountFromStream(textField.text)
    }

    QtObject {
        id: d
        readonly property int minWidth: 480
        readonly property int maxWidth: 1280
        readonly property int minHeight: 120
        readonly property int maxHeight: 720

        function resize() {
            var targetWidth = Math.max(titleWidth, Math.max(mainTextContainer.contentWidth,
                                                            termsContainer.contentWidth))
            var targetHeight =  mainTextContainer.height +
                                2 * hifi.dimensions.contentSpacing.y + textField.height +
                                5 * hifi.dimensions.contentSpacing.y + termsContainer.height +
                                1 * hifi.dimensions.contentSpacing.y + buttons.height

            root.width = Math.max(d.minWidth, Math.min(d.maxWidth, targetWidth))
            root.height = Math.max(d.minHeight, Math.min(d.maxHeight, targetHeight))
        }
    }

    ShortcutText {
        id: mainTextContainer
        anchors {
            top: parent.top
            left: parent.left
            margins: 0
            topMargin: hifi.dimensions.contentSpacing.y
        }

        text: qsTr("Your Steam username is not available.")
        wrapMode: Text.WordWrap
        color: hifi.colors.redAccent
        lineHeight: 1
        lineHeightMode: Text.ProportionalHeight
        horizontalAlignment: Text.AlignHCenter
    }


    TextField {
        id: textField
        anchors {
            top: mainTextContainer.bottom
            left: parent.left
            margins: 0
            topMargin: 2 * hifi.dimensions.contentSpacing.y
        }
        width: 250

        placeholderText: "Choose your own"
    }

    InfoItem {
        id: termsContainer
        anchors {
            top: textField.bottom
            left: parent.left
            margins: 0
            topMargin: 3 * hifi.dimensions.contentSpacing.y
        }

        text: qsTr("By creating this user profile, you agree to <a href='https://highfidelity.com/terms'>High Fidelity's Terms of Service</a>")
        wrapMode: Text.WordWrap
        color: hifi.colors.baseGrayHighlight
        lineHeight: 1
        lineHeightMode: Text.ProportionalHeight
        horizontalAlignment: Text.AlignHCenter

        onLinkActivated: loginDialog.openUrl(link)
    }

    Row {
        id: buttons
        anchors {
            top: termsContainer.bottom
            right: parent.right
            margins: 0
            topMargin: 1 * hifi.dimensions.contentSpacing.y
        }
        spacing: hifi.dimensions.contentSpacing.x
        onHeightChanged: d.resize(); onWidthChanged: d.resize();

        Button {
            anchors.verticalCenter: parent.verticalCenter
            width: 200

            text: qsTr("Create your profile")
            color: hifi.buttons.blue

            onClicked: usernameCollisionBody.create()
        }

        Button {
            anchors.verticalCenter: parent.verticalCenter

            text: qsTr("Cancel")

            onClicked: root.destroy()
        }
    }

    Component.onCompleted: {
        root.title = qsTr("Complete Your Profile")
        root.iconText = "<"
        d.resize();
    }
    Connections {
        target: loginDialog
        onHandleCreateCompleted: {
            console.log("Create Succeeded")

            loginDialog.loginThroughSteam()
        }
        onHandleCreateFailed: {
            console.log("Create Failed: " + error)

            mainTextContainer.visible = true
            mainTextContainer.text = "\"" + textField.text + qsTr("\" is invalid or already taken.")
        }
        onHandleLoginCompleted: {
            console.log("Login Succeeded")

            bodyLoader.setSource("WelcomeBody.qml", { "welcomeBack" : false })
            bodyLoader.item.width = root.pane.width
            bodyLoader.item.height = root.pane.height
        }
        onHandleLoginFailed: {
            console.log("Login Failed")
        }
    }

    Keys.onPressed: {
        if (!visible) {
            return
        }

        switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                event.accepted = true
                usernameCollisionBody.create()
                break
        }
    }
}
