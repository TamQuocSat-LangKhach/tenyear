local kuiji = fk.CreateSkill {
  name = "kuiji"
}

Fk:loadTranslationTable{
  ['kuiji'] = '溃击',
  ['#kuiji-damage'] = '溃击：你可以对其他角色中体力值最大的一名角色造成2点伤害',
  ['#kuiji_trigger'] = '溃击',
  ['#kuiji-recover'] = '溃击：你可以令除 %dest 以外体力值最小的一名角色回复1点体力',
  [':kuiji'] = '出牌阶段限一次，你可以将一张黑色基本牌当作【兵粮寸断】对你使用，然后摸一张牌。若如此做，你可以对体力值最多的一名其他角色造成2点伤害。该角色因此进入濒死状态时，你可令另一名体力值最少的角色回复1点体力。',
  ['$kuiji1'] = '绝域奋击，孤注一掷。',
  ['$kuiji2'] = '舍得一身剐，不畏君王威。',
}

-- 主动技能部分
kuiji:addEffect('active', {
  name = "kuiji",
  anim_type = "offensive",
  target_num = 0,
  card_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(kuiji.name) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black then
      local card = Fk:cloneCard("supply_shortage")
      card:addSubcard(to_select)
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local card = Fk:cloneCard("supply_shortage")
    card:addSubcards(effect.cards)
    room:useCard{
      from = effect.from,
      tos = {{effect.from}},
      card = card,
    }
    player:drawCards(1, kuiji.name)
    local targets = {}
    local n = 0
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp > n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(player)) do
      if p.hp == n then
        table.insert(targets, p.id)
      end
    end
    local to = room:askToChoosePlayers(player, {
      targets = Fk:findPlayersByIds(targets),
      min_num = 1,
      max_num = 1,
      prompt = "#kuiji-damage",
      skill_name = kuiji.name,
      cancelable = true,
    })
    if #to > 0 then
      room:damage{
        from = player,
        to = room:getPlayerById(to[1].id),
        damage = 2,
        skillName = kuiji.name,
      }
    end
  end,
})

-- 触发技能部分
kuiji:addEffect(fk.EnterDying, {
  name = "#kuiji_trigger",
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(kuiji.name) and data.damage and data.damage.skillName == "kuiji"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = {}
    local n = 999
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp < n then
        n = p.hp
      end
    end
    for _, p in ipairs(room:getOtherPlayers(target)) do
      if p.hp == n and p:isWounded() then
        table.insert(targets, p.id)
      end
    end
    local to = room:askToChoosePlayers(player, {
      targets = Fk:findPlayersByIds(targets),
      min_num = 1,
      max_num = 1,
      prompt = "#kuiji-recover::" .. target.id,
      skill_name = kuiji.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1].id)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover({
      who = player.room:getPlayerById(event:getCostData(self)),
      num = 1,
      recoverBy = player,
      skillName = "kuiji"
    })
  end,
})

return kuiji
