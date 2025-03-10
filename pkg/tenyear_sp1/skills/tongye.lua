local tongye = fk.CreateSkill {
  name = "tongye"
}

Fk:loadTranslationTable{
  ['tongye'] = '统业',
  ['@tongye_count'] = '统业',
  [':tongye'] = '锁定技，游戏开始时，或其他角色死亡后，你根据场上势力数获得对应效果（覆盖之前获得的效果）：不大于4，你的手牌上限+3；不大于3，你的攻击范围+3，摸牌阶段摸牌数增加4减去势力数；不大于2，你于出牌阶段内使用【杀】的次数上限+3；为1，你回复3点体力。',
  ['$tongye1'] = '白首全金瓯，著风流于春秋。',
  ['$tongye2'] = '长戈斩王气，统大业于四海。',
}

tongye:addEffect(fk.GameStart, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(tongye.name) 
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:setPlayerMark(player, "@tongye_count", #kingdoms)
    room:broadcastProperty(player, "MaxCards")
    if #kingdoms == 1 then
      room:recover{
        who = player,
        num = 3,
        recoverBy = player,
        skillName = tongye.name,
      }
    end
  end,
})

tongye:addEffect(fk.Deathed, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(tongye.name) 
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:setPlayerMark(player, "@tongye_count", #kingdoms)
    room:broadcastProperty(player, "MaxCards")
    if #kingdoms == 1 then
      room:recover{
        who = player,
        num = 3,
        recoverBy = player,
        skillName = tongye.name,
      }
    end
  end,
})

tongye:addEffect(fk.DrawNCards, {
  frequency = Skill.Compulsory,
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player)
    return 
      player:hasSkill(tongye.name) and
      (player == target and player:getMark("@tongye_count") > 0 and player:getMark("@tongye_count") < 4)
  end,
  on_use = function(self, event, target, player, data)
    if player:getMark("@tongye_count") then
      data.n = data.n + 4 - player:getMark("@tongye_count")
    end
  end,
})

tongye:addEffect('maxcards', {
  correct_func = function(self, player)
    if
      player:hasSkill(tongye.name) and
      player:getMark("@tongye_count") > 0 and
      player:getMark("@tongye_count") <= 4
    then
      return 3
    end
  end,
})

tongye:addEffect('atkrange', {
  correct_func = function (skill, from)
    if
      from:hasSkill(tongye.name) and
      from:getMark("@tongye_count") > 0 and
      from:getMark("@tongye_count") <= 3
    then
      return 3
    end
  end,
})

tongye:addEffect('targetmod', {
  residue_func = function(self, player, skill, scope)
    if
      skill.trueName == "slash_skill" and
      player:hasSkill(tongye.name) and
      player:getMark("@tongye_count") > 0 and
      player:getMark("@tongye_count") <= 2
    then
      return 3
    end
    return 0
  end,
})

return tongye
