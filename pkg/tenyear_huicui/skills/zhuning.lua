local zhuning = fk.CreateSkill {
  name = "zhuning",
}

Fk:loadTranslationTable{
  ["zhuning"] = "诛佞",
  [":zhuning"] = "出牌阶段限一次，你可以交给一名其他角色任意张牌，这些牌标记为“隙”，然后你可以视为使用一张不计次数的【杀】或伤害类锦囊牌，"..
  "然后若此牌没有造成伤害，此技能本阶段改为“出牌阶段限两次”。",

  ["#zhuning"] = "诛佞：交给一名角色任意张牌（标记为“隙”），然后视为使用一张伤害牌",
  ["@@zhuning-inhand"] = "隙",
  ["#zhuning-use"] = "诛佞：你可以视为使用一张不计次数的伤害牌",

  ["$zhuning1"] = "此剑半丈，当斩奸佞人头！",
  ["$zhuning2"] = "此身八尺，甘为柱国之石。",
}

local U = require "packages/utility/utility"

zhuning:addEffect("active", {
  anim_type = "support",
  prompt = "#zhuning",
  min_card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(zhuning.name, Player.HistoryPhase) < 1 + player:getMark("zhuning-phase")
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:moveCardTo(effect.cards, Card.PlayerHand, target, fk.ReasonGive, zhuning.name, nil, false, player, "@@zhuning-inhand")
    if player.dead then return end
    local cards = table.filter(U.getUniversalCards(room, "bt"), function (id)
      return Fk:getCardById(id).is_damage_card
    end)
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = zhuning.name,
      prompt = "#zhuning-use",
      extra_data = {
        bypass_times = true,
        expand_pile = cards,
      },
      skip = true,
    })
    if use then
      local card = Fk:cloneCard(use.card.name)
      card.skillName = zhuning.name
      use = {
        card = card,
        from = player,
        tos = use.tos,
        extraUse = true,
      }
      room:useCard(use)
      if not player.dead and not use.damageDealt then
        room:setPlayerMark(player, "zhuning-phase", 1)
      end
    end
  end,
})

return zhuning
