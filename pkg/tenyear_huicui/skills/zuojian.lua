local zuojian = fk.CreateSkill {
  name = "zuojian",
}

Fk:loadTranslationTable{
  ["zuojian"] = "佐谏",
  [":zuojian"] = "出牌阶段结束时，若你此阶段使用的牌数不小于你的体力值，你可以选择一项：1.令装备区牌数大于你的角色摸一张牌；"..
  "2.弃置装备区牌数小于你的每名角色各一张手牌。",

  ["zuojian1"] = "装备数大于你的角色各摸一张牌",
  ["zuojian2"] = "弃置装备数小于你的角色各一张手牌",

  ["$zuojian1"] = "关羽者，刘备之枭将，宜除之。",
  ["$zuojian2"] = "主公虽非赵简子，然某可为周舍。",
}

zuojian:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(zuojian.name) and player.phase == Player.Play and
      #player.room.logic:getEventsOfScope(GameEvent.UseCard, 999, function(e)
        return e.data.from == player
      end, Player.HistoryPhase) >= player.hp then
      if table.find(player.room.alive_players, function(p)
        return #p:getCardIds("e") > #player:getCardIds("e")
      end) then
        return true
      else
        return table.find(player.room.alive_players, function(p)
          return #p:getCardIds("e") < #player:getCardIds("e") and not p:isKongcheng()
        end)
      end
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local choices = {}
    local targets1 = table.filter(player.room.alive_players, function(p)
      return #p:getCardIds("e") > #player:getCardIds("e")
    end)
    local targets2 = table.filter(player.room.alive_players, function(p)
      return #p:getCardIds("e") < #player:getCardIds("e") and not p:isKongcheng()
    end)
    if #targets1 > 0 then
      table.insert(choices, "zuojian1")
    end
    if #targets2 > 0 then
      table.insert(choices, "zuojian2")
    end
    table.insert(choices, "Cancel")
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = zuojian.name,
      all_choices = {"zuojian1", "zuojian2", "Cancel"},
    })
    if choice ~= "Cancel" then
      local tos = choice == "zuojian1" and targets1 or targets2
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos, choice = choice})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = event:getCostData(self).choice
    local tos = event:getCostData(self).tos
    if choice == "zuojian1" then
      for _, p in ipairs(tos) do
        if not p.dead then
          p:drawCards(1, zuojian.name)
        end
      end
    elseif choice == "zuojian2" then
      for _, p in ipairs(tos) do
        if player.dead then return end
        if not p.dead and not p:isKongcheng() then
          local id = room:askToChooseCard(player, {
            target = p,
            flag = "h",
            skill_name = zuojian.name,
          })
          room:throwCard(id, zuojian.name, p, player)
        end
      end
    end
  end,
})

return zuojian
