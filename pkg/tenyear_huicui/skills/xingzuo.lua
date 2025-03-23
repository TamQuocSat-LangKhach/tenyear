local xingzuo = fk.CreateSkill {
  name = "xingzuo"
}

Fk:loadTranslationTable{
  ['xingzuo'] = '兴作',
  ['#xingzuo-invoke'] = '兴作：你可观看牌堆底的三张牌，并用任意张手牌替换其中等量的牌',
  ['#xingzuo_delay'] = '兴作',
  ['#xingzuo-choose'] = '兴作：你可以令一名角色用所有手牌替换牌堆底的三张牌，若交换前其手牌数大于3，你失去1点体力',
  [':xingzuo'] = '出牌阶段开始时，你可观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，你可以令一名有手牌的角色用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。',
  ['$xingzuo1'] = '顺人之情，时之势，兴作可成。',
  ['$xingzuo2'] = '兴作从心，相继不绝。',
}

xingzuo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingzuo.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = room:getNCards(3, "bottom")
    local handcards = player:getCardIds(Player.Hand)
    local cardmap = room:askToArrangeCards(player, {
      skill_name = xingzuo.name,
      card_map = {cards, handcards, "Bottom", "$Hand"},
      prompt = "#xingzuo-invoke"
    })
    U.swapCardsWithPile(player, cardmap[1], cardmap[2], xingzuo.name, "Bottom")
  end
})

local xingzuo_delay = fk.CreateTriggerSkill{
  name = "#xingzuo_delay",
  anim_type = "control",
}

xingzuo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
      player:usedSkillTimes(xingzuo.name, Player.HistoryTurn) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isKongcheng() end), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xingzuo-choose",
      skill_name = xingzuo.name
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(xingzuo.name)
    local to = room:getPlayerById(event:getCostData(self))
    local cards = to:getCardIds(Player.Hand)
    local n = #cards
    U.swapCardsWithPile(to, cards, room:getNCards(3, "bottom"), xingzuo.name, "Bottom")
    if n > 3 and not player.dead then
      room:loseHp(player, 1, xingzuo.name)
    end
  end,
})

return xingzuo
