// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var questionInfo: ({ question: "", optionA: "", optionB: "" })
  property string titleName: ""
  property int timeout: 10

  title.text: luatr(titleName)
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 500
  height: 200

  Column {
    width: parent.width
    anchors.top: parent.top
    anchors.topMargin: 50
    spacing: 10

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 18
      color: "white"
      text: luatr(questionInfo.question)
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      font.pixelSize: 18
      color: "white"
      text: luatr("lisao_countdown") + timeout
    }

    Timer {
      interval: 1000
      repeat: true
      running: true
      onTriggered: {
        timeout--;
      }
    }
  }

  Item {
    id: buttonArea
    anchors.fill: parent
    anchors.bottomMargin: 10
    height: 40

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      spacing: 8

      MetroButton {
        Layout.fillWidth: true
        text: luatr(questionInfo.optionA)
        enabled: true

        onClicked: {
          close();
          roomScene.state = "notactive";
          if (questionInfo.answer === 1) {
            ClientInstance.notifyServer("PushRequest", "updatemini,closeFrame");
            const reply = JSON.stringify({ right: '1' });
            ClientInstance.replyToServer("", reply);
          } else {
            ClientInstance.replyToServer("", "__cancel");
          }
        }
      }

      MetroButton {
        Layout.fillWidth: true
        enabled: true
        text: luatr(questionInfo.optionB)
        onClicked: {
          close();
          roomScene.state = "notactive";
          if (questionInfo.answer === 2) {
            ClientInstance.notifyServer("PushRequest", "updatemini,closeFrame");
            const reply = JSON.stringify({ right: '1' });
            ClientInstance.replyToServer("", reply);
          } else {
            ClientInstance.replyToServer("", "__cancel");
          }
        }
      }
    }
  }

  onTimeoutChanged: {
    if (timeout < 1) {
      close();
      roomScene.state = "notactive";
      ClientInstance.replyToServer("", "__cancel");
    }
  }

  function loadData(data) {
    questionInfo = data[0];
    titleName = data[1];
  }

  function updateData(data) {
    const type = data[0];
    if (type == "closeFrame") {
      close();
      roomScene.state = "notactive";
    }
  }
}
