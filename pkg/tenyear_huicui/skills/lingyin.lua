local lingyin = fk.CreateSkill {
  name = "lingyin",
}

Fk:loadTranslationTable{
  ["lingyin"] = "铃音",
  [":lingyin"] = "出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且"..
  "可以将武器或防具牌当【决斗】使用。",

  ["#lingyin"] = "铃音：将一张武器牌或防具牌当【决斗】使用",
  ["@@lingyin-turn"] = "铃音",
  ["#lingyin-invoke"] = "铃音：获得至多%arg张“妄”，若剩余“妄”颜色相同，你本回合伤害+1且可以将武器和防具当【决斗】使用",

  ["$lingyin1"] = "环佩婉尔，心动情动铃儿动。",
  ["$lingyin2"] = "小鹿撞入我怀，银铃焉能不鸣？",
}

lingyin:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "duel",
  prompt = "#lingyin",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and (card.sub_type == Card.SubtypeWeapon or card.sub_type == Card.SubtypeArmor)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("duel")
    card:addSubcard(cards[1])
    return card
  end,
  enabled_at_play = function(self, player)
    return player:getMark("@@lingyin-turn") > 0
  end,
  enabled_at_response = function (self, player, response)
    return not response and player:getMark("@@lingyin-turn") > 0
  end,
})

lingyin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lingyin.name) and
      player.phase == Player.Play and #player:getPile("ruiji_wang") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = room:getBanner("RoundCount")
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = n,
      pattern = ".|.|.|ruiji_wang",
      prompt = "#lingyin-invoke:::" .. n,
      skill_name = lingyin.name,
      expand_pile = "ruiji_wang",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.simpleClone(event:getCostData(self).cards)
    local colors = {}
    for _, id in ipairs(player:getPile("ruiji_wang")) do
      if not table.contains(cards, id) then
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
    end
    table.removeOne(colors, Card.NoColor)
    if #colors < 2 then
      room:setPlayerMark(player, "@@lingyin-turn", 1)
    end
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, lingyin.name)
  end,
})

lingyin:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@lingyin-turn") > 0 and not data.chain and data.to ~= player
  end,
  on_use = function(self, event, target, player, data)
    data:changeDamage(1)
  end,
})

return lingyin
