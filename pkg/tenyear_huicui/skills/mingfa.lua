local mingfa = fk.CreateSkill {
  name = "mingfa",
}

Fk:loadTranslationTable{
  ["mingfa"] = "明伐",
  [":mingfa"] = "每阶段限一次，当你于出牌阶段使用非转化的【杀】或普通锦囊牌结算完毕后，若你没有“明伐”牌，你可以将此牌置于武将牌上并"..
  "选择一名其他角色。该角色的结束阶段，视为你对其使用X张“明伐”牌（X为其手牌数，最少为1，最多为5），然后移去“明伐”牌。",

  ["#mingfa-choose"] = "明伐：将%arg置为“明伐”，选择一名角色，其结束阶段视为对其使用“明伐”牌！",
  ["@@mingfa"] = "明伐",

  ["$mingfa1"] = "煌煌大势，无须诈取。",
  ["$mingfa2"] = "开示公道，不为掩袭。",
}

mingfa:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(mingfa.name) and player.phase == Player.Play and
      #player:getPile(mingfa.name) == 0 and (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      player.room:getCardArea(event.data.card) == Card.Processing and
      not data.card:isVirtual() and data.card.name == Fk:getCardById(data.card.id).name and
      player:usedSkillTimes(mingfa.name, Player.HistoryPhase) == 0 and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#mingfa-choose:::"..data.card:toLogString(),
      skill_name = mingfa.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:addTableMarkIfNeed(to, "@@mingfa", player.id)
    room:setPlayerMark(player, mingfa.name, to.id)
    player:addToPile(mingfa.name, data.card, true, mingfa.name)
  end,
})

mingfa:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target.phase == Player.Finish and player:getMark(mingfa.name) == target.id
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(target, "@@mingfa", player.id)
    room:setPlayerMark(player, mingfa.name, 0)
    local card = Fk:cloneCard(Fk:getCardById(player:getPile(mingfa.name)[1]).name)
    card.skillName = mingfa.name
    if player:canUseTo(card, target, {bypass_distances = true, bypass_times = true}) then
      local n = math.max(target:getHandcardNum(), 1)
      n = math.min(n, 5)
      for _ = 1, n, 1 do
        if player.dead or target.dead then break end
        room:useCard{
          card = card,
          from = player,
          tos = {target},
          extraUse = true,
        }
      end
    end
    room:moveCards{
      from = player,
      ids = player:getPile(mingfa.name),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = mingfa.name,
    }
  end
})

mingfa:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(mingfa.name) == target.id or
      (target == player and player:getMark(mingfa.name) ~= 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      local to = room:getPlayerById(player:getMark(mingfa.name))
      room:removeTableMark(to, "@@mingfa", player.id)
    else
      room:setPlayerMark(player, mingfa.name, 0)
      room:moveCards{
        from = player,
        ids = player:getPile(mingfa.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = mingfa.name,
      }
    end
  end
})

return mingfa
