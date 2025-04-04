local suchou = fk.CreateSkill {
  name = "suchou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['suchou'] = '夙仇',
  ['loseSuchou'] = '失去〖夙仇〗',
  ['@@suchou-phase'] = '夙仇',
  [':suchou'] = '锁定技，出牌阶段开始时，你选择：1.减1点体力上限或失去1点体力，你于此阶段内使用牌不能被响应；2.失去此技能。',
  ['$suchou1'] = '关家人我杀定了，谁也保不住！',
  ['$suchou2'] = '身陷仇海，谁知道我是怎么过的！',
}

suchou:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(suchou.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"loseHp", "loseMaxHp", "loseSuchou"},
      skill_name = suchou.name
    })
    if choice == "loseSuchou" then
      room:handleAddLoseSkills(player, "-suchou", nil, true, false)
      return false
    end
    if choice == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, suchou.name)
    end
    if player.dead then return false end
    room:setPlayerMark(player, "@@suchou-phase", 1)
  end,
})

suchou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return player == target and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:getMark("@@suchou-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
})

return suchou
