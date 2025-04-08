local tongyuan = fk.CreateSkill {
  name = "tongyuanz",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["tongyuanz"] = "同援",
  [":tongyuanz"] = "锁定技，当你使用红色锦囊牌后，〖摧坚〗增加效果“若其没有【闪】，你摸两张牌”；<br>"..
  "当你使用或打出红色基本牌后，〖摧坚〗将“交给”的效果删除；<br>"..
  "若以上两个效果均已触发，则你本局游戏使用红色普通锦囊牌无法被响应，使用红色基本牌可以额外指定一个目标。",

  ["#tongyuanz-choose"] = "同援：你可以为%arg额外指定一个目标",

  ["$tongyuanz1"] = "乐将军何在？随我共援上方谷！",
  ["$tongyuanz2"] = "袍泽有难，岂有坐视之理？",
}

tongyuan:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(tongyuan.name) and data.card.color == Card.Red then
      if data.card.type == Card.TypeTrick then
        return player:getMark("tongyuan1") == 0
      elseif data.card.type == Card.TypeBasic then
        return player:getMark("tongyuan2") == 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.card.type == Card.TypeTrick then
      room:setPlayerMark(player, "tongyuan1", 1)
    else
      room:setPlayerMark(player, "tongyuan2", 1)
    end
  end,
})

tongyuan:addEffect(fk.CardRespondFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongyuan.name) and data.card.color == Card.Red and
      data.card.type == Card.TypeBasic and player:getMark("tongyuan2") == 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "tongyuan2", 1)
  end,
})

tongyuan:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("tongyuan1") > 0 and player:getMark("tongyuan2") > 0 and
      data.card.color == Card.Red and data.card:isCommonTrick()
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

tongyuan:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("tongyuan1") > 0 and player:getMark("tongyuan2") > 0 and
      data.card.color == Card.Red and data.card.type == Card.TypeBasic and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#tongyuan-choose:::"..data.card:toLogString(),
      skill_name = tongyuan.name,
    })
    if #to > 0 then
    event:setCostData(self, {tos = to})
    return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return tongyuan
