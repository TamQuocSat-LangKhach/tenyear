local zhanyi = fk.CreateSkill {
  name = "ty__zhanyi",
  dynamic_desc = function (self, player)
    local str = "ty__zhanyi_inner"
    for _, type in ipairs({"basic", "trick", "equip"}) do
      if table.contains(player:getTableMark(self.name), type) then
        str = str..":<font color=\"#E0DB2F\">"..Fk:translate("ty__zhanyi_"..type).."</font>"
      else
        str = str..":"..Fk:translate("ty__zhanyi_"..type)
      end
    end
    return str
  end,
}

Fk:loadTranslationTable{
  ["ty__zhanyi"] = "战意",
  [":ty__zhanyi"] = "出牌阶段开始时，你可以弃置一种类别的所有牌，另外两种类别的牌获得以下效果直到你的下个回合开始：<br>"..
  "基本牌，你使用基本牌无距离限制且造成的伤害和回复值+1；<br>"..
  "锦囊牌，你使用锦囊牌时摸一张牌，你的锦囊牌不计入手牌上限；<br>"..
  "装备牌，当装备牌置入你的装备区后，可以弃置一名其他角色的一张牌。",

  [":ty__zhanyi_inner"] = "出牌阶段开始时，你可以弃置一种类别的所有牌，另外两种类别的牌获得以下效果直到你的下个回合开始：<br>{1}{2}{3}",
  ["ty__zhanyi_basic"] = "基本牌，你使用基本牌无距离限制且造成的伤害和回复值+1；<br>",
  ["ty__zhanyi_trick"] = "锦囊牌，你使用锦囊牌时摸一张牌，你的锦囊牌不计入手牌上限；<br>",
  ["ty__zhanyi_equip"] = "装备牌，当装备牌置入你的装备区后，可以弃置一名其他角色的一张牌。",

  ["#ty__zhanyi-choice"] = "战意：弃置一种类别所有的牌，另外两种类别的牌获得额外效果",
  ["#ty__zhanyi-discard"] = "战意：你可以弃置一名角色一张牌",

  ["$ty__zhanyi1"] = "此命不已，此战不休！",
  ["$ty__zhanyi2"] = "以役兴国，战意磅礴！",
}

zhanyi:addEffect(fk.EventPhaseStart, {
  anim_type = "special",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhanyi.name) and player.phase == Player.Play and
      not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local all_choices = {"basic", "trick", "equip", "Cancel"}
    local choices = table.filter(all_choices, function(type)
      return table.find(player:getCardIds("he"), function (id)
        return Fk:getCardById(id):getTypeString() == type and not player:prohibitDiscard(id)
      end) ~= nil
    end)
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zhanyi.name,
      prompt = "#ty__zhanyi-choice",
      detailed = false,
      all_choices = all_choices,
    })
    if choice ~= "Cancel" then
      event:setCostData(self, {choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local types = {"basic", "trick", "equip"}
    local type = event:getCostData(self).choice
    table.removeOne(types, type)
    local mark = player:getTableMark(zhanyi.name)
    table.insertTableIfNeed(mark, types)
    room:setPlayerMark(player, zhanyi.name, mark)
    local cards = table.filter(player:getCardIds("he"), function(id)
      return Fk:getCardById(id):getTypeString() == type and not player:prohibitDiscard(id)
    end)
    room:throwCard(cards, zhanyi.name, player, player)
  end,
})

zhanyi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(zhanyi.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, zhanyi.name, 0)
  end,
})

zhanyi:addEffect(fk.CardUsing, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and not player.dead and
      table.contains(player:getTableMark(zhanyi.name), data.card:getTypeString()) then
      if data.card.type == Card.TypeBasic then
        return data.card.is_damage_card or data.card.name == "peach" or
          (data.card.name == "analeptic" and data.extra_data and data.extra_data.analepticRecover)
      elseif data.card.type == Card.TypeTrick then
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(zhanyi.name)
    if data.card.type == Card.TypeBasic then
      if data.card.is_damage_card then
        room:notifySkillInvoked(player, zhanyi.name, "offensive")
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif data.card.name == "peach" then
        room:notifySkillInvoked(player, zhanyi.name, "support")
        data.additionalRecover = (data.additionalRecover or 0) + 1
      elseif data.card.name == "analeptic" and data.extra_data and data.extra_data.analepticRecover then
        room:notifySkillInvoked(player, zhanyi.name, "support")
        data.additionalRecover = (data.additionalRecover or 0) + 1
      end
    elseif data.card.type == Card.TypeTrick then
      room:notifySkillInvoked(player, zhanyi.name, "drawcard")
      player:drawCards(1, zhanyi.name)
    end
  end,
})

zhanyi:addEffect(fk.AfterCardsMove, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if table.contains(player:getTableMark(zhanyi.name), "equip") then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerEquip then
          return table.find(player.room:getOtherPlayers(player, false), function (p)
            return not p:isNude()
          end)
        end
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = zhanyi.name,
      prompt = "#ty__zhanyi-discard",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "he",
      skill_name = zhanyi.name,
    })
    room:throwCard(id, zhanyi.name, to, player)
  end,
})

zhanyi:addEffect("targetmod", {
  bypass_distances = function(self, player, skill, card)
    return table.contains(player:getTableMark(zhanyi.name), "basic") and card and card.type == Card.TypeBasic
  end,
})

zhanyi:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return table.contains(player:getTableMark(zhanyi.name), "trick") and card.type == Card.TypeTrick
  end,
})

return zhanyi
