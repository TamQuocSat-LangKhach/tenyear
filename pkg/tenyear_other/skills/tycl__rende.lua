local rende = fk.CreateSkill {
  name = "tycl__rende",
}

Fk:loadTranslationTable{
  ["tycl__rende"] = "章武",
  [":tycl__rende"] = "出牌阶段每名其他角色限一次，你可以获得一名其他角色两张手牌，然后视为使用一张基本牌。",

  ["#tycl__rende"] = "章武：获得一名其他角色两张手牌，然后视为使用一张基本牌",
  ["#tycl__rende-ask"] = "章武：你可以视为使用一张基本牌",

  ["$tycl__rende1"] = "惟贤惟德能服于人。",
  ["$tycl__rende2"] = "以德服人。",
}

local U = require "packages/utility/utility"

rende:addEffect("active", {
  anim_type = "offensive",
  prompt = "#tycl__rende",
  card_num = 0,
  target_num = 1,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player and
      not table.contains(player:getTableMark("tycl__rende-phase"), to_select.id) and
      to_select:getHandcardNum() > 1
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:addTableMark(player, "tycl__rende-phase", target.id)
    local cards = room:askToChooseCards(player, {
      target = target,
      min = 2,
      max = 2,
      flag = "h",
      skill_name = rende.name,
    })
    room:obtainCard(player, cards, false, fk.ReasonPrey, player, rende.name)
    if player.dead then return end
    cards = U.getUniversalCards(room, "b")
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = rende.name,
      prompt = "#tycl__rende-ask",
      extra_data = {
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
      },
      cancelable = true,
      skip = true,
    })
    if use then
      local card = Fk:cloneCard(use.card.name)
      card.skillName = rende.name
      room:useCard{
        from = player,
        tos = use.tos,
        card = card,
        extraUse = true,
      }
    end
  end,
})

return rende
