local xingzuo = fk.CreateSkill {
  name = "xingzuo",
}

Fk:loadTranslationTable{
  ["xingzuo"] = "兴作",
  [":xingzuo"] = "出牌阶段开始时，你可以观看牌堆底的三张牌并用任意张手牌替换其中等量的牌。若如此做，结束阶段，你可以令一名有手牌的角色"..
  "用所有手牌替换牌堆底的三张牌，然后若交换前该角色的手牌数大于3，你失去1点体力。",

  ["#xingzuo-exchange"] = "兴作：你可以观看牌堆底的三张牌，用手牌替换其中等量的牌",
  ["#xingzuo-choose"] = "兴作：令一名角色用所有手牌交换牌堆底三张牌，若交换前手牌数大于3，你失去1点体力",

  ["$xingzuo1"] = "顺人之情，时之势，兴作可成。",
  ["$xingzuo2"] = "兴作从心，相继不绝。",
}

xingzuo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingzuo.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local results = room:askToArrangeCards(player, {
      skill_name = xingzuo.name,
      card_map = {
        "Bottom", room:getNCards(3, "bottom"),
        "$Hand", player:getCardIds("h"),
      },
      prompt = "#xingzuo-exchange",
    })
    room:swapCardsWithPile(player, results[1], results[2], xingzuo.name, "Bottom")
  end
})

xingzuo:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and not player.dead and player.phase == Player.Finish and
      player:usedSkillTimes(xingzuo.name, Player.HistoryTurn) > 0 and
      table.find(player.room.alive_players, function(p)
        return not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#xingzuo-choose",
      skill_name = xingzuo.name,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = to:getHandcardNum()
    room:swapCardsWithPile(to, to:getCardIds("h"), room:getNCards(3, "bottom"), xingzuo.name, "Bottom")
    if n > 3 and not player.dead then
      room:loseHp(player, 1, xingzuo.name)
    end
  end,
})

return xingzuo
