local jiangchi = fk.CreateSkill {
  name = "ty_ex__jiangchi",
}

Fk:loadTranslationTable{
  ["ty_ex__jiangchi"] = "将驰",
  [":ty_ex__jiangchi"] = "出牌阶段开始时，你可以选择一项：1.摸两张牌，此阶段不能使用或打出【杀】；2.摸一张牌；3.弃置一张牌，"..
  "此阶段使用【杀】无距离限制且可以多使用一张【杀】。",

  ["#ty_ex__jiangchi-invoke"] = "将驰：你可以选一项执行",
  ["@@ty_ex__jiangchi_targetmod-phase"] = "将驰 多出杀",
  ["@@ty_ex__jiangchi_prohibit-phase"] = "将驰 禁止出杀",

  ["$ty_ex__jiangchi1"] = "率师而行，所向皆破！",
  ["$ty_ex__jiangchi2"] = "数从征伐，志意慷慨，不避险阻！",
}

jiangchi:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiangchi.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__jiangchi_active",
      prompt = "#ty_ex__jiangchi-invoke",
      cancelable = true,
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards, choice = dat.interaction})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    if choice == "ty_ex__jiangchi_discard" then
      room:setPlayerMark(player, "@@ty_ex__jiangchi_targetmod-phase", 1)
      room:throwCard(event:getCostData(self).cards, jiangchi.name, player, player)
    elseif choice == "draw1" then
      player:drawCards(1, jiangchi.name)
    elseif choice == "ty_ex__jiangchi_draw2" then
      room:setPlayerMark(player, "@@ty_ex__jiangchi_prohibit-phase", 1)
      player:drawCards(2, jiangchi.name)
    end
  end,
})

jiangchi:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0 and
      scope == Player.HistoryPhase then
      return 1
    end
  end,
  bypass_distances = function(self, player, skill, card, to)
    return skill.trueName == "slash_skill" and player:getMark("@@ty_ex__jiangchi_targetmod-phase") > 0
  end,
})

jiangchi:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    return player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0 and card and card.trueName == "slash"
  end,
  prohibit_response = function (skill, player, card)
    return player:getMark("@@ty_ex__jiangchi_prohibit-phase") > 0 and card and card.trueName == "slash"
  end
})

return jiangchi
