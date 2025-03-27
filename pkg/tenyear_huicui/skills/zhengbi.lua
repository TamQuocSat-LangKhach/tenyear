local zhengbi = fk.CreateSkill {
  name = "ty__zhengbi",
}

Fk:loadTranslationTable{
  ["ty__zhengbi"] = "征辟",
  [":ty__zhengbi"] = "出牌阶段开始时，你可以选择一名其他角色并选择一项：1.此阶段结束时，若其此阶段获得过手牌，你获得其一张手牌和装备区内一张牌；"..
  "2.交给其一张基本牌，然后其交给你一张非基本牌或两张基本牌。",

  ["#ty__zhengbi-choose"] = "征辟：选择一名角色<br>直接点“确定”，若其此阶段获得手牌，此阶段结束时你获得其牌；<br>"..
  "选一张基本牌点“确定”，将此牌交给其，然后其交给你一张非基本牌或两张基本牌。",
  ["#ty__zhengbi-give1"] = "征辟：请交给 %src 两张基本牌",
  ["#ty__zhengbi-give2"] = "征辟：请交给 %src 一张非基本牌",


  ["$ty__zhengbi1"] = "跅弛之士，在御之而已。",
  ["$ty__zhengbi2"] = "内不避亲，外不避仇。",
}

local U = require "packages/utility/utility"

zhengbi:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhengbi.name) and player.phase == Player.Play and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ex__choose_skill",
      prompt = "#ty__zhengbi-choose",
      cancelable = true,
      extra_data = {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_c_num = 0,
        max_c_num = 1,
        min_t_num = 1,
        max_t_num = 1,
        pattern = ".|.|.|.|.|basic",
      },
    })
    if success and dat then
      if #dat.cards > 0 then
        event:setCostData(self, {tos = dat.targets, cards = dat.cards})
      else
        event:setCostData(self, {tos = dat.targets})
      end
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if event:getCostData(self).cards then
      room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, zhengbi.name, nil, true, player)
      if player.dead or to.dead or to:isNude() then return end
      local cards = to:getCardIds("he")
      if #cards > 1 then
        local choices = {}
        local num = #table.filter(to:getCardIds(Player.Hand), function(id)
          return Fk:getCardById(id).type == Card.TypeBasic end)
        if num > 1 then
          table.insert(choices, "zhengbi__basic-back:"..player.id)
        end
        if #to:getCardIds("he") - num > 0 then
          table.insert(choices, "zhengbi__nobasic-back:"..player.id)
        end
        if #choices == 0 then return end
        local choice = room:askToChoice(to, {
          choices = choices,
          skill_name = zhengbi.name
        })
        if choice:startsWith("zhengbi__basic-back") then
          cards = room:askToCards(to, {
            min_num = 2,
            max_num = 2,
            include_equip = false,
            pattern = ".|.|.|.|.|basic",
            prompt = "#ty__zhengbi-give1:"..player.id,
            skill_name = zhengbi.name,
            cancelable = false,
          })
        else
          cards = room:askToCards(to, {
            min_num = 1,
            max_num = 1,
            include_equip = true,
            pattern = ".|.|.|.|.|^basic",
            prompt = "#ty__zhengbi-give2:"..player.id,
            skill_name = zhengbi.name,
            cancelable = false,
          })
        end
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, zhengbi.name, nil, true, to.id)
    else
      room:setPlayerMark(player, "ty__zhengbi-phase", to.id)
    end
  end,
})

zhengbi:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and player.phase == Player.Play and player:getMark("ty__zhengbi-phase") ~= 0 then
      local room = player.room
      local p = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
      if p.dead or p:isNude() then return end
      return #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
        for _, move in ipairs(e.data) do
          return move.to == p and move.toArea == Card.PlayerHand
        end
      end, Player.HistoryPhase) > 0
    end
  end,
  on_cost = function (self, event, target, player, data)
    event:setCostData(self, {tos = {player.room:getPlayerById(player:getMark("ty__zhengbi-phase"))}})
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(player:getMark("ty__zhengbi-phase"))
    local cards = U.askforCardsChosenFromAreas(player, to, "he", zhengbi.name, nil, nil, false)
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonPrey, zhengbi.name, nil, false, player)
  end,
})

return zhengbi
