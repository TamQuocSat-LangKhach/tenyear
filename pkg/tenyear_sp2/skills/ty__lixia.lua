local ty__lixia = fk.CreateSkill {
  name = "ty__lixia"
}

Fk:loadTranslationTable{
  ['ty__lixia'] = '礼下',
  ['ty__lixia_draw'] = '令%src摸两张牌',
  ['@ty__shixie_distance'] = '距离',
  [':ty__lixia'] = '锁定技，其他角色的结束阶段，若你不在其攻击范围内，你选择一项：1.摸一张牌；2.令其摸两张牌。选择完成后，其他角色计算与你的距离-1。',
  ['$ty__lixia1'] = '得人才者，得天下。',
  ['$ty__lixia2'] = '礼贤下士，方得民心。',
}

-- 添加触发技能效果
ty__lixia:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return target ~= player and player:hasSkill(ty__lixia.name) and target.phase == Player.Finish and not target:inMyAttackRange(player)
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"draw1", "ty__lixia_draw:" .. target.id},
      skill_name = ty__lixia.name
    })
    if choice == "draw1" then
      player:drawCards(1, ty__lixia.name)
    else
      target:drawCards(2, ty__lixia.name)
    end
    local num = tonumber(player:getMark("@ty__shixie_distance")) - 1
    room:setPlayerMark(player, "@ty__shixie_distance", num > 0 and "+" .. num or num)
  end,
})

-- 添加距离技能效果
ty__lixia:addEffect('distance', {
  name = "#ty__lixia_distance",
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num < 0 then
      return num
    end
  end,
})

return ty__lixia
