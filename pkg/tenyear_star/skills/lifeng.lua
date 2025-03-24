local lifeng = fk.CreateSkill {
  name = "lifengc",
}

Fk:loadTranslationTable{
  ["lifengc"] = "砺锋",
  [":lifengc"] = "你可以将一张本回合未被使用过的颜色的手牌当不计次数的【杀】或【无懈可击】使用。",

  ["#lifengc"] = "砺锋：将一张牌当不计次数的【杀】或【无懈可击】使用",

  ["$lifengc1"] = "锋出百砺，健卒亦如是。",
  ["$lifengc2"] = "强军者，必校之以三九，练之三伏。",
}

local U = require "packages/utility/utility"

lifeng:addEffect("viewas", {
  pattern = "slash,nullification",
  prompt = "#lifengc",
  interaction = function(self, player)
    local all_names = {"slash", "nullification"}
    local names = player:getViewAsCardNames(lifeng.name, all_names)
    if #names == 0 then return end
    return U.CardNameBox {choices = names, all_choices = all_names}
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select) and
      Fk:getCardById(to_select).color ~= Card.NoColor and
      not table.contains(player:getTableMark("lifengc-turn"), Fk:getCardById(to_select).color)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or self.interaction.data == nil then return end
    local card_name = self.interaction.data
    local card = Fk:cloneCard(card_name)
    card.skillName = lifeng.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response and #player:getHandlyIds() > 0 and #player:getTableMark("lifengc-turn") < 2
  end,
})

lifeng:addEffect("targetmod", {
  bypass_times = function (self, player, skill, scope, card, to)
    return card and table.contains(card.skillNames, lifeng.name)
  end,
})

lifeng:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(lifeng.name) and data.card.color ~= Card.NoColor
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addTableMark(player, "lifengc-turn", data.card.color)
  end,
})

lifeng:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local mark = {}
    room.logic:getEventsOfScope(GameEvent.UseCard, 1, function (e)
      local use = e.data
      if use.from == player and use.card.color ~= Card.NoColor then
        table.insertIfNeed(mark, use.card.color)
      end
    end, Player.HistoryTurn)
    if #mark > 0 then
      room:setPlayerMark(player, "lifengc-turn", mark)
    end
  end
end)

return lifeng
