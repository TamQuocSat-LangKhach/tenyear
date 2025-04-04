local kuiji = fk.CreateSkill {
  name = "kuiji",
}

Fk:loadTranslationTable{
  ["kuiji"] = "溃击",
  [":kuiji"] = "出牌阶段限一次，你可以将一张黑色基本牌当【兵粮寸断】对你使用，然后摸一张牌。若如此做，你可以对体力值最大的"..
  "一名其他角色造成2点伤害。该角色因此进入濒死状态时，你可以令另一名体力值最少的角色回复1点体力。",

  ["#kuiji"] = "溃击：将一张黑色基本牌当【兵粮寸断】对你使用并摸一张牌，然后对体力值最大的其他角色造成2点伤害！",
  ["#kuiji-damage"] = "溃击：你可以对体力值最大的一名角色造成2点伤害",
  ["#kuiji-recover"] = "溃击：你可以令除 %dest 以外一名角色回复1点体力",

  ["$kuiji1"] = "绝域奋击，孤注一掷。",
  ["$kuiji2"] = "舍得一身剐，不畏君王威。",
}

kuiji:addEffect("active", {
  anim_type = "offensive",
  prompt = "#kuiji",
  target_num = 0,
  card_num = 1,
  can_use = function(self, player)
    return player:usedEffectTimes(kuiji.name, Player.HistoryPhase) == 0 and not player:hasDelayedTrick("supply_shortage")
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected == 0 and Fk:getCardById(to_select).type == Card.TypeBasic and Fk:getCardById(to_select).color == Card.Black then
      local card = Fk:cloneCard("supply_shortage")
      card:addSubcard(to_select)
      return not player:prohibitUse(card) and not player:isProhibited(player, card)
    end
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:useVirtualCard("supply_shortage", effect.cards, player, player, kuiji.name)
    if player.dead then return end
    player:drawCards(1, kuiji.name)
    if player.dead then return end
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return table.every(room:getOtherPlayers(player, false), function(q)
        return q.hp <= p.hp
      end)
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#kuiji-damage",
      skill_name = kuiji.name,
      cancelable = true,
    })
    if #to > 0 then
      room:damage{
        from = player,
        to = to[1],
        damage = 2,
        skillName = kuiji.name,
      }
    end
  end,
})

kuiji:addEffect(fk.EnterDying, {
  anim_type = "support",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.damage and data.damage.skillName == kuiji.name and not player.dead then
      local skill_event = player.room.logic:getCurrentEvent():findParent(GameEvent.SkillEffect)
      if skill_event and skill_event.data.skill.name == kuiji.name and skill_event.data.who == player then
        local targets = table.filter(player.room:getOtherPlayers(target, false), function(p)
          return p:isWounded() and table.every(player.room:getOtherPlayers(target, false), function(q)
            return q.hp >= p.hp
          end)
        end)
        if #targets > 0 then
          event:setCostData(self, {extra_data = targets})
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = event:getCostData(self).extra_data
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#kuiji-recover::" .. target.id,
      skill_name = kuiji.name,
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:recover{
      who = event:getCostData(self).tos[1],
      num = 1,
      recoverBy = player,
      skillName = kuiji.name,
    }
  end,
})

return kuiji
