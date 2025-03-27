local fuzhong = fk.CreateSkill {
  name = "fuzhong"
}

Fk:loadTranslationTable{
  ['fuzhong'] = '负重',
  ['@fuzhong_weight'] = '重',
  ['#fuzhong-choose'] = '负重：必须选择一名其他角色，对其造成1点伤害，然后移去4个重标记',
  [':fuzhong'] = '锁定技，当你于回合外得到牌时，你获得一枚“重”标记。当你的“重”标记数：大于等于1，摸牌阶段，你多摸一张牌；大于等于2，你计算与其他角色的距离-2；大于等于3，你的手牌上限+3；大于等于4，结束阶段，你对一名其他角色造成1点伤害，然后移去4个“重”。',
  ['$fuzhong1'] = '身负重任，绝无懈怠。',
  ['$fuzhong2'] = '勇冠其军，负重前行。',
}

fuzhong:addEffect(fk.AfterCardsMove, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fuzhong.name) and player.phase == Player.NotActive then
      for _, move in ipairs(data) do
        if move.to == player.id and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, fuzhong.name)
    player:broadcastSkillInvoke(fuzhong.name)
    room:addPlayerMark(player, "@fuzhong_weight")
  end,
})

fuzhong:addEffect(fk.DrawNCards, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@fuzhong_weight") > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, fuzhong.name, "drawcard")
    player:broadcastSkillInvoke(fuzhong.name)
    data.n = data.n + 1
  end,
})

fuzhong:addEffect(fk.EventPhaseStart, {
  frequency = Skill.Compulsory,
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player.phase == Player.Finish and player:getMark("@fuzhong_weight") > 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, fuzhong.name, "offensive")
    player:broadcastSkillInvoke(fuzhong.name)
    local targets = room:askToChoosePlayers(player, {
      targets = table.map(player.room:getOtherPlayers(player, false), Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#fuzhong-choose",
      skill_name = fuzhong.name
    })
    if #targets > 0 then
      room:damage{
        from = player,
        to = targets[1],
        damage = 1,
        skillName = fuzhong.name,
      }
      room:removePlayerMark(player, "@fuzhong_weight", 4)
    end
  end,
})

fuzhong:addEffect('distance', {
  frequency = Skill.Compulsory,
  correct_func = function(self, from, to)
    if from:hasSkill(fuzhong.name) and from:getMark("@fuzhong_weight") > 1 then
      return -2
    end
  end,
})

fuzhong:addEffect('maxcards', {
  correct_func = function(self, player)
    if player:hasSkill(fuzhong.name) and player:getMark("@fuzhong_weight") > 2 then
      return 3
    end
  end,
})

return fuzhong
