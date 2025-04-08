local suchou = fk.CreateSkill {
  name = "suchou",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["suchou"] = "夙仇",
  [":suchou"] = "锁定技，出牌阶段开始时，你需选择一项：1.减1点体力上限或失去1点体力，你于此阶段内使用牌不能被响应；2.失去此技能。",

  ["suchou_lose"] = "失去此技能",
  ["@@suchou-phase"] = "夙仇",

  ["$suchou1"] = "关家人我杀定了，谁也保不住！",
  ["$suchou2"] = "身陷仇海，谁知道我是怎么过的！",
}

suchou:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(suchou.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askToChoice(player, {
      choices = {"loseHp", "loseMaxHp", "suchou_lose"},
      skill_name = suchou.name,
    })
    if choice == "suchou_lose" then
      room:handleAddLoseSkills(player, "-suchou")
      return
    end
    if choice == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, suchou.name)
    end
    if player.dead then return end
    room:setPlayerMark(player, "@@suchou-phase", 1)
  end,
})

suchou:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      player:getMark("@@suchou-phase") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return suchou
