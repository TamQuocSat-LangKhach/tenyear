local mingfa = fk.CreateSkill {
  name = "mingfa"
}

Fk:loadTranslationTable{
  ['mingfa'] = '明伐',
  ['#mingfa-choose'] = '明伐：将%arg置为“明伐”，选择一名角色，其结束阶段视为对其使用其手牌张数次“明伐”牌',
  ['@@mingfa'] = '明伐',
  [':mingfa'] = '出牌阶段内限一次，你使用非转化的【杀】或普通锦囊牌结算完毕后，若你没有“明伐”牌，可将此牌置于武将牌上并选择一名其他角色。该角色的结束阶段，视为你对其使用X张“明伐”牌（X为其手牌数，最少为1，最多为5），然后移去“明伐”牌。',
  ['$mingfa1'] = '煌煌大势，无须诈取。',
  ['$mingfa2'] = '开示公道，不为掩袭。',
}

mingfa:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mingfa.name) then
      return target == player and player.phase == Player.Play and #player:getPile(mingfa.name) == 0 and
        (event.data.card.trueName == "slash" or event.data.card:isCommonTrick()) and player.room:getCardArea(event.data.card) == Card.Processing and
        U.isPureCard(event.data.card) and player:usedSkillTimes(mingfa.name, Player.HistoryPhase) == 0
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#mingfa-choose:::"..event.data.card:toLogString(),
      skill_name = mingfa.name,
    })
    if #tos > 0 then
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addToPile(mingfa.name, event.data.card, true, mingfa.name)
    room:setPlayerMark(player, mingfa.name, event:getCostData(self).tos[1])
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    room:addTableMark(to, "@@mingfa", player.id)
  end,
})

mingfa:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(mingfa.name) then
      return target.phase == Player.Finish and player:getMark(mingfa.name) ~= 0 and #player:getPile(mingfa.name) > 0 and
        player:getMark(mingfa.name) == target.id
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local card = Fk:cloneCard(Fk:getCardById(player:getPile(mingfa.name)[1]).name)
    if card.trueName ~= "nullification" and card.skill:getMinTargetNum() < 2 and not player:isProhibited(target, card) then
      --据说没有合法性检测甚至无懈都能虚空用，甚至不合法目标还能触发贞烈。我不好说
      local n = math.max(target:getHandcardNum(), 1)
      n = math.min(n, 5)
      for i = 1, n, 1 do
        if target.dead then break end
        room:useCard({
          card = card,
          from = player.id,
          tos = {{target.id}},
          skillName = mingfa.name,
        })
      end
    end
    room:setPlayerMark(player, mingfa.name, 0)
    if not target.dead then
      room:removeTableMark(target, "@@mingfa", player.id)
    end
    room:moveCards({
      from = player.id,
      ids = player:getPile(mingfa.name),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = mingfa.name,
      specialName = mingfa.name,
    })
  end
})

mingfa:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    if #player:getPile(mingfa.name) > 0 and player:getMark(mingfa.name) ~= 0 then
      return target == player and event.data == mingfa
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark(mingfa.name))
    room:setPlayerMark(player, mingfa.name, 0)
    room:moveCards({
      from = player.id,
      ids = player:getPile(mingfa.name),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = mingfa.name,
      specialName = mingfa.name,
    })
    if not to.dead then
      room:removeTableMark(to, "@@mingfa", to.id)
    end
  end
})

mingfa:addEffect(fk.Death, {
  can_refresh = function(self, event, target, player, data)
    if #player:getPile(mingfa.name) > 0 and player:getMark(mingfa.name) ~= 0 then
      return target == player or target:getMark("@@mingfa") ~= 0
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if target == player then
      local to = room:getPlayerById(player:getMark(mingfa.name))
      room:setPlayerMark(player, mingfa.name, 0)
      room:moveCards({
        from = player.id,
        ids = player:getPile(mingfa.name),
        toArea = Card.DiscardPile,
        moveReason = fk.ReasonPutIntoDiscardPile,
        skillName = mingfa.name,
        specialName = mingfa.name,
      })
      if not to.dead then
        room:removeTableMark(to, "@@mingfa", to.id)
      end
    else
      local mark = target:getMark("@@mingfa")
      if table.contains(mark, player.id) then
        table.removeOne(mark, player.id)
        if #mark == 0 then mark = 0 end
        room:setPlayerMark(target, "@@mingfa", mark)
        room:setPlayerMark(player, mingfa.name, 0)
        room:moveCards({
          from = player.id,
          ids = player:getPile(mingfa.name),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = mingfa.name,
          specialName = mingfa.name,
        })
      end
    end
  end
})

return mingfa
