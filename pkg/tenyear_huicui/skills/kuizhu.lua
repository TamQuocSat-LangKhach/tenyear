local kuizhul = fk.CreateSkill {
  name = "kuizhul",
}

Fk:loadTranslationTable{
  ["kuizhul"] = "馈珠",
  [":kuizhul"] = "出牌阶段结束时，你可以选择体力值全场最大的一名其他角色，将手牌摸至与该角色相同（最多摸至五张），然后该角色观看你的手牌，"..
  "弃置任意张手牌并从观看的牌中获得等量的牌，若其获得的牌数大于1，则你选择一项：1.移去一个“珠”；2.令其对其攻击范围内的一名角色造成1点伤害。",

  ["#kuizhul-choose"] = "馈珠：你可以将手牌补至与一名角色相同，其可以获得你的手牌",
  ["#kuizhul-exchange"] = "馈珠：你可以弃置任意张手牌，获得对方等量的手牌",
  ["#kuizhul-damage"] = "馈珠：选择一名角色令 %dest 对其造成伤害，或点“取消”移去一个“珠”",

  ["$kuizhul1"] = "与君同谋，赠君金珠。",
  ["$kuizhul2"] = "金珠熠熠，都归将军了。",
}

Fk:addPoxiMethod{
  name = "kuizhul",
  prompt = "#kuizhul-exchange",
  card_filter = function(to_select, selected, data)
    return not (table.contains(data[2][2], to_select) and Self:prohibitDiscard(to_select))
  end,
  feasible = function(selected, data)
    local count = 0
    for _, id in ipairs(selected) do
      if table.contains(data[1][2], id) then
        count = count - 1
      else
        count = count + 1
      end
    end
    return count == 0
  end,
}

kuizhul:addEffect(fk.EventPhaseEnd, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(kuizhul.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return table.every(player.room:getOtherPlayers(player, false), function(p2)
            return p.hp >= p2.hp
          end) and
          not p:isKongcheng()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return table.every(room:getOtherPlayers(player, false), function(p2)
          return p.hp >= p2.hp
        end) and
        not p:isKongcheng()
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = kuizhul.name,
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#kuizhul-choose",
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
    if math.min(to:getHandcardNum(), 5) > player:getHandcardNum() then
      player:drawCards(math.min(to:getHandcardNum(), 5) - player:getHandcardNum(), player.id)
    end
    if player.dead or to.dead or player:isKongcheng() or to:isKongcheng() then return end
    local results = room:askToPoxi(to, {
      poxi_type = kuizhul.name,
      data = {
        { player.general, player:getCardIds("h") },
        { to.general, to:getCardIds("h") },
      },
      cancelable = true,
    })
    if #results == 0 then return end
    local moves = {}
    local to_throw = table.filter(results, function(id)
      return table.contains(to:getCardIds("h"), id)
    end)
    local to_get = table.filter(results, function(id)
      return table.contains(player:getCardIds("h"), id)
    end)
    table.insert(moves, {
      ids = to_throw,
      from = to,
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonDiscard,
      proposer = to,
      skillName = kuizhul.name,
    })
    table.insert(moves, {
      ids = to_get,
      from = player,
      to = to,
      toArea = Card.PlayerHand,
      moveReason = fk.ReasonPrey,
      proposer = to,
      skillName = kuizhul.name,
    })
    room:moveCards(table.unpack(moves))
    if player.dead or #to_get < 2 then return end
    local targets = table.filter(room.alive_players, function(p)
      return to:inMyAttackRange(p)
    end)
    if #targets > 0 then
      targets = room:askToChoosePlayers(player, {
        skill_name = kuizhul.name,
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#kuizhul-damage::"..to.id,
        cancelable = true,
        no_indicate = true,
      })
      if #targets > 0 then
        room:doIndicate(to, targets)
        room:damage{
          from = to,
          to = targets[1],
          damage = 1,
          skillName = kuizhul.name,
        }
        return
      end
    end
    room:removePlayerMark(player, "@lisu_zhu", 1)
  end,
})

return kuizhul
