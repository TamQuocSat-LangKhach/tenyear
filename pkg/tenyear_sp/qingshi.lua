local qingshi = fk.CreateSkill {
  name = "qingshi"
}

Fk:loadTranslationTable{
  ['qingshi'] = '情势',
  ['qingshi-turn'] = '情势',
  ['qingshi1'] = '令此牌对其中一个目标伤害+1',
  ['qingshi2'] = '令任意名其他角色各摸一张牌',
  ['qingshi3'] = '摸三张牌，然后此技能本回合失效',
  ['#qingshi-invoke'] = '情势：请选择一项（当前使用牌为%arg）',
  ['#qingshi1-choose'] = '情势：令%arg对其中一名目标造成伤害+1',
  ['#qingshi2-choose'] = '情势：令任意名其他角色各摸一张牌',
  ['#qingshi_delay'] = '情势',
  [':qingshi'] = '当你于出牌阶段内使用一张牌时（每种牌名每回合限一次），若手牌中有同名牌，你可以选择一项：1.令此牌对其中一个目标造成的伤害值+1：2.令任意名其他角色各摸一张牌；3.摸三张牌，然后此技能本回合失效。',
  ['$qingshi1'] = '兵者，行霸道之势，彰王道之实。',
  ['$qingshi2'] = '将为军魂，可因势而袭，其有战无类。',
}

qingshi:addEffect(fk.CardUsing, {
  global = false,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qingshi.name) and player.phase == Player.Play and
      table.find(player.player_cards[Player.Hand], function(id) return Fk:getCardById(id).trueName == data.card.trueName end) and
      not table.contains(player:getTableMark("qingshi-turn"), data.card.trueName)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"qingshi1", "qingshi2", "qingshi3", "Cancel"},
      skill_name = qingshi.name,
      prompt = "#qingshi-invoke:::"..data.card:toLogString()
    })
    if choice == "qingshi1" then
      local to = room:askToChoosePlayers(player, {
        targets = TargetGroup:getRealTargets(data.tos),
        min_num = 1,
        max_num = 1,
        prompt = "#qingshi1-choose:::"..data.card:toLogString(),
        skill_name = qingshi.name
      })
      if #to > 0 then
        event:setCostData(skill, {choice, to})
        return true
      end
    elseif choice == "qingshi2" then
      local to = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = 998,
        prompt = "#qingshi2-choose:::"..data.card:toLogString(),
        skill_name = qingshi.name
      })
      if #to > 0 then
        event:setCostData(skill, {choice, to})
        return true
      end
    elseif choice == "qingshi3" then
      event:setCostData(skill, {choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "qingshi-turn", data.card.trueName)
    if event:getCostData(skill)[1] == "qingshi1" then
      room:notifySkillInvoked(player, qingshi.name, "offensive")
      player:broadcastSkillInvoke(qingshi.name)
      data.extra_data = data.extra_data or {}
      data.extra_data.qingshi_data = data.extra_data.qingshi_data or {}
      table.insert(data.extra_data.qingshi_data, {player.id, event:getCostData(skill)[2][1]})
    elseif event:getCostData(skill)[1] == "qingshi2" then
      room:notifySkillInvoked(player, qingshi.name, "support")
      player:broadcastSkillInvoke(qingshi.name)
      local tos = event:getCostData(skill)[2]
      room:sortPlayersByAction(tos)
      for _, id in ipairs(tos) do
        local p = room:getPlayerById(id)
        if not p.dead then
          p:drawCards(1, qingshi.name)
        end
      end
    elseif event:getCostData(skill)[1] == "qingshi3" then
      room:notifySkillInvoked(player, qingshi.name, "drawcard")
      player:broadcastSkillInvoke(qingshi.name)
      player:drawCards(3, qingshi.name)
      room:invalidateSkill(player, qingshi.name, "-turn")
    end
  end,
})

local qingshi_delay = fk.CreateTriggerSkill{
  name = "#qingshi_delay",
  events = {fk.DamageCaused},
  anim_type = "offensive",
}

qingshi:addEffect(fk.DamageCaused, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    if player.dead or data.card == nil or data.chain then return false end
    local room = player.room
    local card_event = room.logic:getCurrentEvent():findParent(GameEvent.UseCard)
    if not card_event then return false end
    local use = card_event.data[1]
    if use.extra_data then
      local qingshi_data = use.extra_data.qingshi_data
      if qingshi_data then
        return table.find(qingshi_data, function (players)
          return players[1] == player.id and players[2] == data.to.id
        end)
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:broadcastSkillInvoke(qingshi.name)
    data.damage = data.damage + 1
  end,
})

return qingshi
