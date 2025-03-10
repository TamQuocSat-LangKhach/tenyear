local shoucheng = fk.CreateSkill {
  name = "ty__shoucheng"
}

Fk:loadTranslationTable{
  ['ty__shoucheng'] = '守成',
  ['#ty__shoucheng-choose'] = '守成：你可令一名失去最后手牌的角色摸两张牌',
  ['#ty__shoucheng-draw'] = '守成：你可令 %dest 摸两张牌',
  [':ty__shoucheng'] = '每回合限一次，当一名角色于其回合外失去手牌后，若其没有手牌，你可令其摸两张牌。',
  ['$ty__shoucheng1'] = '待吾等助将军一臂之力！',
  ['$ty__shoucheng2'] = '国库盈余，可助军威。',
}

shoucheng:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(shoucheng) or player:usedSkillTimes(shoucheng.name, Player.HistoryTurn) > 0 then return end
    for _, move in ipairs(data) do
      if move.from then
        local from = player.room:getPlayerById(move.from)
        if from:isKongcheng() and from.phase == Player.NotActive and not from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local targets = {}
    local room = player.room
    for _, move in ipairs(data) do
      if move.from then
        local from = room:getPlayerById(move.from)
        if from:isKongcheng() and from.phase == Player.NotActive and not from.dead then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              table.insertIfNeed(targets, from.id)
              break
            end
          end
        end
      end
    end
    if #targets == 0 then return end
    if #targets > 1 then
      local tos = player.room:askToChoosePlayers(player, {
        targets = Fk:getPlayerByIds(targets),
        min_num = 1,
        max_num = 1,
        prompt = "#ty__shoucheng-choose",
        skill_name = shoucheng.name,
        cancelable = true
      })
      if #tos > 0 then
        event:setCostData(self, {tos = tos})
        return true
      end
    else
      event:setCostData(self, {tos = targets})
      return player.room:askToSkillInvoke(player, {
        skill_name = shoucheng.name,
        prompt = "#ty__shoucheng-draw::" .. targets[1]
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    player:broadcastSkillInvoke("shoucheng")
    to:drawCards(2, shoucheng.name)
  end,
})

return shoucheng
