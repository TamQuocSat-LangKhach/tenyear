local lixia = fk.CreateSkill {
  name = "ty__lixia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__lixia"] = "礼下",
  [":ty__lixia"] = "锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.令其摸两张牌。然后其他角色计算与你的距离-1。",

  ["ty__lixia_draw"] = "令%src摸两张牌",

  ["$ty__lixia1"] = "得人才者，得天下。",
  ["$ty__lixia2"] = "礼贤下士，方得民心。",
}

lixia:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(lixia.name) and target.phase == Player.Finish and
      not target:inMyAttackRange(player) and not target.dead
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"draw1", "ty__lixia_draw:" .. player.id},
      skill_name = lixia.name,
    })
    if choice == "draw1" then
      player:drawCards(1, lixia.name)
    else
      target:drawCards(2, lixia.name)
    end
    if player.dead then return end
    local num = tonumber(player:getMark("@ty__shixie_distance")) - 1
    room:setPlayerMark(player, "@ty__shixie_distance", num > 0 and "+" .. num or num)
  end,
})

lixia:addEffect("distance", {
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num < 0 then
      return num
    end
  end,
})

return lixia
