local lingyin = fk.CreateSkill {
  name = "lingyin"
}

Fk:loadTranslationTable{
  ['lingyin'] = '铃音',
  ['#lingyin-viewas'] = '发动 铃音，将一张武器牌或防具牌当【决斗】使用',
  ['@@lingyin-turn'] = '铃音',
  ['ruiji_wang'] = '妄',
  ['liying'] = '俐影',
  ['#lingyin-invoke'] = '铃音：获得至多%arg张“妄”，然后若剩余“妄”颜色相同，你本回合伤害+1且可以将武器、防具当【决斗】使用',
  [':lingyin'] = '出牌阶段开始时，你可以获得至多X张“妄”（X为游戏轮数）。然后若“妄”颜色均相同，你本回合对其他角色造成的伤害+1且可以将武器或防具牌当【决斗】使用。',
  ['$lingyin1'] = '环佩婉尔，心动情动铃儿动。',
  ['$lingyin2'] = '小鹿撞入我怀，银铃焉能不鸣？',
}

-- ViewAsSkill
lingyin:addEffect('viewas', {
  anim_type = "offensive",
  prompt = "#lingyin-viewas",
  pattern = "duel",
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
})

-- TriggerSkill
lingyin:addEffect(fk.EventPhaseStart, {
  mute = true,
  expand_pile = "ruiji_wang",
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(lingyin.name) then
      return player.phase == Player.PhasePlay and #player:getPile("ruiji_wang") > 0
    end
  end,
  on_cost = function(self, event, target, player)
    local n = player.room:getBanner("RoundCount")
    local cards = player.room:askToCards(player, {
      min_num = 1,
      max_num = n,
      pattern = ".|.|.|ruiji_wang|.|.",
      prompt = "#lingyin-invoke:::" .. tostring(n),
      skill_name = "liying",
      cancelable = true,
    })
    if #cards > 0 then
      event:setCostData(skill.name, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    player:broadcastSkillInvoke("lingyin")
    room:notifySkillInvoked(player, "lingyin", "drawcard")
    local cards = table.simpleClone(event:getCostData(skill.name))
    local colors = {}
    for _, id in ipairs(player:getPile("ruiji_wang")) do
      if not table.contains(cards, id) then
        table.insertIfNeed(colors, Fk:getCardById(id).color)
      end
    end
    if #colors < 2 then
      room:setPlayerMark(player, "@@lingyin-turn", 1)
    end
    room:obtainCard(player, cards, true, fk.ReasonJustMove)
  end,
})

-- DamageCaused
lingyin:addEffect(fk.DamageCaused, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("@@lingyin-turn") > 0 and not data.chain and data.to ~= player
  end,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
})

return lingyin
