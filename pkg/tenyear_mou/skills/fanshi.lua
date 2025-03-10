local fanshi = fk.CreateSkill {
  name = "fanshi"
}

Fk:loadTranslationTable{
  ['fanshi'] = '返势',
  ['jianzhuan'] = '渐专',
  [':fanshi'] = '觉醒技，结束阶段。若〖渐专〗的选项数小于2，你依次执行3次剩余项，加2点体力上限，回复2点体力，失去〖渐专〗，获得〖覆斗〗。',
  ['$fanshi1'] = '垒巨木为寨，发屯兵自守。',
  ['$fanshi2'] = '吾居伊周之位，怎可以罪见黜？',
}

fanshi:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Wake,
  can_trigger = function(self, event, target, player)
    return target == player and player.phase == Player.Finish and player:hasSkill(fanshi) 
      and player:usedSkillTimes(fanshi.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player)
    if player:hasSkill(jianzhuan, true) then
      local x = 0
      for i = 1, 4 do
        if player:getMark("jianzhuan"..tostring(i)) == 0 then
          x = x + 1
        end
      end
      return x < 2
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local choice = ""
    for i = 1, 4 do
      choice = "jianzhuan"..tostring(i)
      if player:getMark(choice) == 0 then
        for j = 1, 3 do
          doJianzhuan(player, choice, 1)
          if player.dead then return false end
        end
        break
      end
    end
    room:changeMaxHp(player, 2)
    if player.dead then return false end
    if player:isWounded() then
      room:recover({
        who = player,
        num = 2,
        recoverBy = player,
        skillName = fanshi.name,
      })
      if player.dead then return false end
    end
    room:handleAddLoseSkills(player, "-jianzhuan|fudou", nil, true, false)
  end,
})

return fanshi
