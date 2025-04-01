local liehou = fk.CreateSkill {
  name = "ty__liehou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__liehou"] = "列侯",
  [":ty__liehou"] = "锁定技，摸牌阶段，你额外摸一张牌，然后选择一项：1.弃置等量的牌；2.失去1点体力。",

  ["#ty__liehou-discard"] = "列侯：你需弃置%arg张牌，否则失去1点体力",

  ["$ty__liehou1"] = "论功行赏，加官进侯。",
  ["$ty__liehou2"] = "增班列侯，赏赐无量！"
}

liehou:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, liehou.name, 0)
end)

liehou:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(liehou.name)
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1 + player:getMark(liehou.name)
    data.extra_data = data.extra_data or {}
    data.extra_data.ty__liehou = 1 + player:getMark(liehou.name)
  end
})

liehou:addEffect(fk.AfterDrawNCards, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return player:usedSkillTimes(liehou.name, Player.HistoryPhase) > 0 and not player.dead and
      data.extra_data and data.extra_data.ty__liehou
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.extra_data.ty__liehou
    if #room:askToDiscard(player, {
      min_num = n,
      max_num = n,
      include_equip = true,
      skill_name = liehou.name,
      cancelable = true,
      prompt = "#ty__liehou-discard:::"..n
    }) == 0 then
      room:loseHp(player, 1, liehou.name)
    end
  end
})

return liehou
