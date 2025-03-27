local gongjian = fk.CreateSkill {
  name = "gongjian",
}

Fk:loadTranslationTable{
  ["gongjian"] = "攻坚",
  [":gongjian"] = "每回合限一次，当一名角色使用【杀】指定目标后，若此【杀】与上一张【杀】有相同的目标，则你可以弃置其中相同目标角色"..
  "各至多两张牌，你获得其中的【杀】。",

  ["#gongjian-invoke"] = "攻坚：你可以弃置重复的目标角色各至多两张牌，并获得其中的【杀】",

  ["$gongjian1"] = "善攻者，敌不知其所守。",
  ["$gongjian2"] = "围解自出，势必意散。",
}

gongjian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(gongjian.name) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(gongjian.name, Player.HistoryTurn) == 0 then
      local use_event = player.room.logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local targets = {}
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < use_event.id and e.data.card.trueName == "slash" then
          targets = e.data.tos
          return true
        end
      end, 0)
      if #targets == 0 then return end
      targets = table.filter(targets, function (p)
        return table.contains(data.use.tos, p) and not p:isNude() and not p.dead
      end)
      if #targets > 0 then
        event:setCostData(self, {tos = targets})
        return true
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(event:getCostData(self).tos)
    if room:askToSkillInvoke(player, {
      skill_name = gongjian.name,
      prompt = "#gongjian-invoke",
    }) then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(event:getCostData(self).tos)
    for _, to in ipairs(tos) do
      if player.dead then return end
      if not (to.dead or to:isNude()) then
        local cards = {}
        if to == player then
          cards = room:askToDiscard(player, {
            min_num = 1,
            max_num = 2,
            include_equip = true,
            skill_name = gongjian.name,
            cancelable = false,
          })
        else
          cards = room:askToChooseCards(player, {
            target = to,
            min = 1,
            max = 2,
            flag = "he",
            skill_name = gongjian.name,
          })
        end
        room:throwCard(cards, gongjian.name, to, player)
        if player.dead then break end
        cards = table.filter(cards, function (id)
          return table.contains(room.discard_pile, id) and Fk:getCardById(id).trueName == "slash"
        end)
        if #cards > 0 then
          room:obtainCard(player, cards, true, fk.ReasonJustMove, player, gongjian.name)
        end
      end
    end
  end,
})

return gongjian
