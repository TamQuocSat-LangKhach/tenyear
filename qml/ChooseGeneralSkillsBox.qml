// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var cards: []
  property var skills: []
  property var selected: []
  property int min
  property int max
  property string prompt
  property bool cancelable: false

  title.text: Backend.translate(prompt !== "" ? processPrompt(prompt) : "$ChooseCard")
  // TODO: Adjust the UI design in case there are more than 7 cards
  width: 50 + Math.max(4, cards.length) * 100
  height: 340

  Component {
    id: cardDelegate
    GeneralCardItem {
      name: modelData
      autoBack: false
      selectable: true

      onRightClicked: {
        roomScene.startCheat("GeneralDetail", { generals: [modelData] });
      }
    }
  }

  function processPrompt(prompt) {
    const data = prompt.split(":");
    let raw = Backend.translate(data[0]);
    const src = parseInt(data[1]);
    const dest = parseInt(data[2]);
    if (raw.match("%src")) raw = raw.replace(/%src/g, Backend.translate(getPhoto(src).general));
    if (raw.match("%dest")) raw = raw.replace(/%dest/g, Backend.translate(getPhoto(dest).general));
    if (raw.match("%arg2")) raw = raw.replace(/%arg2/g, Backend.translate(data[4]));
    if (raw.match("%arg")) raw = raw.replace(/%arg/g, Backend.translate(data[3]));
    return raw;
  }

  Row {
    id: generalArea
    x: 20
    y: 35
    spacing: 5
    Repeater {
      id: to_select
      model: cards
      delegate: cardDelegate
    }
  }

  Flickable {
    id: flickableContainer
    ScrollBar.horizontal: ScrollBar {}

    flickableDirection: Flickable.VerticalFlick
    anchors.fill: parent
    anchors.topMargin: 175
    anchors.leftMargin: 5
    anchors.rightMargin: 5
    anchors.bottomMargin: 50

    contentWidth: skillColumn.width
    contentHeight: skillColumn.height
    clip: true

    RowLayout {
      id: skillColumn
      x: 22
      y: 0
      spacing: 18

      Repeater {
        id: skillList
        model: skills

        ColumnLayout {
          id: skillRow
          x: 0
          y: 0
          spacing: 5
          Layout.alignment: Qt.AlignTop

          Repeater {
            model: modelData
            id: skill_buttons

            SkillButton {
              skill: Backend.translate(modelData)
              type: "active"
              enabled: true
              orig: modelData

              onPressedChanged: {
                if (pressed) {
                  root.selected.push(orig);
                } else {
                  root.selected.splice(root.selected.indexOf(orig), 1);
                }

                root.updateSelectable();
              }
            }

          }
        }

      }
    }
  }

  Row {
    id: buttons
    anchors.margins: 8
    anchors.top: flickableContainer.bottom
    anchors.horizontalCenter: root.horizontalCenter
    spacing: 32

    MetroButton {
      width: 120
      Layout.fillWidth: true
      text: processPrompt("OK")
      id: buttonConfirm

      onClicked: {
        close();
        roomScene.state = "notactive";
        ClientInstance.replyToServer("", JSON.stringify(root.selected));
      }
    }

    MetroButton {
      width: 100
      Layout.fillWidth: true
      text: processPrompt("Cancel")
      visible: cancelable

      onClicked: {
        root.close();
        roomScene.state = "notactive";
        ClientInstance.replyToServer("", JSON.stringify(root.selected));
      }
    }
  }

  function updateSelectable() {
    buttonConfirm.enabled = (selected.length <= max && selected.length >= min);
  }

  function loadData(data) {
    const d = data;
    cards = d[0];
    skills = d[1];
    min = d[2];
    max = d[3];
    prompt = d[4];
    cancelable = d[5];
  
    updateSelectable()
  }
}

