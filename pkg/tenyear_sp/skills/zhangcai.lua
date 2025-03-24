local zhangcai = fk.CreateSkill {
  name = "zhangcai",
}

Fk:loadTranslationTable{
  ["zhangcai"] = "彰才",
  [":zhangcai"] = "当你使用或打出点数为8的牌时，你可以摸X张牌（X为手牌中与使用的牌点数相同的牌的数量且至少为1）。",

  ["$zhangcai1"] = "今提墨笔绘乾坤，湖海添色山永春。",
  ["$zhangcai2"] = "手提玉剑斥千军，昔日锦鲤化金龙。",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhangcai.name) and
      (player:getMark("@@ruxian") > 0 or data.card.number == 8)
  end,
  on_use = function(self, event, target, player, data)
    local n = #table.filter(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):compareNumberWith(data.card, false)
    end)
    player:drawCards(math.max(1, n), zhangcai.name)
  end,
}

zhangcai:addEffect(fk.CardUsing, spec)
zhangcai:addEffect(fk.CardResponding, spec)

return zhangcai
