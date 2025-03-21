local ty_ex__jiaozhao = fk.CreateSkill {
  name = "ty_ex__jiaozhao"
}

Fk:loadTranslationTable{
  ['ty_ex__jiaozhao'] = '矫诏',
  ['#ty_ex__jiaozhao-prompt'] = '矫诏：展示一张手牌令一名角色声明一种基本牌或普通锦囊牌，你本回合可以将此牌当声明的牌使用',
  ['@ty_ex__jiaozhao'] = '矫诏',
  ['#ty_ex__jiaozhao-choice'] = '矫诏：声明一种牌名，%src 本回合可以将%arg当此牌使用',
  ['#TYEXJiaozhaoChoice'] = '%from “%arg2” 声明牌名 %arg',
  ['@ty_ex__jiaozhao-inhand'] = '矫诏',
  ['ty_ex__jiaozhao&'] = '矫诏',
  [':ty_ex__jiaozhao'] = '出牌阶段限一次，你可以展示一张手牌并选择一名距离最近的其他角色，该角色声明一种基本牌或普通锦囊牌的牌名，本回合你可以将此牌当声明的牌使用（不能指定自己为目标）。',
  ['$ty_ex__jiaozhao1'] = '事关社稷，万望阁下谨慎行事。',
  ['$ty_ex__jiaozhao2'] = '为续江山，还请爱卿仔细观之。',
}

ty_ex__jiaozhao:addEffect('active', {
  anim_type = "special",
  card_num = 1,
  prompt = function (skill, player)
    return "#ty_ex__jiaozhao-prompt"..((player:getMark("@ty_ex__jiaozhao") > 0) and "1" or "")
  end,
  can_use = function(self, player)
    if not player:isKongcheng() then
      if player:getMark("@ty_ex__jiaozhao") < 2 then
        return player:usedSkillTimes(ty_ex__jiaozhao.name, Player.HistoryPhase) == 0
      else
        return #player:getTableMark("ty_ex__jiaozhao_choice-phase") < 2
      end
    end
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  target_filter = function(self, player, to_select, selected)
    if #selected == 0 and player:getMark("@ty_ex__jiaozhao") == 0 then
      local n = 999
      for _, p in ipairs(Fk:currentRoom().alive_players) do
        if p ~= player and not p:isRemoved() and player:distanceTo(p) < n then
          n = player:distanceTo(p)
        end
      end
      return player:distanceTo(Fk:currentRoom():getPlayerById(to_select)) == n
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    local n = player:getMark("@ty_ex__jiaozhao") == 0 and 1 or 0
    return #selected == n and #selected_cards == 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = #effect.tos > 0 and room:getPlayerById(effect.tos[1]) or player
    player:showCards(effect.cards)
    if player.dead then return end
    local c = Fk:getCardById(effect.cards[1])
    local mark = player:getTableMark("ty_ex__jiaozhao_choice-phase")
    local pat = table.contains(mark, "b") and "" or "b"
    if not table.contains(mark, "t") then pat = pat .. "t" end
    local names = U.getAllCardNames(pat)
    local choice = room:askToChoice(target, {
      choices = names,
      skill_name = ty_ex__jiaozhao.name,
      prompt = "#ty_ex__jiaozhao-choice:"..player.id.."::"..c:toLogString(),
    })
    table.insert(mark, Fk:cloneCard(choice).type == Card.TypeBasic and "b" or "t")
    room:setPlayerMark(player, "ty_ex__jiaozhao_choice-phase", mark)
    room:sendLog{
      type = "#TYEXJiaozhaoChoice",
      from = player.id,
      arg = choice,
      arg2 = ty_ex__jiaozhao.name,
      toast = true,
    }
    if table.contains(player:getCardIds("h"), effect.cards[1]) then
      room:setCardMark(c, "ty_ex__jiaozhao-inhand", choice)
      room:setCardMark(c, "@ty_ex__jiaozhao-inhand", Fk:translate(choice)) --- FIXME : translate for visble card mark
      room:handleAddLoseSkills(player, "ty_ex__jiaozhao&", nil, false, true)
    end
  end,
})

local ty_ex__jiaozhao_change = fk.CreateSkill {
  name = "#ty_ex__jiaozhao_change"
}

ty_ex__jiaozhao_change:addEffect(fk.AfterTurnEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__jiaozhaoVS, true)
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-ty_ex__jiaozhao&", nil, false, true)
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      local c = Fk:getCardById(id)
      if c:getMark("ty_ex__jiaozhao-inhand") ~= 0 then
        room:setCardMark(c, "ty_ex__jiaozhao-inhand", 0)
        room:setCardMark(c, "@ty_ex__jiaozhao-inhand", 0)
      end
    end
  end,
})

ty_ex__jiaozhao_change:addEffect(fk.EventLoseSkill, {
  can_trigger = function(self, event, target, player, data)
    return target == player and data == ty_ex__jiaozhao
  end,
  on_trigger = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@ty_ex__jiaozhao", 0)
  end,
})

return ty_ex__jiaozhao
