local ty__diaodu = fk.CreateSkill {
  name = "ty__diaodu"
}

Fk:loadTranslationTable{
  ['ty__diaodu'] = '调度',
  ['#ty__diaodu-choose'] = '调度：获得一名角色装备区一张牌，然后交给除其以外的角色，该角色可以使用之',
  ['#ty__diaodu-give'] = '调度：将%arg交给一名角色，其可以使用之',
  ['#ty__diaodu-use'] = '调度：使用%arg令 %src 摸一张牌；或不使用，你摸一张牌',
  [':ty__diaodu'] = '出牌阶段开始时，你可以获得距离1以内一名角色装备区内的一张牌，然后将此牌交给除其以外一名角色，该角色选择一项：1.使用此牌，然后你摸一张牌；2.不使用此牌，其摸一张牌。',
  ['$ty__diaodu1'] = '开源节流，作法于凉。',
  ['$ty__diaodu2'] = '调度征求，省行薄敛。',
}

ty__diaodu:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(ty__diaodu.name) and player.phase == Player.Play and
      table.find(player.room.alive_players, function(p)
        return player:distanceTo(p) <= 1 and #p:getCardIds("e") > 0
      end)
  end,
  on_cost = function(self, event, target, player)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return player:distanceTo(p) <= 1 and #p:getCardIds("e") > 0
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__diaodu-choose",
      skill_name = ty__diaodu.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    local id = room:askToChooseCard(player, {
      target = to,
      flag = "e",
      skill_name = ty__diaodu.name,
    })
    room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonPrey, ty__diaodu.name, nil, true, player.id)
    if player.dead or not table.contains(player:getCardIds("h"), id) then return end
    local targets = table.map(table.filter(room.alive_players, function(p)
      return p ~= to
    end), Util.IdMapper)
    local p = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__diaodu-give:::"..Fk:getCardById(id):toLogString(),
      skill_name = ty__diaodu.name,
      cancelable = to ~= player
    })
    if #p > 0 then
      p = room:getPlayerById(p[1])
      room:moveCardTo(id, Card.PlayerHand, p, fk.ReasonGive, ty__diaodu.name, nil, true, player.id)
      local card = Fk:getCardById(id)
      if p.dead or not table.contains(p:getCardIds("h"), id) or p:isProhibited(p, card) then return end
      if room:askToSkillInvoke(p, {
        skill_name = ty__diaodu.name,
        prompt = "#ty__diaodu-use:"..player.id.."::"..card:toLogString()
      }) then
        room:useCard({
          from = p.id,
          tos = {{p.id}},
          card = card,
        })
        if not player.dead then
          player:drawCards(1, ty__diaodu.name)
        end
      else
        p:drawCards(1, ty__diaodu.name)
      end
    end
  end,
})

return ty__diaodu
