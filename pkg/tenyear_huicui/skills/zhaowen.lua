local zhaowen = fk.CreateSkill {
  name = "zhaowen",
}

Fk:loadTranslationTable{
  ["zhaowen"] = "昭文",
  [":zhaowen"] = "出牌阶段开始时，你可以展示所有手牌。若如此做，本回合其中的黑色牌可以当任意普通锦囊牌使用（每回合每种牌名限一次），"..
  "其中的红色牌你使用时摸一张牌。",

  ["#zhaowen"] = "昭文：将一张黑色“昭文”牌当任意普通锦囊牌使用",
  ["@@zhaowen-inhand-turn"] = "昭文",
  ["#zhaowen-invoke"] = "昭文：你可以展示手牌，本回合其中黑色牌可以当任意锦囊牌使用，红色牌使用时摸一张牌",

  ["$zhaowen1"] = "我辈昭昭，正始之音浩荡。",
  ["$zhaowen2"] = "正文之昭，微言之绪，绝而复续。",
}

local U = require "packages/utility/utility"

zhaowen:addEffect("viewas", {
  pattern = ".|.|.|.|.|trick|.",
  prompt = "#zhaowen",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local names = player:getViewAsCardNames(zhaowen.name, all_names, {}, player:getTableMark("zhaowen-turn"))
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  card_filter = function(self, player, to_select, selected)
    local card = Fk:getCardById(to_select)
    return #selected == 0 and card.color == Card.Black and card:getMark("@@zhaowen-inhand-turn") > 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return nil end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = zhaowen.name
    return card
  end,
  before_use = function(self, player, use)
    player.room:addTableMark(player, "zhaowen-turn", use.card.trueName)
  end,
  enabled_at_play = function(self, player)
    return table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-inhand-turn") > 0
    end)
  end,
  enabled_at_response = function(self, player, response)
    return not response and table.find(player:getCardIds("h"), function(id)
      return Fk:getCardById(id).color == Card.Black and Fk:getCardById(id):getMark("@@zhaowen-inhand-turn") > 0
    end) and
    #player:getViewAsCardNames(zhaowen.name, Fk:getAllCardNames("t"), {}, player:getTableMark("zhaowen-turn")) > 0
  end,
})

zhaowen:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaowen.name) and player.phase == Player.Play and
      not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhaowen.name,
      prompt = "#zhaowen-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:showCards(player:getCardIds("h"))
    if not player.dead and not player:isKongcheng() then
      for _, id in ipairs(player:getCardIds("h")) do
        room:setCardMark(Fk:getCardById(id), "@@zhaowen-inhand-turn", 1)
      end
    end
  end,
})

zhaowen:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhaowen.name) and
      data.card.color == Card.Red and data.extra_data and data.extra_data.zhaowen_draw
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, zhaowen.name)
  end,
})

zhaowen:addEffect(fk.PreCardUse, {
  can_refresh = function (self, event, target, player, data)
    return target == player and data.card:getMark("@@zhaowen-inhand-turn") > 0
  end,
  on_refresh = function (self, event, target, player, data)
    data.extra_data = data.extra_data or {}
    data.extra_data.zhaowen_draw = true
  end,
})

return zhaowen
