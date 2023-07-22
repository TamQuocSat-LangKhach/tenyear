// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Fk.Pages
import Fk.RoomElement

GraphicsBox {
  id: root

  property var selected_ids: []
  property string prompt: ""
  property var cards: []
  property int max: 0
  property int min: 0

  title.text: Backend.translate("$ChooseCards").arg(root.min).arg(root.max)

  width: 740
  height: 430

  Component {
    id: cardDelegate
    CardItem {
      Component.onCompleted: {
        setData(modelData);
      }
      autoBack: false
      selectable: true
      onSelectedChanged: {
        if (selected) {
          virt_name = 'is_selected';
          root.selected_ids.push(cid);
        } else {
          virt_name = '';
          root.selected_ids.splice(root.selected_ids.indexOf(cid), 1);
        }
        root.selected_idsChanged();
        root.updateCardSelectable();
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.topMargin: 40
    anchors.leftMargin: 20
    anchors.rightMargin: 20
    anchors.bottomMargin: 20

    Flickable {
      id: flickableContainer
      ScrollBar.vertical: ScrollBar {}
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 0
      flickableDirection: Flickable.VerticalFlick
      width: parent.width
      height: parent.height - 50
      contentWidth: cardsList.width
      contentHeight: cardsList.height
      clip: true

      ColumnLayout {
        id: cardsList

        GridLayout {
          columns: 7

          Repeater {
            id: to_select
            model: cards
            delegate: cardDelegate
          }
        }
      }
    }
    
    MetroButton {
      text: Backend.translate("OK")
      enabled: root.selected_ids.length <= root.max && root.selected_ids.length >= root.min
      onClicked: {
        close();
        ClientInstance.replyToServer("", JSON.stringify(root.selected_ids));
      }
    }
  }

  function updateCardSelectable() {
    for (let i = 0; i < cards.length; i++) {
      const item = to_select.itemAt(i);
      if (item.selected) continue;
      item.selectable = root.selected_ids.length < root.max;
    }
  }

  function loadData(data) {
    const d = data;
    cards = d[0].map(cid => {
      return JSON.parse(Backend.callLuaFunction("GetCardData", [cid]));
    });
    min = d[1];
    max = d[2];
  }
}
