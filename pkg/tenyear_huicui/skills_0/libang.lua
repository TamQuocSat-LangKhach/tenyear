local libang = fk.CreateSkill {
  name = "libang"
}

Fk:loadTranslationTable{
  ['libang'] = '利傍',
  ['#libang'] = '利傍：弃置一张牌，获得两名其他角色各一张牌，然后判定',
  ['#libang_delay'] = '利傍',
  ['libang_active'] = '利傍',
  ['#libang-card'] = '利傍：交给其中一名角色两张牌，否则失去1点体力',
  ['#libang-slash'] = '利傍：视为对其中一名角色使用一张【杀】',
  [':libang'] = '出牌阶段限一次，你可以弃置一张牌，获得两名其他角色各一张牌并展示，然后你判定，若结果与这两张牌的颜色：均不同，你交给其中一名角色两张牌或失去1点体力；至少一张相同，你获得判定牌并视为对其中一名角色使用一张【杀】。',
  ['$libang1'] = '天下熙攘，所为者利尔。',
  ['$libang2'] = '我有武力傍身，必可待价而沽。',
}

libang:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  prompt = "#libang",
  can_use = function(self, player)
    return player:usedSkillTimes(libang.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < 2 and to_select ~= player.id and #selected_cards == 1
      and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos, false)
    room:throwCard(effect.cards, libang.name, player, player)
    if player.dead then return end
    local cards = {}
    local target1 = room:getPlayerById(effect.tos[1])
    local target2 = room:getPlayerById(effect.tos[2])
    local id1 = room:askToChooseCard(player, {
      target = target1,
      flag = "he",
      skill_name = libang.name
    })
    room:obtainCard(player, id1, true, fk.ReasonPrey)
    table.insert(cards, id1)
    if not player.dead and not target2:isNude() then
      local id2 = room:askToChooseCard(player, {
        target = target2,
        flag = "he",
        skill_name = libang.name
      })
      room:obtainCard(player.id, id2, true, fk.ReasonPrey)
      table.insert(cards, id2)
    end
    if player.dead then return end
    player:showCards(cards)
    local pattern = "."
    local suits = {}
    for _, id in ipairs(cards) do
      if Fk:getCardById(id).color == Card.Red then
        table.insertIfNeed(suits, "heart")
        table.insertIfNeed(suits, "diamond")
      elseif Fk:getCardById(id).color == Card.Black then
        table.insertIfNeed(suits, "spade")
        table.insertIfNeed(suits, "club")
      end
    end
    if #suits > 0 then
      pattern = ".|.|" .. table.concat(suits, ",")
    end
    local judge = {
      who = player,
      reason = libang.name,
      pattern = pattern,
      extra_data = {effect.tos, cards},
    }
    room:judge(judge)
  end,
})

libang:addEffect(fk.FinishJudge, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data.reason == "libang" and not player.dead
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.color == Card.NoColor then return end
    local targets = data.extra_data[1]
    for i = #targets, 1, -1 do
      if room:getPlayerById(targets[i]).dead then
        table.removeOne(targets, targets[i])
      end
    end
    if not data.card:matchPattern(data.pattern) then
      if #targets == 0 or #player:getCardIds{Player.Hand, Player.Equip} < 2 then
        room:loseHp(player, 1, "libang")
      else
        local _, dat = room:askToUseActiveSkill(player, {
          skill_name = "libang_active",
          prompt = "#libang-card",
          cancelable = true,
          extra_data = {targets = targets}
        })
        if dat then
          room:obtainCard(dat.targets[1], dat.cards, false, fk.ReasonGive, player.id)
        else
          room:loseHp(player, 1, "libang")
        end
      end
    else
      if room:getCardArea(data.card) == Card.Processing then
        room:obtainCard(player.id, data.card, true, fk.ReasonJustMove)
      end
      targets = table.filter(targets, function(id) return not player:isProhibited(room:getPlayerById(id), Fk:cloneCard("slash")) end)
      if #targets == 0 then return end
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#libang-slash",
        skill_name = "libang"
      })
      room:useVirtualCard("slash", nil, player, room:getPlayerById(tos[1]), "libang")
    end
  end,
})

return libang
