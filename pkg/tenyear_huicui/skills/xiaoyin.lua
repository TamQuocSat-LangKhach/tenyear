local xiaoyin = fk.CreateSkill {
  name = "xiaoyin",
}

Fk:loadTranslationTable{
  ["xiaoyin"] = "硝引",
  [":xiaoyin"] = "准备阶段，你可以亮出牌堆顶X张牌（X为你距离1以内的角色数），获得其中红色牌，将其中任意张黑色牌作为“硝引”放置在等量名"..
  "座次连续（不计入你的座位）的其他角色的武将牌上。<br>有“硝引”牌的角色受到伤害时：若为火焰伤害，伤害来源可以弃置一张与“硝引”同类别的牌并"..
  "随机移去一张此类别的“硝引”牌令此伤害+1；不为火焰伤害，伤害来源可以获得其一张“硝引”牌并将此伤害改为火焰伤害。",

  ["#xiaoyin-give"] = "硝引：将黑色牌作为“硝引”放置在连续的其他角色武将牌上",
  ["#xiaoyin-damage"] = "硝引：你可以弃置一张与 %dest “硝引”同类别的牌，令其受到伤害+1",
  ["#xiaoyin-fire"] = "硝引：你可以获得 %dest 的一张“硝引”，令此伤害改为火焰伤害",

  ["$xiaoyin1"] = "鹿栖于野，必能奔光而来。",
  ["$xiaoyin2"] = "磨硝作引，可点心中灵犀。",
}

xiaoyin:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiaoyin.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return player:distanceTo(p) <= 1
    end)
    local ids = room:getNCards(n)
    room:turnOverCardsFromDrawPile(player, ids, xiaoyin.name)
    room:delay(2000)
    local to_get = table.filter(ids, function (id)
      return Fk:getCardById(id).color == Card.Red
    end)
    if #to_get > 0 then
      room:obtainCard(player, to_get, true, fk.ReasonJustMove)
    end
    local cards = table.filter(ids, function (id)
      return room:getCardArea(id) == Card.Processing and Fk:getCardById(id).color == Card.Black
    end)
    local targets = room:getOtherPlayers(player, false)
    local selected = {}
    while #cards > 0 and #targets > 0 and not player.dead do
      local to, id = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        min_num = 1,
        max_num = 1,
        targets = targets,
        pattern = tostring(Exppattern{ id = cards }),
        expand_pile = cards,
        skill_name = xiaoyin.name,
        prompt = "#xiaoyin-give",
        cancelable = true,
      })
      if #to == 0 then break end
      to = to[1]
      table.insert(selected, to)
      table.removeOne(cards, id[1])
      to:addToPile(xiaoyin.name, id, true, xiaoyin.name)
      if player.dead or #cards == 0 or #targets == 0 then break end
      targets = table.filter(room:getOtherPlayers(player, false), function(p)
        if not table.contains(selected, p) then
          for _, q in ipairs(selected) do
            if p:getNextAlive() == q or q:getNextAlive() == p then
              return true
            elseif p:getNextAlive() == player and player:getNextAlive() == q then
              return true
            elseif q:getNextAlive() == player and player:getNextAlive() == p then
              return true
            end
          end
        end
      end)
    end
    room:cleanProcessingArea(ids)
  end,
})

xiaoyin:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.from == player and not player.dead and #target:getPile("xiaoyin") > 0 then
      if data.damageType == fk.FireDamage then
        return not player:isNude()
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.FireDamage then
      local types = {}
      for _, id in ipairs(target:getPile("xiaoyin")) do
        table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
      end
      local card = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xiaoyin.name,
        cancelable = true,
        pattern = ".|.|.|.|.|"..table.concat(types, ","),
        prompt = "#xiaoyin-damage::"..target.id,
        skip = true,
      })
      if #card > 0 then
        event:setCostData(self, {tos = {target}, cards = card})
        return true
      end
    elseif room:askToSkillInvoke(player, {
        skill_name = "xiaoyin",
        prompt = "#xiaoyin-fire::"..target.id,
      }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageType == fk.FireDamage then
      local card_type = Fk:getCardById(event:getCostData(self).cards[1]).type
      room:throwCard(event:getCostData(self).cards, xiaoyin.name, player, player)
      local ids = table.filter(target:getPile(xiaoyin.name), function(id)
        return Fk:getCardById(id).type == card_type end)
      if #ids > 0 then
        room:moveCards({
          from = target,
          ids = table.random(ids, 1),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = xiaoyin.name,
        })
        data:changeDamage(1)
      end
    else
      local id = room:askToChooseCard(player, {
        target = target,
        flag = { card_data = {{ xiaoyin.name, target:getPile(xiaoyin.name) }} },
        skill_name = xiaoyin.name,
        prompt = "#xiaoyin-fire::" .. target.id
      })
      room:moveCardTo(id, Card.PlayerHand, player, fk.ReasonJustMove, xiaoyin.name, nil, true, player)
      data.damageType = fk.FireDamage
    end
  end,
})

return xiaoyin
