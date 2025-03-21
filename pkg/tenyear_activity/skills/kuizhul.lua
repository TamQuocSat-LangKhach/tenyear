local kuizhul = fk.CreateSkill {
  name = "kuizhul"
}

Fk:loadTranslationTable{
  ['kuizhul'] = '馈珠',
  ['#kuizhul-choose'] = '馈珠：你可以将手牌补至与一名角色相同，其可以获得你的手牌',
  ['#kuizhul-exchange'] = '馈珠：你可以弃置任意张手牌，获得%src等量的手牌',
  ['#kuizhul-damage'] = '馈珠：选择一名角色令 %dest 对其造成伤害，或点“取消”移去一个“珠”',
  ['@lisu_zhu'] = '珠',
  [':kuizhul'] = '出牌阶段结束时，你可以选择体力值全场最大的一名其他角色，将手牌摸至与该角色相同（最多摸至五张），然后该角色观看你的手牌，弃置任意张手牌并从观看的牌中获得等量的牌，若其获得的牌数大于1，则你选择一项：1.移去一个“珠”；2.令其对其攻击范围内的一名角色造成1点伤害。',
  ['$kuizhul1'] = '与君同谋，赠君金珠。',
  ['$kuizhul2'] = '金珠熠熠，都归将军了。',
}

kuizhul:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(skill.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player), function(p)
        return not p:isKongcheng() and table.every(player.room:getOtherPlayers(player), function(p2)
          return p.hp >= p2.hp
        end)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() and table.every(room:getOtherPlayers(player), function(p2)
        return p.hp >= p2.hp
      end)
    end), Util.IdMapper)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = "#kuizhul-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(skill, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(skill))
    if math.min(to:getHandcardNum(), 5) > player:getHandcardNum() then
      player:drawCards(math.min(to:getHandcardNum(), 5) - player:getHandcardNum(), player.id)
    end
    if player.dead or to.dead or player:isKongcheng() or to:isKongcheng() then return end
    local cards = table.filter(to:getCardIds("h"), function(id) return not to:prohibitDiscard(Fk:getCardById(id)) end)
    if #cards == 0 then
      U.viewCards(to, player:getCardIds("h"), skill.name)
      return
    end
    local results = U.askForExchange(to, {
      piles = {player:getCardIds("h"), cards},
      piles_name = {player.general, to.general},
      skill_name = "#kuizhul-exchange:"..player.id,
    })
    if #results == 0 then return end
    local to_throw = table.filter(results, function(id) return table.contains(to:getCardIds("h"), id) end)
    room:throwCard(to_throw, skill.name, to, to)
    if to.dead or player.dead then return end
    local to_get = table.filter(results, function(id) return table.contains(player:getCardIds("h"), id) end)
    if #to_get == 0 then return end
    room:moveCardTo(to_get, Card.PlayerHand, to, fk.ReasonPrey, skill.name, nil, false, to.id)
    if player.dead or #to_get < 2 then return end
    local targets = table.map(table.filter(room.alive_players, function(p) return to:inMyAttackRange(p) end), Util.IdMapper)
    if #targets > 0 then
      targets = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        skill_name = "#kuizhul-damage::"..to.id,
        cancelable = true,
        no_indicate = true,
      })
      if #targets > 0 then
        room:doIndicate(to.id, targets)
        room:damage{
          from = to,
          to = room:getPlayerById(targets[1]),
          damage = 1,
          skillName = skill.name,
        }
        return
      end
    end
    room:removePlayerMark(player, "@lisu_zhu", 1)
  end,
})

return kuizhul
