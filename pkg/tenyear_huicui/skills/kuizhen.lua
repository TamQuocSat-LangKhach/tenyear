local kuizhen = fk.CreateSkill {
  name = "kuizhen",
}

Fk:loadTranslationTable{
  ["kuizhen"] = "溃阵",
  [":kuizhen"] = "出牌阶段限一次，你可以选择一名手牌数或体力值不小于你的角色，其视为对你使用【决斗】，若你：受到此【决斗】造成的伤害，"..
  "你观看其所有手牌，获得其中所有的【杀】且你使用以此法获得的【杀】无次数限制；未受到过此【决斗】造成的伤害，其失去1点体力。",

  ["#kuizhen"] = "溃阵：选择一名角色，视为其对你使用【决斗】",
  ["@@kuizhen-inhand"] = "溃阵",

  ["$kuizhen1"] = "今一马当先，效霸王破釜！",
  ["$kuizhen2"] = "自古北马皆傲，视南风为鱼俎。",
}

local U = require "packages/utility/utility"

kuizhen:addEffect("active", {
  anim_type = "offensive",
  prompt = "#kuizhen",
  can_use = function(self, player)
    return player:usedSkillTimes(kuizhen.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      (to_select.hp >= player.hp or to_select:getHandcardNum() >= player:getHandcardNum()) and
      to_select:canUseTo(Fk:cloneCard("duel"), player)
  end,
  target_num = 1,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local use = room:useVirtualCard("duel", nil, target, player, kuizhen.name, true)
    if not use or target.dead then return end
    if use.damageDealt and use.damageDealt[player] then
      if player.dead or target:isKongcheng() then return end
      local cards = target:getCardIds("h")
      U.viewCards(player, cards, kuizhen.name)
      cards = table.filter(cards, function (id)
        return Fk:getCardById(id).trueName == "slash"
      end)
      if #cards == 0 then return end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, kuizhen.name, nil, false, player, "@@kuizhen-inhand")
    else
      room:loseHp(target, 1, kuizhen.name)
    end
  end,
})

kuizhen:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and data.card:getMark("@@kuizhen-inhand") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

kuizhen:addEffect("targetmod", {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and card.trueName == "slash" and card:getMark("@@kuizhen-inhand") > 0
  end,
})

return kuizhen
