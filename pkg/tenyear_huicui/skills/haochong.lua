local haochong = fk.CreateSkill {
  name = "haochong",
}

Fk:loadTranslationTable{
  ["haochong"] = "昊宠",
  [":haochong"] = "当你使用一张牌后，你可以将手牌调整至手牌上限（最多摸五张），然后若你以此法：获得牌，你的手牌上限-1；失去牌，你的手牌上限+1。",

  ["#haochong-discard"] = "昊宠：你可以将手牌弃至手牌上限（弃%arg张），然后手牌上限+1",
  ["#haochong-draw"] = "昊宠：你可以将手牌摸至手牌上限（当前手牌上限%arg，最多摸五张），然后手牌上限-1",

  ["$haochong1"] = "朗螟蛉之子，幸隆曹氏厚恩。",
  ["$haochong2"] = "幸得义父所重，必效死奉曹。",
}

haochong:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(haochong.name) and player:getHandcardNum() ~= player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum() - player:getMaxCards()
    if n > 0 then
      local cards = room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = haochong.name,
        cancelable = true,
        prompt = "#haochong-discard:::"..n,
        skip = true,
      })
      if #cards > 0 then
        event:setCostData(self, {cards = cards})
        return true
      end
    elseif room:askToSkillInvoke(player, {
        skill_name = haochong.name,
        prompt = "#haochong-draw:::"..player:getMaxCards(),
      }) then
      event:setCostData(self, nil)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event:getCostData(self) ~= nil then
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      room:throwCard(event:getCostData(self).cards, haochong.name, player, player)
    else
      local n = math.min(player:getMaxCards() - player:getHandcardNum(), 5)
      if player:getMaxCards() > 0 then
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
      end
      player:drawCards(n, haochong.name)
    end
  end,
})

return haochong
