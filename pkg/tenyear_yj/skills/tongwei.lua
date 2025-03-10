local tongwei = fk.CreateSkill {
  name = "tongwei"
}

Fk:loadTranslationTable{
  ['tongwei'] = '统围',
  ['#tongwei'] = '统围：你可以重铸两张牌并指定一名其他角色',
  ['@tongwei'] = '统围',
  ['#tongwei_trigger'] = '统围',
  ['#tongwei-choice'] = '统围：选择视为对 %dest 使用的牌',
  [':tongwei'] = '出牌阶段限一次，你可以指定一名其他角色并重铸两张牌。若如此做，其使用下一张牌结算后，若此牌点数介于你上次此法重铸牌点数之间，你视为对其使用一张【杀】或【过河拆桥】。',
  ['$tongwei1'] = '今统虎贲十万，必困金龙于斯。',
  ['$tongwei2'] = '昔年将军七出长坂，今尚能饭否？'
}

-- 主动技能
tongwei:addEffect('active', {
  anim_type = "control",
  card_num = 2,
  target_num = 1,
  prompt = "#tongwei",
  can_use = function(self, player)
    return player:usedSkillTimes(tongwei.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n1 = Fk:getCardById(effect.cards[1]).number
    local n2 = Fk:getCardById(effect.cards[2]).number
    room:recastCard(effect.cards, player, tongwei.name)
    if player.dead or target.dead then return end
    if n1 > n2 then
      n1, n2 = n2, n1
    end
    room:setPlayerMark(target, "@tongwei", n1..","..n2)
    room:setPlayerMark(player, "tongwei_"..target.id, {n1, n2})
  end,
})

-- 触发技能
tongwei:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player:getMark("tongwei_"..target.id) ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room
    local n1, n2 = player:getMark("tongwei_"..target.id)[1], player:getMark("tongwei_"..target.id)[2]
    room:setPlayerMark(target, "@tongwei", 0)
    room:setPlayerMark(player, "tongwei_"..target.id, 0)
    if n1 < data.card.number and data.card.number < n2 then
      player:broadcastSkillInvoke(tongwei.name)
      room:notifySkillInvoked(player, tongwei.name)
      local names = {"slash", "dismantlement"}
      for i = 2, 1, -1 do
        local card = Fk:cloneCard(names[i])
        if not player:canUseTo(card, target, {bypass_distances = true, bypass_times = true}) then
          table.remove(names, i)
        end
      end
      if #names == 0 then return end
      local choice = room:askToChoice(player, {
        choices = names,
        skill_name = tongwei.name,
        prompt = "#tongwei-choice::"..target.id
      })
      room:useVirtualCard(choice, nil, player, target, tongwei.name, true)
    end
  end,
})

return tongwei
