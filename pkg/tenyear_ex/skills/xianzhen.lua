local xianzhen = fk.CreateSkill {
  name = "ty_ex__xianzhen",
}

Fk:loadTranslationTable{
  ["ty_ex__xianzhen"] = "陷阵",
  [":ty_ex__xianzhen"] = "每回合限一次，出牌阶段，你可以与一名角色拼点：若你赢，本回合你无视该角色的防具、对其使用牌无距离和次数限制，"..
  "且你本回合使用牌对其造成伤害时，此伤害+1（每回合每种牌名限一次）；若你没赢，本回合你不能使用【杀】且你的【杀】不计入手牌上限。",

  ["#ty_ex__xianzhen"] = "陷阵：与一名角色拼点，若赢，对其使用牌无距离次数限制且无视防具、伤害+1",
  ["@@ty_ex__xianzhen-turn"] = "陷阵",

  ["$ty_ex__xianzhen1"] = "精练整齐，每战必克！",
  ["$ty_ex__xianzhen2"] = "陷阵杀敌，好不爽快！",
}

xianzhen:addEffect("active", {
  anim_type = "offensive",
  prompt = "#ty_ex__xianzhen",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(xianzhen.name, Player.HistoryTurn) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and player:canPindian(to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local pindian = player:pindian({target}, xianzhen.name)
    if pindian.results[target].winner == player then
      room:addTableMark(target, "@@ty_ex__xianzhen-turn", player.id)
      room:addTableMark(player, MarkEnum.MarkArmorInvalidTo .. "-turn", target.id)
    elseif not player.dead then
      room:setPlayerMark(player, "ty_ex__xianzhen_lose-turn", 1)
    end
  end,
})

xianzhen:addEffect(fk.DamageCaused, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(data.to:getTableMark("@@ty_ex__xianzhen-turn"), player.id) and
      data.card and not table.contains(player:getTableMark("ty_ex__xianzhen_card-turn"), data.card.trueName)
  end,
  on_use = function(self, event, target, player, data)
    player.room:addTableMark(player, "ty_ex__xianzhen_card-turn", data.card.trueName)
    data:changeDamage(1)
  end,
})

xianzhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and table.contains(to:getTableMark("@@ty_ex__xianzhen-turn"), player.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and table.contains(to:getTableMark("@@ty_ex__xianzhen-turn"), player.id)
  end,
})

xianzhen:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("ty_ex__xianzhen_lose-turn") > 0 and card and card.trueName == "slash"
  end,
})

xianzhen:addEffect("maxcards", {
  exclude_from = function(self, player, card)
    return card.trueName == "slash" and player:getMark("ty_ex__xianzhen_lose-turn") > 0
  end,
})

return xianzhen
