local anxu = fk.CreateSkill {
  name = "ty_ex__anxu",
}

Fk:loadTranslationTable{
  ["ty_ex__anxu"] = "安恤",
  [":ty_ex__anxu"] = "出牌阶段限一次，你可以选择两名手牌数不同的其他角色，令其中手牌少的角色获得手牌多的角色一张手牌并展示之："..
  "若此牌不为♠，你摸一张牌；若其手牌数因此相同，你回复1点体力。",

  ["#ty_ex__anxu"] = "安恤：选择两名手牌数不同的其他角色，手牌少的角色获得手牌多的角色一张手牌",

  ["$ty_ex__anxu1"] = "温言呢喃，消君之愁。",
  ["$ty_ex__anxu2"] = "吴侬软语，以解君忧。",
}

anxu:addEffect("active", {
  anim_type = "control",
  prompt = "#ty_ex__anxu",
  card_num = 0,
  target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(anxu.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    if #selected > 1 or to_select == player then return end
    if #selected == 0 then
      return true
    elseif #selected == 1 then
      return to_select:getHandcardNum() ~= selected[1]:getHandcardNum()
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local from, to = effect.tos[1], effect.tos[2]
    if from:getHandcardNum() > to:getHandcardNum() then
      from, to = to, from
    end
    local card = room:askToChooseCard(from, {
      target = to,
      flag = "h",
      skill_name = anxu.name,
    })
    room:obtainCard(from, card, true, fk.ReasonPrey, from, anxu.name)
    if not from.dead and table.contains(from:getCardIds("h"), card) then
      from:showCards(card)
    end
    if Fk:getCardById(card).suit ~= Card.Spade and not player.dead then
      player:drawCards(1, anxu.name)
    end
    if from:getHandcardNum() == to:getHandcardNum() and player:isWounded() and not player.dead then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = anxu.name,
      }
    end
  end,
})

return anxu
