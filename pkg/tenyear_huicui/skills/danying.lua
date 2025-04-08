local danying = fk.CreateSkill {
  name = "danying",
}

Fk:loadTranslationTable{
  ["danying"] = "胆迎",
  [":danying"] = "每回合限一次，你可以展示手牌中的『安』，视为使用或打出一张【杀】或【闪】。若如此做，本回合你下次成为牌的目标后，"..
  "使用者弃置你一张牌。",

  ["#danying"] = "胆迎：展示“安”，视为使用或打出【杀】或【闪】",

  ["$danying1"] = "早就想会会你常山赵子龙了。",
  ["$danying2"] = "赵子龙是吧？兜鍪给你打掉。",
}

local U = require "packages/utility/utility"

danying:addEffect("viewas", {
  pattern = "slash,jink",
  prompt = "#danying",
  interaction = function(self, player)
    local all_names = {"slash", "jink"}
    local names = player:getViewAsCardNames(danying.name, all_names)
    if #names > 0 then
      return U.CardNameBox {choices = names, all_choices = all_names}
    end
  end,
  view_as = function(self, player, cards)
    if self.interaction.data == nil then return end
    local card = Fk:cloneCard(self.interaction.data)
    card.skillName = danying.name
    return card
  end,
  before_use = function(self, player, use)
    local card = table.find(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@miyun_safe-inhand-round") > 0
    end)
    if card then
      player:showCards(card)
    end
  end,
  enabled_at_play = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@miyun_safe-inhand-round") > 0
      end)
  end,
  enabled_at_response = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryTurn) == 0 and
      table.find(player:getCardIds("h"), function (id)
        return Fk:getCardById(id):getMark("@@miyun_safe-inhand-round") > 0
      end)
  end,
})

danying:addEffect(fk.TargetConfirmed, {
  anim_type = "negative",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedEffectTimes(danying.name, Player.HistoryTurn) > 0 and
      player:usedEffectTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if not data.from.dead and not player.dead and not player:isNude() then
      if data.from == player then
        room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = danying.name,
          cancelable = false,
        })
      else
        local card = room:askToChooseCard(data.from, {
          target = player,
          flag = "he",
          skill_name = danying.name,
        })
        room:throwCard(card, danying.name, player, data.from)
      end
    end
  end,
})

return danying
