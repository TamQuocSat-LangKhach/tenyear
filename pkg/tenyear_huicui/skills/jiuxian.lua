local jiuxian = fk.CreateSkill {
  name = "jiuxianc",
}

Fk:loadTranslationTable{
  ["jiuxianc"] = "救陷",
  [":jiuxianc"] = "出牌阶段限一次，你可以重铸一半手牌（向上取整），然后视为使用一张【决斗】。此牌对目标角色造成伤害后，你可以"..
  "令其攻击范围内的一名其他角色回复1点体力。",

  ["#jiuxianc"] = "救陷：你可以重铸一半手牌（%arg张），然后视为使用一张【决斗】",
  ["#jiuxianc-duel"] = "救陷：请视为使用【决斗】",
  ["#jiuxianc-recover"] = "救陷：你可以令其中一名角色回复1点体力",

  ["$jiuxianc1"] = "救袍泽于水火，返清明于天下。",
  ["$jiuxianc2"] = "与君共扼王旗，焉能见死不救。",
}

jiuxian:addEffect("active", {
  anim_type = "support",
  card_num = function(self, player)
    return (1 + player:getHandcardNum()) // 2
  end,
  target_num = 0,
  prompt = function(self, player)
    return "#jiuxianc:::"..(1 + player:getHandcardNum()) // 2
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(jiuxian.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < (1 + player:getHandcardNum()) // 2 and table.contains(player:getCardIds("h"), to_select)
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    room:recastCard(effect.cards, player, jiuxian.name)
    if not player.dead and player:canUse(Fk:cloneCard("duel")) then
      room:askToUseVirtualCard(player, {
        name = "duel",
        skill_name = jiuxian.name,
        prompt = "#jiuxianc-duel",
        cancelable = false,
      })
    end
  end
})

jiuxian:addEffect(fk.Damage, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.room.logic:damageByCardEffect() and
      not player.dead and not data.to.dead and data.card and table.contains(data.card.skillNames, jiuxian.name) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return data.to:inMyAttackRange(p) and p:isWounded()
      end)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return data.to:inMyAttackRange(p) and p:isWounded()
    end)
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = jiuxian.name,
      prompt = "#jiuxianc-recover",
    })
    if #to > 0 then
      room:recover{
        who = to[1],
        num = 1,
        recoverBy = player,
        skillName = jiuxian.name,
      }
    end
  end,
})

return jiuxian
