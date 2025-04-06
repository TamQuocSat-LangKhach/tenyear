local huace = fk.CreateSkill {
  name = "huace",
}

Fk:loadTranslationTable{
  ["huace"] = "画策",
  [":huace"] = "出牌阶段限一次，你可以将一张手牌当上一轮没有角色使用过的普通锦囊牌使用。",

  ["#huace"] = "画策：将一张手牌当上一轮没被使用过的普通锦囊牌使用",

  ["$huace1"] = "筹画所料，无有不中。",
  ["$huace2"] = "献策破敌，所谋皆应。",
}

local U = require "packages/utility/utility"

huace:addEffect("viewas", {
  prompt = "#huace",
  interaction = function(self, player)
    local all_names = Fk:getAllCardNames("t")
    local names = player:getViewAsCardNames(huace.name, all_names, nil, player:getTableMark(huace.name))
    if #names == 0 then return end
    return U.CardNameBox { choices = names, all_choices = all_names }
  end,
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getHandlyIds(), to_select)
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcard(cards[1])
    card.skillName = huace.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(huace.name, Player.HistoryPhase) == 0
  end,
})

huace:addEffect(fk.RoundStart, {
  can_refresh = function(self, event, target, player, data)
    return player:hasSkill(huace.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    local round_events = room.logic:getEventsByRule(GameEvent.Round, 1, function (e)
      return e.id ~= room.logic:getCurrentEvent().id
    end, 0)
    if #round_events == 0 then return end
    local names = {}
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      if e.id < round_events[1].end_id and e.id > round_events[1].id then
        local use = e.data
        if use.card:isCommonTrick() then
          table.insertIfNeed(names, use.card.name)
        end
      end
    end, 0)
    room:setPlayerMark(player, huace.name, names)
  end,
})

huace:addAcquireEffect(function (self, player, is_start)
  if not is_start then
    local room = player.room
    local round_event = room.logic:getCurrentEvent():findParent(GameEvent.Round, true)
    local id = room.logic:getCurrentEvent().end_id
    if round_event then
      id = round_event.id
    end
    local round_events = room.logic:getEventsByRule(GameEvent.Round, 1, function (e)
      return e.id < id
    end, 0)
    if #round_events == 0 then return end
    local names = {}
    room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
      if e.id < round_events[1].end_id and e.id > round_events[1].id then
        local use = e.data
        if use.card:isCommonTrick() then
          table.insertIfNeed(names, use.card.name)
        end
      end
    end, 0)
    room:setPlayerMark(player, huace.name, names)
  end
end)

return huace
