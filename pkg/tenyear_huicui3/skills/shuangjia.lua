local shuangjia = fk.CreateSkill {
  name = "shuangjia"
}

Fk:loadTranslationTable{
  ['shuangjia'] = '霜笳',
  ['@@shuangjia-inhand'] = '胡笳',
  ['beifen'] = '悲愤',
  ['@shuangjia'] = '胡笳',
  [':shuangjia'] = '锁定技，游戏开始时，你的初始手牌增加“胡笳”标记且不计入手牌上限。你每拥有一张“胡笳”，其他角色计算与你距离+1（最多+5）。',
  ['$shuangjia1'] = '塞外青鸟匿，不闻折柳声。',
  ['$shuangjia2'] = '向晚吹霜笳，雪落白发生。',
}

shuangjia:addEffect(fk.GameStart, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player)
    return player:hasSkill(shuangjia.name) and not player:isKongcheng()
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cards = player:getCardIds(Player.Hand)
    for _, id in ipairs(cards) do
      room:setCardMark(Fk:getCardById(id), "@@shuangjia-inhand", 1)
    end
    room:setPlayerMark(player, "beifen", #cards)
    room:setPlayerMark(player, "@shuangjia", #cards)
  end,
})

shuangjia:addEffect(fk.AfterCardsMove, {
  can_refresh = function(self, event, target, player)
    return #player:getTableMark("beifen") > 0
  end,
  on_refresh = function(self, event, target, player)
    local room = player.room
    local mark = player:getTableMark("beifen")
    for _, id in ipairs(player:getCardIds(Player.Hand)) do
      local card = Fk:getCardById(id)
      local value = table.contains(mark, id) and 1 or 0
      if card:getMark("@@shuangjia-inhand") ~= value then
        room:setCardMark(card, "@@shuangjia-inhand", value)
      end
    end
  end,
})

shuangjia:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return card:getMark("@@shuangjia-inhand") > 0
  end,
})

shuangjia:addEffect('distance', {
  correct_func = function(self, from, to)
    return math.min(to:getMark("@shuangjia"), 5)
  end,
})

return shuangjia
