local ty__shuangren = fk.CreateSkill {
  name = "ty__shuangren"
}

Fk:loadTranslationTable{
  ['ty__shuangren'] = '双刃',
  ['#ty__shuangren-ask'] = '双刃：你可与一名角色拼点',
  ['#ty__shuangren_active'] = '双刃',
  ['#ty__shuangren_slash-ask'] = '双刃：视为对与 %src 势力相同的一至两名角色使用【杀】(若选两名，其中一名须为%src)',
  ['@@ty__shuangren_prohibit-phase'] = '双刃禁杀',
  ['#ty__shuangren_prohibit'] = '双刃',
  [':ty__shuangren'] = '出牌阶段开始时，你可以与一名角色拼点。若你赢，你选择与其势力相同的一至两名角色（若选择两名，其中一名须为该角色），然后你视为对选择的角色使用一张不计入次数的【杀】；若你没赢，你本阶段不能使用【杀】。',
  ['$ty__shuangren1'] = '这淮阴城下，正是葬汝尸骨的好地界。',
  ['$ty__shuangren2'] = '吾众下大军已至，匹夫，以何敌我？',
}

ty__shuangren:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(ty__shuangren.name) and player.phase == Player.Play and not player:isKongcheng() and table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
    if #targets == 0 then return false end
    local tos = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__shuangren-ask",
      skill_name = ty__shuangren.name,
      cancelable = true,
    })
    if #tos > 0 then
      event:setCostData(self, tos[1].id)
      return true
    end
    return false
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local pindian = player:pindian({to}, ty__shuangren.name)
    if pindian.results[to.id].winner == player then
      local slash = Fk:cloneCard("slash")
      if player.dead or player:prohibitUse(slash) then return false end
      local targets = table.filter(room:getOtherPlayers(player), function(p) return p.kingdom == to.kingdom and not player:isProhibited(p, slash) end)
      if #targets == 0 then return false end
      room:setPlayerMark(player, "ty__shuangren_kingdom", to.kingdom)
      room:setPlayerMark(player, "ty__shuangren_target", to.id)
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "#ty__shuangren_active",
        prompt = "#ty__shuangren_slash-ask:" .. to.id,
        cancelable = false
      })
      local tos = success and table.map(dat.targets, Util.Id2PlayerMapper) or {table.random(targets)}
      room:useVirtualCard("slash", nil, player, tos, ty__shuangren.name, true)
    else
      room:addPlayerMark(player, "@@ty__shuangren_prohibit-phase")
    end
  end,
})

ty__shuangren:addEffect('prohibit', {
  name = "#ty__shuangren_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty__shuangren_prohibit-phase") > 0 and card.trueName == "slash"
  end,
})

ty__shuangren:addEffect('active', {
  name = "#ty__shuangren_active",
  card_num = 0,
  card_filter = Util.FalseFunc,
  min_target_num = 1,
  max_target_num = 2,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected < 2 then
      local to = Fk:currentRoom():getPlayerById(to_select)
      return to.kingdom == player:getMark("ty__shuangren_kingdom")
    end
  end,
  feasible = function(self, player, selected, selected_cards)
    if #selected_cards == 0 and #selected > 0 and #selected <= 2 then
      return #selected == 1 or table.contains(selected, player:getMark("ty__shuangren_target"))
    end
  end,
})

return ty__shuangren
