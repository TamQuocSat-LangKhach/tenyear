local fuzhong = fk.CreateSkill {
  name = "fuzhong",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["fuzhong"] = "负重",
  [":fuzhong"] = "锁定技，当你于回合外得到手牌后，你获得一枚“重”标记。若你的“重”标记数：<br>"..
  "大于等于1，摸牌阶段，你多摸一张牌；<br>"..
  "大于等于2，你计算与其他角色的距离-2；<br>"..
  "大于等于3，你的手牌上限+3；<br>"..
  "大于等于4，结束阶段，你对一名其他角色造成1点伤害，然后移去4个“重”。",

  ["@fuzhong_weight"] = "重",
  ["#fuzhong-choose"] = "负重：对一名角色造成1点伤害并移去4个“重”标记",

  ["$fuzhong1"] = "身负重任，绝无懈怠。",
  ["$fuzhong2"] = "勇冠其军，负重前行。",
}

fuzhong:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(fuzhong.name) and player.room.current ~= player then
      for _, move in ipairs(data) do
        if move.to == player and move.toArea == Card.PlayerHand then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@fuzhong_weight")
  end,
})

fuzhong:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuzhong.name) and player:getMark("@fuzhong_weight") > 0
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 1
  end,
})

fuzhong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(fuzhong.name) and player.phase == Player.Finish and
      player:getMark("@fuzhong_weight") > 3 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getOtherPlayers(player, false),
      min_num = 1,
      max_num = 1,
      prompt = "#fuzhong-choose",
      skill_name = fuzhong.name,
      cancelable = false,
    })[1]
    room:damage{
      from = player,
      to = to,
      damage = 1,
      skillName = fuzhong.name,
    }
    room:removePlayerMark(player, "@fuzhong_weight", 4)
  end,
})

fuzhong:addEffect("distance", {
  correct_func = function(self, from, to)
    if from:hasSkill(fuzhong.name) and from:getMark("@fuzhong_weight") > 1 then
      return -2
    end
  end,
})

fuzhong:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(fuzhong.name) and player:getMark("@fuzhong_weight") > 2 then
      return 3
    end
  end,
})

fuzhong:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@fuzhong_weight", 0)
end)

return fuzhong
