local shuojian = fk.CreateSkill {
  name = "shuojian"
}

Fk:loadTranslationTable{
  ['shuojian'] = '数荐',
  ['#shuojian'] = '数荐：交给一名角色一张牌，其选择令你摸牌或其视为使用【过河拆桥】',
  ['shuojian1'] = '令 %src 摸%arg张牌并弃%arg2张牌',
  ['shuojian2'] = '你视为使用%arg张【过河拆桥】，本回合此技能失效',
  ['shuojian_viewas'] = '数荐',
  ['#shuojian-use'] = '数荐：视为使用【过河拆桥】（第%arg张，共%arg2张）',
  [':shuojian'] = '出牌阶段限三次，你可以交给一名其他角色一张牌，然后其选择一项：1.令你摸3张牌并弃2张牌；2.视为使用3张【过河拆桥】，本回合此技能失效。此阶段下次发动该技能，选项中所有数字-1。',
  ['$shuojian1'] = '我数荐卿而祖不用，其之失也。',
  ['$shuojian2'] = '兴霸乃当世豪杰，何患无爵。',
}

shuojian:addEffect('active', {
  anim_type = "support",
  card_num = 1,
  target_num = 1,
  prompt = "#shuojian",
  times = function(self, player)
    return player.phase == Player.Play and 3 - player:usedSkillTimes(shuojian.name, Player.HistoryPhase) or -1
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(shuojian.name, Player.HistoryPhase) < 3
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:moveCardTo(effect.cards[1], Card.PlayerHand, target, fk.ReasonGive, shuojian.name, nil, false, player.id)
    if target.dead then return end
    local n = 4 - player:usedSkillTimes(shuojian.name, Player.HistoryPhase)
    local choices = {}
    if not player.dead then
      table.insert(choices, "shuojian1:"..player.id.."::"..n..":"..(n-1))
    end
    if not target:prohibitUse(Fk:cloneCard("dismantlement")) then
      table.insert(choices, "shuojian2:::"..n)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = shuojian.name
    })
    if choice[9] == "1" then
      player:drawCards(n, shuojian.name)
      if not player.dead and n > 1 then
        room:askToDiscard(player, { 
          min_num = n - 1,
          max_num = n - 1,
          include_equip = true,
          skill_name = shuojian.name,
          cancelable = false
        })
      end
    else
      room:invalidateSkill(player, shuojian.name, "-turn")
      for i = 1, n, 1 do
        if target.dead then return end
        local success, data = room:askToUseActiveSkill(target, {
          skill_name = "shuojian_viewas",
          prompt = "#shuojian-use:::"..i..":"..n,
          cancelable = true
        })
        if success then
          local card = Fk:cloneCard("dismantlement")
          card.skillName = shuojian.name
          room:useCard{
            from = target.id,
            tos = table.map(data.targets, function(id) return {id} end),
            card = card,
          }
        else
          break
        end
      end
    end
  end,
})

return shuojian
