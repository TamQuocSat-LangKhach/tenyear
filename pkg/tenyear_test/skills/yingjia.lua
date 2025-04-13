local yingjia = fk.CreateSkill {
  name = "ty__yingjia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__yingjia"] = "迎驾",
  [":ty__yingjia"] = "锁定技，你对距离不为1的其他角色使用牌后，本回合你计算与其距离视为1，然后若你与所有其他角色距离均为1，你可以获得"..
  "一名其他角色所有手牌，然后交给其等量的牌。",

  ["#ty__yingjia-choose"] = "迎驾：你可以获得一名角色所有手牌，交给其等量的牌",
  ["#ty__yingjia-give"] = "迎驾：交给 %dest %arg张牌",
}

yingjia:addEffect(fk.CardUseFinished, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yingjia.name) and
      table.find(data.tos, function (p)
        return p ~= player and not table.contains(player:getTableMark("ty__yingjia-turn"), p.id) and not p.dead and
          player:distanceTo(p) ~= 1
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(data.tos) do
      if p ~= player and not p.dead then
        room:addTableMark(player, "ty__yingjia-turn", p.id)
      end
    end
    if table.every(room:getOtherPlayers(player, false), function (p)
      return player:distanceTo(p) == 1
    end) then
      local targets = table.filter(room:getOtherPlayers(player, false), function (p)
        return not p:isKongcheng()
      end)
      if #targets > 0 then
        local to = room:askToChoosePlayers(player, {
          min_num = 1,
          max_num = 1,
          targets = targets,
          skill_name = yingjia.name,
          prompt = "#ty__yingjia-choose",
          cancelable = true,
        })
        if #to > 0 then
          to = to[1]
          local n = to:getHandcardNum()
          room:moveCardTo(to:getCardIds("h"), Card.PlayerHand, player, fk.ReasonPrey, yingjia.name, nil, false, player)
          if player.dead or to.dead or player:isNude() then return end
          local cards = player:getCardIds("he")
          if #cards > n then
            cards = room:askToCards(player, {
              min_num = n,
              max_num = n,
              include_equip = true,
              skill_name = yingjia.name,
              prompt = "#ty__yingjia-give::"..to.id..":"..n,
              cancelable = false,
            })
          end
          room:moveCardTo(cards, Card.PlayerHand, to, fk.ReasonGive, yingjia.name, nil, false, player)
        end
      end
    end
  end,
})

yingjia:addEffect("distance", {
  fixed_func = function(self, from, to)
    if table.contains(from:getTableMark("ty__yingjia-turn"), to.id) then
      return 1
    end
  end,
})

return yingjia
