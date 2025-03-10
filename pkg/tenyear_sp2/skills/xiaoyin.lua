local xiaoyin = fk.CreateSkill {
  name = "xiaoyin"
}

Fk:loadTranslationTable{
  ['xiaoyin'] = '硝引',
  ['xiaoyin_active'] = '硝引',
  ['#xiaoyin-give'] = '硝引：将黑色牌作为“硝引”放置在连续的其他角色武将牌上',
  ['#xiaoyin_trigger'] = '硝引',
  ['#xiaoyin-damage'] = '硝引：你可以弃置一张与 %dest “硝引”同类别的牌，令其受到伤害+1',
  ['#xiaoyin-fire'] = '硝引：你可以获得 %dest 的一张“硝引”，令此伤害改为火焰伤害',
  [':xiaoyin'] = '准备阶段，你可以亮出牌堆顶X张牌（X为你距离1以内的角色数），获得其中红色牌，将其中任意张黑色牌作为“硝引”放置在等量名座次连续（不计入你的座位）的其他角色的武将牌上。有“硝引”牌的角色受到伤害时：若为火焰伤害，伤害来源可以弃置一张与“硝引”同类别的牌并随机移去一张此类别的“硝引”牌令此伤害+1；不为火焰伤害，伤害来源可以获得其一张“硝引”牌并将此伤害改为火焰伤害。',
  ['$xiaoyin1'] = '鹿栖于野，必能奔光而来。',
  ['$xiaoyin2'] = '磨硝作引，可点心中灵犀。',
}

xiaoyin:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(xiaoyin) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local n = #table.filter(room.alive_players, function(p)
      return player == p or player:distanceTo(p) == 1
    end)
    local ids = U.turnOverCardsFromDrawPile(player, n, xiaoyin.name)
    room:delay(2000)
    local to_get = {}
    for i = #ids, 1, -1 do
      if Fk:getCardById(ids[i]).color == Card.Red then
        table.insert(to_get, ids[i])
        table.remove(ids, i)
      end
    end
    if #to_get > 0 then
      room:obtainCard(player.id, to_get, true, fk.ReasonJustMove)
    end
    local targets = {}
    while #ids > 0 and not player.dead do
      room:setPlayerMark(player, "xiaoyin_cards", ids)
      room:setPlayerMark(player, "xiaoyin_targets", targets)
      local success, dat = room:askToUseActiveSkill(player, {
        skill_name = "xiaoyin_active",
        prompt = "#xiaoyin-give",
        cancelable = true,
        extra_data = {cards = ids, targets = targets},
      })
      room:setPlayerMark(player, "xiaoyin_cards", 0)
      room:setPlayerMark(player, "xiaoyin_targets", 0)
      if not success then break end
      table.insert(targets, dat.targets[1])
      table.removeOne(ids, dat.cards[1])
      room:getPlayerById(dat.targets[1]):addToPile("xiaoyin", dat.cards[1], true, xiaoyin.name)
    end
    room:cleanProcessingArea(ids, xiaoyin.name)
  end,
})

xiaoyin:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player and #player:getPile("xiaoyin") > 0 and data.from and not data.from.dead then
      if data.damageType == fk.FireDamage then
        return not data.from:isNude()
      else
        return true
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    if data.damageType == fk.FireDamage then
      local types = {}
      for _, id in ipairs(target:getPile("xiaoyin")) do
        table.insertIfNeed(types, Fk:getCardById(id):getTypeString())
      end
      local card = room:askToDiscard(data.from, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = xiaoyin.name,
        cancelable = true,
        pattern = ".|.|.|.|.|"..table.concat(types, ","),
        prompt = "#xiaoyin-damage::"..target.id,
        skip = true
      })
      if #card > 0 then
        event:setCostData(skill, card)
        return true
      end
    else
      return room:askToSkillInvoke(data.from, {
        skill_name = "xiaoyin",
        prompt = "#xiaoyin-fire::"..target.id,
      })
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.from:hasSkill(xiaoyin, true) then
      data.from:broadcastSkillInvoke("xiaoyin")
      room:notifySkillInvoked(data.from, "xiaoyin", "offensive")
    end
    room:doIndicate(data.from.id, {target.id})
    if data.damageType == fk.FireDamage then
      local card_type = Fk:getCardById(event:getCostData(skill)[1]).type
      room:throwCard(event:getCostData(skill), "xiaoyin", data.from, data.from)
      local ids = table.filter(target:getPile("xiaoyin"), function(id)
        return Fk:getCardById(id).type == card_type end)
      if #ids > 0 then
        room:moveCards({
          from = target.id,
          ids = table.random(ids, 1),
          toArea = Card.DiscardPile,
          moveReason = fk.ReasonPutIntoDiscardPile,
          skillName = "xiaoyin",
          specialName = "xiaoyin",
        })
        data.damage = data.damage + 1
      end
    else
      local id = room:askToChooseCard(data.from, {
        target = target,
        flag = { card_data = {{ "xiaoyin", target:getPile("xiaoyin") }} },
        skill_name = "xiaoyin",
        prompt = "#xiaoyin-fire::" .. target.id
      })
      room:moveCardTo(id, Card.PlayerHand, data.from, fk.ReasonJustMove, xiaoyin.name, nil, true, data.from.id)
      data.damageType = fk.FireDamage
    end
  end,
})

return xiaoyin
