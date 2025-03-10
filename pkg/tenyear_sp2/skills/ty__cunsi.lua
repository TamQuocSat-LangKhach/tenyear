local ty__cunsi = fk.CreateSkill {
  name = "ty__cunsi"
}

Fk:loadTranslationTable{
  ['ty__cunsi'] = '存嗣',
  ['#ty__cunsi'] = '存嗣：你可以令一名角色获得〖勇决〗，若不为你，你摸两张牌',
  ['ty__yongjue'] = '勇决',
  [':ty__cunsi'] = '限定技，出牌阶段，你可以令一名角色获得〖勇决〗；若不为你，你摸两张张牌。',
  ['$ty__cunsi1'] = '存汉室之嗣，留汉室之本。',
  ['$ty__cunsi2'] = '一切，便托付将军了！',
}

ty__cunsi:addEffect('active', {
  anim_type = "support",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  prompt = "#ty__cunsi",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__cunsi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player),
      min_num = 1,
      max_num = 1,
      skill_name = ty__cunsi.name
    })
    if #target > 0 then 
      target = target[1]
      room:handleAddLoseSkills(target, "ty__yongjue", nil, true, false)
      if target ~= player then
        player:drawCards(2, ty__cunsi.name)
      end
    end
  end,
})

return ty__cunsi
