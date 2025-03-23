local gongjian = fk.CreateSkill {
  name = "gongjian"
}

Fk:loadTranslationTable{
  ['gongjian'] = '攻坚',
  [':gongjian'] = '每回合限一次，当一名角色使用【杀】指定目标后，若此【杀】与上一张【杀】有相同的目标，则你可以弃置其中相同目标角色各至多两张牌，你获得其中的【杀】。',
  ['$gongjian1'] = '善攻者，敌不知其所守。',
  ['$gongjian2'] = '围解自出，势必意散。',
}

gongjian:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(gongjian.name) and data.card.trueName == "slash" and data.firstTarget and
      player:usedSkillTimes(gongjian.name, Player.HistoryTurn) == 0 then
      local logic = player.room.logic
      local use_event = logic:getCurrentEvent():findParent(GameEvent.UseCard, true)
      if use_event == nil then return false end
      local events = logic.event_recorder[GameEvent.UseCard] or Util.DummyTable
      local last_find = false
      local use, e
      for i = #events, 1, -1 do
        e = events[i]
        if e.id == use_event.id then
          last_find = true
        elseif last_find then
          use = e.data[1]
          if use.card.trueName == "slash" then
            local tos1 = AimGroup:getAllTargets(data.tos)
            local tos2 = TargetGroup:getRealTargets(use.tos)
            local tos = {}
            local can_invoked = false
            for _, p in ipairs(player.room.alive_players) do
              if table.contains(tos1, p.id) and table.contains(tos2, p.id) then
                table.insert(tos, p.id)
                if not p:isNude() then
                  can_invoked = true
                end
              end
            end
            if can_invoked then
              event:setCostData(self, tos)
              return true
            end
            return false
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.simpleClone(event:getCostData(self))
    room:sortPlayersByAction(tos)
    room:doIndicate(player.id, tos)
    for _, pid in ipairs(tos) do
      local to = room:getPlayerById(pid)
      if not (to.dead or to:isNude()) then
        local cards = room:askToChooseCards(player, {
          target = to,
          min = 1,
          max = 2,
          flag = "he",
          skill_name = gongjian.name
        })
        room:throwCard(cards, gongjian.name, to, player)
        if player.dead then break end
        cards = table.filter(cards, function (id)
          return room:getCardArea(id) == Card.DiscardPile and Fk:getCardById(id, true).trueName == "slash"
        end)
        if #cards > 0 then
          room:obtainCard(player, cards, false, fk.ReasonPrey)
          if player.dead then break end
        end
      end
    end
  end,
})

return gongjian
