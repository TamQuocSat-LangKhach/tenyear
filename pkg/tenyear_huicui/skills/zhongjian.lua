local zhongjian = fk.CreateSkill {
  name = "ty__zhongjian",
}

Fk:loadTranslationTable{
  ["ty__zhongjian"] = "忠鉴",
  [":ty__zhongjian"] = "出牌阶段限一次，你可以秘密选择一名本回合未选择过的角色，并秘密选一项，直到你的下回合开始："..
  "1.当该角色下次造成伤害后，其弃置两张牌；2.当该角色下次受到伤害后，其摸两张牌。当〖忠鉴〗被触发时，你摸一张牌。",

  ["#ty__zhongjian"] = "忠鉴：秘密选择一名角色，当其下次造成或受到伤害后执行效果",
  ["ty__zhongjian_discard"] = "造成伤害后，其弃置两张牌",
  ["ty__zhongjian_draw"] = "受到伤害后，其摸两张牌",

  ["$ty__zhongjian1"] = "闻大忠似奸、大智若愚，不辨之难鉴之。",
  ["$ty__zhongjian2"] = "以眼为镜可正衣冠，以心为镜可鉴忠奸。",
}

zhongjian:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__zhongjian",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  no_indicate = true,
  interaction =  UI.ComboBox { choices = {"ty__zhongjian_discard", "ty__zhongjian_draw"} },
  can_use = function(self, player)
    return player:usedSkillTimes(zhongjian.name, Player.HistoryPhase) < (1 + player:getMark("ty__caishi_twice-turn"))
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not table.contains(player:getTableMark("ty__zhongjian_target-turn"), to_select.id)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "ty__zhongjian_target-turn", target.id)
    local choice = self.interaction.data
    room:addTableMarkIfNeed(player, choice, target.id)
  end,
})

zhongjian:addEffect(fk.Damage, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target and table.contains(player:getTableMark("ty__zhongjian_discard"), target.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "ty__zhongjian_discard", target.id)
    if not target.dead then
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = zhongjian.name,
        cancelable = false,
      })
    end
    if not player.dead then
      player:drawCards(1, zhongjian.name)
    end
  end,
})

zhongjian:addEffect(fk.Damaged, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(player:getTableMark("ty__zhongjian_draw"), target.id)
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:removeTableMark(player, "ty__zhongjian_draw", target.id)
    if not target.dead then
      target:drawCards(2, zhongjian.name)
    end
    if not player.dead then
      player:drawCards(1, zhongjian.name)
    end
  end,
})

zhongjian:addEffect(fk.TurnStart, {
  can_refresh = function (self, event, target, player, data)
    return target == player
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "ty__zhongjian_discard", 0)
    room:setPlayerMark(player, "ty__zhongjian_draw", 0)
  end,
})

return zhongjian
