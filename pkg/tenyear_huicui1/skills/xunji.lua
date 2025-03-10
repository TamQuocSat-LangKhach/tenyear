local xunji = fk.CreateSkill {
  name = "xunji"
}

Fk:loadTranslationTable{
  ['xunji'] = '寻嫉',
  ['#xunji'] = '寻嫉：选择一名其他角色，若其下回合内造成过伤害，则你视为对其使用【决斗】',
  ['@@xunji'] = '寻嫉',
  [':xunji'] = '出牌阶段限一次，你可以秘密选择一名其他角色。该角色下个回合结束阶段，若其本回合使用过黑色牌，则你视为对其使用一张【决斗】；此【决斗】对其造成伤害后，若其存活，则其对你造成等量的伤害。',
  ['$xunji1'] = '待拿下你，再找丞相谢罪。',
  ['$xunji2'] = '姓关的，我现在就来抓你！',
}

-- 主动技能效果
xunji:addEffect('active', {
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
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local mark = target:getMark("@@xunji")
    if not next(mark) then mark = {} end
    table.insertIfNeed(mark, player.id)
    room:setPlayerMark(target, "@@xunji", mark)
  end,
})

-- 触发技能效果
xunji:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Finish and player:getMark("@@xunji") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("@@xunji")
    room:setPlayerMark(player, "@@xunji", 0)
    local turn_event = room.logic:getCurrentEvent():findParent(GameEvent.Turn, true)
    if not turn_event then return false end
    if #room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      local use = e.data[1]
      return use.from == player.id and use.card.color == Card.Black
    end, turn_event.id) == 0 then return false end
    for _, id in ipairs(mark) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead and not p:isProhibited(player, Fk:cloneCard("duel")) then
        p:broadcastSkillInvoke(xunji.name)
        room:notifySkillInvoked(p, xunji.name, "offensive")
        room:doIndicate(p.id, {player.id})
        local use = {
          from = p.id,
          tos = {{player.id}},
          card = Fk:cloneCard("duel"),
          skill_name = xunji.name,
        }
        room:useCard(use)
        if not player.dead and not p.dead and use.damage_dealt and use.damage_dealt[player.id] then
          room:damage{
            from = player,
            to = p,
            damage = use.damage_dealt[player.id],
            skill_name = xunji.name,
          }
        end
      end
    end
  end,
})

return xunji
