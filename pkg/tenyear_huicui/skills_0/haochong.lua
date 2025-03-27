local haochong = fk.CreateSkill {
  name = "haochong"
}

Fk:loadTranslationTable{
  ['haochong'] = '昊宠',
  ['#haochong-discard'] = '昊宠：你可以将手牌弃至手牌上限（弃置%arg张），然后手牌上限+1',
  ['#haochong-draw'] = '昊宠：你可以将手牌摸至手牌上限（当前手牌上限%arg，最多摸五张），然后手牌上限-1',
  [':haochong'] = '当你使用一张牌后，你可以将手牌调整至手牌上限（最多摸五张），然后若你以此法：获得牌，你的手牌上限-1；失去牌，你的手牌上限+1。',
  ['$haochong1'] = '朗螟蛉之子，幸隆曹氏厚恩。',
  ['$haochong2'] = '幸得义父所重，必效死奉曹。',
}

haochong:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(haochong.name) and player:getHandcardNum() ~= player:getMaxCards()
  end,
  on_cost = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player:getMaxCards()
    if n > 0 then
      local cards = player.room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = haochong.name,
        cancelable = true,
        prompt = "#haochong-discard:::"..tostring(n),
        skip = true
      })
      if #cards > 0 then
        event:setCostData(self, cards)
        return true
      end
    else
      local params = {
        skill_name = haochong.name,
        prompt = "#haochong-draw:::"..player:getMaxCards()
      }
      if player.room:askToSkillInvoke(player, params) then
        event:setCostData(self, {})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cost_data = event:getCostData(self)
    if #cost_data > 0 then
      room:throwCard(cost_data, haochong.name, player, player)
      room:addPlayerMark(player, MarkEnum.AddMaxCards, 1)
      room:broadcastProperty(player, "MaxCards")
    else
      local n = player:getMaxCards() - player:getHandcardNum()
      player:drawCards(math.min(n, 5), haochong.name)
      if player:getMaxCards() > 0 then  --不允许减为负数
        room:addPlayerMark(player, MarkEnum.MinusMaxCards, 1)
        room:broadcastProperty(player, "MaxCards")
      end
    end
  end,
})

return haochong
