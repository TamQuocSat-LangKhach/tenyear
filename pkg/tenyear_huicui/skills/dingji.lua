local dingji = fk.CreateSkill {
  name = "dingji",
}

Fk:loadTranslationTable{
  ["dingji"] = "定基",
  [":dingji"] = "准备阶段，你可以令一名角色将手牌数调整至五，然后其展示所有手牌，若牌名均不同，其可以视为使用其中一张基本牌或普通锦囊牌。",

  ["#dingji-choose"] = "定基：你可以令一名角色将手牌数调整至五",
  ["#dingji-discard"] = "定基：请弃置%arg张手牌，若剩余牌牌名均不同，你可以视为使用其中一张",
  ["#dingji-use"] = "定基：你可以视为使用手牌中一张基本牌或普通锦囊牌",

  ["$dingji1"] = "丞相宜进爵国公，以彰殊勋。",
  ["$dingji2"] = "今公与诸将并侯，岂天下所望哉！"
}

dingji:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dingji.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 1,
      prompt = "#dingji-choose",
      skill_name = dingji.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local n = to:getHandcardNum() - 5
    if n < 0 then
      to:drawCards(-n, dingji.name)
    elseif n > 0 then
      room:askToDiscard(to, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = dingji.name,
        cancelable = false,
        prompt = "#dingji-discard:::"..n,
      })
    end
    if to.dead then return end
    to:showCards(to:getCardIds("h"))
    if to.dead or to:isKongcheng() then return end
    if table.every(to:getCardIds("h"), function(id)
      return not table.find(to:getCardIds("h"), function(id2)
        return id ~= id2 and Fk:getCardById(id).trueName == Fk:getCardById(id2).trueName
      end)
    end) then
      local names = {}
      for _, id in ipairs(to:getCardIds("h")) do
        local c = Fk:getCardById(id)
        if c.type == Card.TypeBasic or c:isCommonTrick() then
          table.insertIfNeed(names, c.name)
        end
      end
      local cards = table.filter(room:getBanner(dingji.name), function (id)
        return table.contains(names, Fk:getCardById(id).name)
      end)
      local use = room:askToUseRealCard(to, {
        pattern = cards,
        skill_name = dingji.name,
        prompt = "#dingji-use",
        extra_data = {
          bypass_times = true,
          expand_pile = cards,
        },
        skip = true,
      })
      if use then
        local card = Fk:cloneCard(use.card.name)
        card.skillName = dingji.name
        room:useCard{
          card = card,
          from = to,
          tos = use.tos,
          extraUse = true,
        }
      end
    end
  end,
})

dingji:addAcquireEffect(function (self, player, is_start)
  local room = player.room
  if room:getBanner(dingji.name) == nil then
    local ids = {}
    for _, name in ipairs(Fk:getAllCardNames("bt", false, true)) do
      table.insert(ids, room:printCard(name).id)
    end
    room:setBanner(dingji.name, ids)
  end
end)

return dingji
