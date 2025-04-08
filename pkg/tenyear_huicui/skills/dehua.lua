local dehua = fk.CreateSkill {
  name = "dehua",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["dehua"] = "德化",
  [":dehua"] = "锁定技，每轮开始时，你视为使用一张伤害牌，然后你不能从手牌中使用此牌名的牌；你的手牌上限增加以此法使用过的牌名数。"..
  "若所有伤害牌均被选择过，你失去此技能，本局游戏伤害牌不计入你的手牌上限。",

  ["@$dehua"] = "德化",
  ["#dehua-use"] = "德化：视为使用一种伤害牌，然后你不能再使用同名手牌",

  ["$dehua1"] = "君子怀德，可驱怀土之小人。",
  ["$dehua2"] = "以德与人，福虽未至，祸已远离。",
}

local U = require "packages/utility/utility"

dehua:addEffect(fk.RoundStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(dehua.name) and
      table.find(player:getTableMark(dehua.name), function (id)
        return #Fk:getCardById(id):getDefaultTarget(player, {bypass_times = true}) > 0
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getTableMark(dehua.name), function (id)
      return #Fk:getCardById(id):getDefaultTarget(player, {bypass_times = true}) > 0
    end)
    local use = room:askToUseRealCard(player, {
      pattern = cards,
      skill_name = dehua.name,
      prompt = "#dehua-use",
      extra_data = {
        bypass_times = true,
        expand_pile = cards,
      },
      cancelable = false,
      skip = true,
    })
    if use == nil then return end
    local card = Fk:cloneCard(use.card.name)
    card.skillName = dehua.name
    room:useCard{
      card = card,
      from = player,
      tos = use.tos,
      extraUse = true,
    }
    if not player:hasSkill(dehua.name, true) then return end
    local name = use.card.trueName
    room:removeTableMark(player, "@$dehua", name)
    if player:getMark("@$dehua") == 0 then
      room:handleAddLoseSkills(player, "-dehua")
      room:setPlayerMark(player, "dehua_wake", 1)
    else
      cards = player:getTableMark(dehua.name)
      for i = #cards, 1, -1 do
        if Fk:getCardById(cards[i]).trueName == name then
          table.remove(cards, i)
        end
      end
      room:setPlayerMark(player, dehua.name, cards)
      room:addTableMark(player, "dehua_chosen", name)
    end
  end,
})

dehua:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  local names = {}
  local cards = table.filter(U.getUniversalCards(room, "bt"), function(id)
    local card = Fk:getCardById(id)
    if card.is_damage_card then
      table.insertIfNeed(names, card.trueName)
      return true
    end
  end)
  room:setPlayerMark(player, dehua.name, cards)
  room:setPlayerMark(player, "@$dehua", names)
end)

dehua:addLoseEffect(function (self, player, is_death)
  local room = player.room
  room:setPlayerMark(player, dehua.name, 0)
  room:setPlayerMark(player, "@$dehua", 0)
  room:setPlayerMark(player, "dehua_chosen", 0)
end)

dehua:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(dehua.name) then
      return #player:getTableMark("dehua_chosen")
    end
  end,
  exclude_from = function(self, player, card)
    return player:getMark("dehua_wake") > 0 and card.is_damage_card
  end,
})

dehua:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if card and player:hasSkill(dehua.name) and table.contains(player:getTableMark("dehua_chosen"), card.trueName) then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player:getCardIds("h"), id)
      end)
    end
  end,
})

return dehua
