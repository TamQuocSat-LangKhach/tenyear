local shilie = fk.CreateSkill {
  name = "shilie",
}

Fk:loadTranslationTable{
  ["shilie"] = "示烈",
  [":shilie"] = "出牌阶段限一次，你可以选择一项：1.回复1点体力，然后将两张牌置为“示烈”牌（不足则全放，总数不能大于游戏人数）；"..
  "2.失去1点体力，然后获得两张“示烈”牌。<br>你死亡时，你可以将“示烈”牌交给除伤害来源外的一名其他角色。",

  ["$shilie"] = "示烈",
  ["#shilie-recover"] = "示烈：回复1点体力，将两张牌置为“示烈”牌",
  ["#shilie-loseHp"] = "示烈：失去1点体力，获得两张“示烈”牌",
  ["#shilie-put"] = "示烈：将两张牌置为“示烈”牌",
  ["#shilie-get"] = "示烈：获得两张“示烈”牌",
  ["#shilie-choose"] = "示烈：你可以将所有“示烈”牌交给一名角色",

  ["$shilie1"] = "荆州七郡，亦有怀义之人！",
  ["$shilie2"] = "食禄半生，安能弃旧主而去！",
}

shilie:addEffect("active", {
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  derived_piles = "$shilie",
  prompt = function (self)
    return "#shilie-"..self.interaction.data
  end,
  interaction = function(self)
    return UI.ComboBox { choices = {"recover", "loseHp"} }
  end,
  can_use = function(self, player)
    return player:usedEffectTimes(shilie.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    if self.interaction.data == "recover" then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = shilie.name,
        }
        if player.dead then return end
      end
      if not player:isNude() then
        local cards = player:getCardIds("he")
        if #cards > 2 then
          cards = room:askToCards(player, {
            min_num = 2,
            max_num = 2,
            prompt = "#shilie-put",
            skill_name = shilie.name,
            cancelable = false,
          })
        end
        player:addToPile("$shilie", cards, false, shilie.name)
        if player.dead then return end
        local n = #player:getPile("$shilie") - #room.players
        if n > 0 then
          local to_remove = table.slice(player:getPile("$shilie"), 1, n + 1)
          room:moveCardTo(to_remove, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, shilie.name, nil, true, player)
        end
      end
    else
      room:loseHp(player, 1, shilie.name)
      if player.dead then return end
      local cards = player:getPile("$shilie")
      if #cards > 2 then
        cards = room:askToCards(player, {
          min_num = 2,
          max_num = 2,
          pattern = ".|.|.|$shilie",
          prompt = "#shilie-get",
          skill_name = shilie.name,
          expand_pile = "$shilie",
        })
      end
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonJustMove, shilie.name, nil, false, player)
    end
  end,
})

shilie:addEffect(fk.Death, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(shilie.name, false, true) and #player:getPile("$shilie") > 0 and
      table.find(player.room.alive_players, function (p)
        return p ~= data.killer
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = room.alive_players
    table.removeOne(targets, data.killer)
    local to = room:askToChoosePlayers(player, {
      skill_name = shilie.name,
      min_num = 1,
      max_num = 1,
      prompt = "#shilie-choose",
      targets = targets,
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
    room:moveCardTo(player:getPile("$shilie"), Card.PlayerHand, to, fk.ReasonJustMove, shilie.name, nil, false, player)
  end,
})

return shilie
