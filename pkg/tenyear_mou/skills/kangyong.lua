local kangyong = fk.CreateSkill {
  name = "kangyong"
}

Fk:loadTranslationTable{
  ['kangyong'] = '亢勇',
  [':kangyong'] = '锁定技，回合开始时，你回复体力至体力上限；回合结束时，你失去等量体力（至多失去至1点）。',
  ['$kangyong1'] = '此猛士之血，其与醇酒孰烈乎？',
  ['$kangyong2'] = '歃血为誓，城在则人在！'
}

kangyong:addEffect(fk.TurnStart, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(kangyong) then
      return player:isWounded()
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local n = player:getLostHp()
    room:setPlayerMark(player, "kangyong-turn", n)
    room:recover({
      who = player,
      num = n,
      recoverBy = player,
      skillName = kangyong.name
    })
  end,
})

kangyong:addEffect(fk.TurnEnd, {
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(kangyong) then
      return player.hp > 1 and player:getMark("kangyong-turn") > 0
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local n = math.min(player:getMark("kangyong-turn"), player.hp - 1)
    room:loseHp(player, n, kangyong.name)
  end,
})

return kangyong
