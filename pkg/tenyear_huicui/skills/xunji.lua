local xunji = fk.CreateSkill {
  name = "xunji",
}

Fk:loadTranslationTable{
  ["xunji"] = "寻嫉",
  [":xunji"] = "出牌阶段限一次，你可以秘密选择一名其他角色。该角色的下个结束阶段，若其本回合使用过黑色牌，则你视为对其使用一张【决斗】；"..
  "若此【决斗】对其造成伤害且其存活，其对你造成等量的伤害。",

  ["#xunji"] = "寻嫉：秘密选择一名其他角色，若其下回合使用过黑色牌，则视为对其使用【决斗】",

  ["$xunji1"] = "待拿下你，再找丞相谢罪。",
  ["$xunji2"] = "姓关的，我现在就来抓你！",
}

xunji:addEffect("active", {
  anim_type = "offensive",
  no_indicate = true,
  card_num = 0,
  target_num = 1,
  prompt = "#xunji",
  can_use = function(self, player)
    return player:usedSkillTimes(xunji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMarkIfNeed(target, xunji.name, player.id)
  end,
})

xunji:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target.phase == Player.Finish and table.contains(target:getTableMark(xunji.name), player.id) and
      not player.dead and not target.dead then
      player.room:removeTableMark(target, xunji.name, player.id)
      return #player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
        local use = e.data
        return use.from == target and use.card.color == Card.Black
      end, Player.HistoryTurn) > 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {target}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = room:useVirtualCard("duel", nil, player, target, xunji.name)
    if use and not player.dead and not target.dead and use.damageDealt and use.damageDealt[target] then
      room:damage{
        from = target,
        to = player,
        damage = use.damageDealt[target],
        skill_name = xunji.name,
      }
    end
  end,
})

xunji:addLoseEffect(function (self, player, is_death)
  local room = player.room
  for _, p in ipairs(room.alive_players) do
    room:removeTableMark(p, xunji.name, player.id)
  end
end)

return xunji
