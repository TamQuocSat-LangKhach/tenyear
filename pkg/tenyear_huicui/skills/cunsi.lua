local cunsi = fk.CreateSkill {
  name = "ty__cunsi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["ty__cunsi"] = "存嗣",
  [":ty__cunsi"] = "限定技，出牌阶段，你可以令一名角色获得〖勇决〗；若不为你，你摸两张张牌。",

  ["#ty__cunsi"] = "存嗣：令一名角色获得“勇决”，若不为你，你摸两张牌",

  ["$ty__cunsi1"] = "存汉室之嗣，留汉室之本。",
  ["$ty__cunsi2"] = "一切，便托付将军了！",
}

cunsi:addEffect("active", {
  anim_type = "support",
  prompt = "#ty__cunsi",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(cunsi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:handleAddLoseSkills(target, "ty__yongjue")
    if target ~= player then
      player:drawCards(2, cunsi.name)
    end
  end,
})

return cunsi
