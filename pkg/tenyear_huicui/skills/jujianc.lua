local jujianc = fk.CreateSkill {
  name = "jujianc$"
}

Fk:loadTranslationTable{
  ['#jujianc-active'] = '发动 拒谏，令一名其他魏势力角色摸一张牌，其本轮内使用普通锦囊牌对你无效',
  ['@@jujianc-round'] = '拒谏',
  ['#jujianc_delay'] = '拒谏',
}

jujianc:addEffect('active', {
  anim_type = "support",
  prompt = "#jujianc-active",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jujianc.name, Player.HistoryPhase) == 0
  end,
  card_filter = function() return false end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and Fk:currentRoom():getPlayerById(to_select).kingdom == "wei"
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:drawCards(target, 1, jujianc.name)
    if player.dead or target.dead then return end
    room:addTableMark(target, "@@jujianc-round", player.id)
  end,
})

jujianc:addEffect(fk.PreCardEffect, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return not player.dead and player.id == data.to and data.card:isCommonTrick() and target and
      table.contains(target:getTableMark("@@jujianc-round"), player.id)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    room:askToSkillInvoke(player, {
      skill_name = jujianc.name,
    })
    return true
  end,
})

return jujianc
