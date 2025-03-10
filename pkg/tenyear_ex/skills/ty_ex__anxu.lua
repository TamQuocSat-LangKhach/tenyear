local ty_ex__anxu = fk.CreateSkill {
  name = "ty_ex__anxu"
}

Fk:loadTranslationTable{
  ['ty_ex__anx__anxu'] = '安恤',
  ['#ty_ex__anxu'] = '安恤：选择两名手牌数不同的其他角色，手牌少的角色获得手牌多的角色一张手牌',
  [':ty_ex__anxu'] = '出牌阶段限一次，你可以选择两名手牌数不同的其他角色，令其中手牌少的角色获得手牌多的角色一张手牌并展示之：若此牌不为♠，你摸一张牌；若其手牌数因此相同，你回复1点体力。',
  ['$ty_ex__anxu1'] = '温言呢喃，消君之愁。',
  ['$ty_ex__anxu2'] = '吴侬软语，以解君忧。',
}

ty_ex__anxu:addEffect('active', {
  anim_type = "control",
  target_num = 2,
  card_num = 0,
  prompt = "#ty_ex__anxu",
  can_use = function(self, player)
    return player:usedSkillTimes(ty_ex__anxu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 1 or to_select.id == player.id then return false end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      local target1 = Fk:currentRoom():getPlayerById(to_select.id)
      local target2 = Fk:currentRoom():getPlayerById(selected[1].id)
      return target1:getHandcardNum() ~= target2:getHandcardNum()
    else
      return false
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target1 = room:getPlayerById(effect.tos[1].id)
    local target2 = room:getPlayerById(effect.tos[2].id)
    local from, to
    if target1:getHandcardNum() < target2:getHandcardNum() then
      from = target1
      to = target2
    else
      from = target2
      to = target1
    end
    local id = room:askToChooseCard({
      player = from,
      target = to,
      flag = "h",
      skill_name = ty_ex__anxu.name
    })
    room:obtainCard(from.id, id, true, fk.ReasonPrey)
    if table.contains(from:getCardIds("h"), id) then
      from:showCards({id})
    end
    if Fk:getCardById(id).suit ~= Card.Spade then
      player:drawCards(1, ty_ex__anxu.name)
    end
    if target1:getHandcardNum() == target2:getHandcardNum() and player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ty_ex__anxu.name
      }
    end
  end,
})

return ty_ex__anxu
