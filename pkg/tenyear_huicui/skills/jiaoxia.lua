local jiaoxia = fk.CreateSkill {
  name = "jiaoxia",
}

Fk:loadTranslationTable{
  ["jiaoxia"] = "狡黠",
  [":jiaoxia"] = "出牌阶段开始时，你可以令本阶段你的手牌均视为【杀】。若你以此法使用的【杀】造成了伤害，此【杀】结算后你可以视为使用原卡牌"..
  "（有次数限制）。出牌阶段，你对每名角色使用第一张【杀】无距离和次数限制。",

  ["#jiaoxia-invoke"] = "狡黠：你可以令本阶段你的手牌均视为【杀】，且结算后可以使用原卡牌！",
  ["#jiaoxia-use"] = "狡黠：你可以视为使用%arg",
  ["@@jiaoxia-phase"] = "狡黠",

  ["$jiaoxia1"] = "暗剑匿踪，现时必捣黄龙！",
  ["$jiaoxia2"] = "袖中藏刃，欲取诸君之头！",
}

jiaoxia:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaoxia.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = jiaoxia.name,
      prompt = "#jiaoxia-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@jiaoxia-phase", 1)
    player:filterHandcards()
  end,
})

jiaoxia:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and
      table.contains(data.card.skillNames, jiaoxia.name) and data.damageDealt and
      player.room:getCardArea(data.card) == Card.Processing and
      player:canUse(Fk:getCardById(Card:getIdList(data.card)[1]), {bypass_times = false})
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local ids = Card:getIdList(data.card)
    local use = room:askToUseRealCard(player, {
      pattern = ids,
      skill_name = jiaoxia.name,
      prompt = "#jiaoxia-use:::" .. Fk:getCardById(ids[1]):toLogString(),
      extra_data = {
        bypass_times = false,
        expand_pile = ids,
        extraUse = false,
      },
      skip = true
    })
    if use then
      event:setCostData(self, {extra_data = use})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:useCard(event:getCostData(self).extra_data)
  end,
})

jiaoxia:addEffect(fk.TargetSpecified, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiaoxia.name) and data.card.trueName == "slash" and
      not table.contains(player:getTableMark("jiaoxia_target-phase"), data.to.id)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "jiaoxia_target-phase", data.to.id)
    if not data.use.extraUse then
      player:addCardUseHistory(data.card.trueName, -1)
      data.use.extraUse = true
    end
  end,
})

jiaoxia:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return player:hasSkill(jiaoxia.name) and card and card.trueName == "slash" and to and
      not table.contains(player:getTableMark("jiaoxia_target-phase"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return player:hasSkill(jiaoxia.name) and card and card.trueName == "slash" and to and
      not table.contains(player:getTableMark("jiaoxia_target-phase"), to.id)
  end,
})

jiaoxia:addEffect("filter", {
  mute = true,
  card_filter = function(self, card, player)
    return player:getMark("@@jiaoxia-phase") > 0 and table.contains(player:getCardIds("h"), card.id)
  end,
  view_as = function(self, player, to_select)
    local card = Fk:cloneCard("slash", to_select.suit, to_select.number)
    card.skillName = jiaoxia.name
    return card
  end,
})

jiaoxia:addAcquireEffect(function (self, player, is_start)
  if not is_start and player.phase == Player.Play then
    local room = player.room
    local targets = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
      local use = e.data
      if use.from == player and use.card.trueName == "slash" then
        for _, p in ipairs(use.tos) do
          if table.insertIfNeed(targets, p.id) then
            if not use.extraUse then
              player:addCardUseHistory(use.card.trueName, -1)
              use.extraUse = true
            end
          end
        end
      end
    end, Player.HistoryPhase)
    room:setPlayerMark(player, "jiaoxia_target-phase", targets)
  end
end)

return jiaoxia
