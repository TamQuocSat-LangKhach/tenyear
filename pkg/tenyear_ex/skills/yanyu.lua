local yanyu = fk.CreateSkill{
  name = "ty_ex__yanyu",
}

Fk:loadTranslationTable{
  ["ty_ex__yanyu"] = "燕语",
  [":ty_ex__yanyu"] = "出牌阶段，你可以重铸【杀】；出牌阶段结束时，你可以令一名男性角色摸X张牌（X为你此阶段因此重铸的【杀】数，至多为3）。",

  ["#ty_ex__yanyu"] = "燕语：你可以重铸【杀】",
  ["#ty_ex__yanyu-draw"] = "燕语：你可以令一名男性角色摸%arg张牌",

  ["$ty_ex__yanyu1"] = "边功未成，还请郎君努力。",
  ["$ty_ex__yanyu2"] = "郎君有意倾心诉，妾身心中相思埋。",
}

yanyu:addEffect("active", {
  anim_type = "drawcard",
  prompt = "#ty_ex__yanyu",
  card_num = 1,
  target_num = 0,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).trueName == "slash"
  end,
  on_use = function(self, room, effect)
    room:recastCard(effect.cards, effect.from, yanyu.name)
  end,
})

yanyu:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == player.Play and
      player:usedEffectTimes(yanyu.name, Player.HistoryPhase) > 0 and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:isMale()
      end)
    end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return p:isMale()
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = yanyu.name,
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__yanyu-draw:::"..math.min(3, player:usedEffectTimes(yanyu.name, Player.HistoryPhase)),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = math.min(3, player:usedEffectTimes(yanyu.name, Player.HistoryPhase))
    event:getCostData(self).tos[1]:drawCards(n, yanyu.name)
  end,
})

return yanyu
