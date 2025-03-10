local lisao = fk.CreateSkill {
  name = "lisao"
}

Fk:loadTranslationTable{
  ['lisao'] = '离骚',
  ['#lisao'] = '离骚：你可令至多两名角色回答《离骚》，其中答错或未回答的角色不能响应你的牌且受到伤害翻倍',
  ['@@lisao_debuff-turn'] = '离骚',
  ['#lisao_debuff'] = '离骚',
  [':lisao'] = '出牌阶段限一次，你可以令至多两名角色同时回答《离骚》选择题（有角色答对则立即停止作答，答错则剩余角色可继续作答），答对的角色展示所有手牌，答错或未作答的角色本回合不能响应你使用的牌且受到的伤害翻倍。',
  ['$lisao1'] = '朝饮木兰之坠露，夕餐秋菊之落英。',
  ['$lisao2'] = '惟草木之零落兮，恐美人之迟暮。',
}

lisao:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  prompt = "#lisao",
  can_use = function(self, player)
    return player:usedSkillTimes(lisao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)

    local randomIndex = math.random(1, 69)
    local targets = table.map(effect.tos, function(pId) return room:getPlayerById(pId) end)

    local gameData = {
      type = "lisao",
      data = {
        {
          question = "lisao_question_" .. randomIndex,
          optionA = "lisao_option_A_" .. randomIndex,
          optionB = "lisao_option_B_" .. randomIndex,
          answer = randomIndex > 35 and 2 or 1,
        },
        lisao.name
      },
    }
    for _, p in ipairs(targets) do
      p.mini_game_data = gameData
    end

    room:notifyMoveFocus(targets, lisao.name)
    local winner = room:doRaceRequest("MiniGame", targets, json.encode(gameData))
    if winner then
      table.removeOne(targets, winner)

      local handcards = winner:getCardIds("h")
      if #handcards > 0 then
        winner:showCards(handcards)
      end
    end

    for _, p in ipairs(targets) do
      local owners = p:getTableMark("@@lisao_debuff-turn")
      if not table.contains(owners, player.id) then
        table.insert(owners, player.id)
        room:setPlayerMark(p, "@@lisao_debuff-turn", owners)
      end
    end
  end,
})

local lisaoDebuff = fk.CreateTriggerSkill {
  name = "#lisao_debuff",
}

lisao:addEffect(fk.DamageInflicted, {
  anim_type = "negative",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@lisao_debuff-turn") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage * 2
  end,
})

lisao:addEffect(fk.CardUsing, {
  can_trigger = function(self, event, target, player, data)
    return false
  end,
  can_refresh = function(self, event, target, player, data)
    return
      target == player and
      table.find(
        player.room.alive_players,
        function(p) return table.contains(p:getTableMark("@@lisao_debuff-turn"), player.id) end
      )
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    table.insertTableIfNeed(
      data.disresponsiveList,
      table.map(
        table.filter(
          player.room.alive_players,
          function(p) return table.contains(p:getTableMark("@@lisao_debuff-turn"), player.id) end
        ),
        Util.IdMapper
      )
    )
  end,
})

return lisao
