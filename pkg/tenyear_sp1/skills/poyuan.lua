local poyuan = fk.CreateSkill {
  name = "poyuan"
}

Fk:loadTranslationTable{
  ['poyuan'] = '破垣',
  ['#poyuan-choose'] = '破垣：你可以弃置一名其他角色至多两张牌',
  ['#poyuan-invoke'] = '破垣：你可以装备【霹雳车】',
  [':poyuan'] = '游戏开始时或回合开始时，若你的装备区里没有【霹雳车】，你可以将【霹雳车】置于装备区；若有，你可以弃置一名其他角色至多两张牌。<br><font color=>【霹雳车】<br>♦9 装备牌·宝物<br /><b>装备技能</b>：锁定技，你回合内使用基本牌的伤害和回复数值+1且无距离限制。你回合外使用或打出基本牌时摸一张牌。离开你装备区时销毁。',
  ['$poyuan1'] = '砲石飞空，坚垣难存。',
  ['$poyuan2'] = '声若霹雳，人马俱摧。',
}

poyuan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(poyuan.name) then
      if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
        return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
      else
        local catapult = table.find(U.prepareDeriveCards(player.room, poyuan_catapult, "poyuan_catapult"), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and U.canMoveCardIntoEquip(player, catapult)
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#poyuan-choose",
        skill_name = poyuan.name,
        cancelable = true,
      })
      if #tos > 0 then
        event:setCostData(self, tos[1]:objectName())
        return true
      end
    else
      return room:askToSkillInvoke(player, {
        skill_name = poyuan.name,
        prompt = "#poyuan-invoke",
      })
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local to = room:getPlayerById(event:getCostData(self))
      local cards = room:askToChooseCards(player, {
        target = to,
        min_num = 1,
        max_num = 2,
        flag = "he",
        skill_name = poyuan.name,
      })
      room:throwCard(cards, poyuan.name, to, player)
    else
      local catapult = table.find(U.prepareDeriveCards(room, poyuan_catapult, "poyuan_catapult"), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
        room:moveCardIntoEquip(player, catapult, poyuan.name, true, player)
      end
    end
  end,
})

poyuan:addEffect(fk.TurnStart, {
  can_trigger = function(self, event, target, player)
    if player:hasSkill(poyuan.name) and (event == fk.GameStart or (event == fk.TurnStart and target == player)) then
      if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
        return table.find(player.room:getOtherPlayers(player), function(p) return not p:isNude() end)
      else
        local catapult = table.find(U.prepareDeriveCards(player.room, poyuan_catapult, "poyuan_catapult"), function (id)
          return player.room:getCardArea(id) == Card.Void
        end)
        return catapult and U.canMoveCardIntoEquip(player, catapult)
      end
    end
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isNude() end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#poyuan-choose",
        skill_name = poyuan.name,
        cancelable = true,
      })
      if #tos > 0 then
        event:setCostData(self, tos[1]:objectName())
        return true
      end
    else
      return room:askToSkillInvoke(player, {
        skill_name = poyuan.name,
        prompt = "#poyuan-invoke",
      })
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if table.find(player:getEquipments(Card.SubtypeTreasure), function(id) return Fk:getCardById(id).name == "ty__catapult" end) then
      local to = room:getPlayerById(event:getCostData(self))
      local cards = room:askToChooseCards(player, {
        target = to,
        min_num = 1,
        max_num = 2,
        flag = "he",
        skill_name = poyuan.name,
      })
      room:throwCard(cards, poyuan.name, to, player)
    else
      local catapult = table.find(U.prepareDeriveCards(room, poyuan_catapult, "poyuan_catapult"), function (id)
        return player.room:getCardArea(id) == Card.Void
      end)
      if catapult then
        room:setCardMark(Fk:getCardById(catapult), MarkEnum.DestructOutMyEquip, 1)
        room:moveCardIntoEquip(player, catapult, poyuan.name, true, player)
      end
    end
  end,
})

return poyuan
