local jiuxianc = fk.CreateSkill {
  name = "jiuxianc"
}

Fk:loadTranslationTable{
  ['jiuxianc'] = '救陷',
  ['#jiuxianc'] = '救陷：你可以重铸一半手牌（%arg张），然后视为使用一张【决斗】',
  ['#jiuxianc_delay'] = '救陷',
  ['#jiuxianc-recover'] = '救陷：你可以令其中一名角色回复1点体力',
  [':jiuxianc'] = '出牌阶段限一次，你可以重铸一半手牌（向上取整），然后视为使用一张【决斗】。此牌对目标角色造成伤害后，你可令其攻击范围内的一名其他角色回复1点体力。',
  ['$jiuxianc1'] = '救袍泽于水火，返清明于天下。',
  ['$jiuxianc2'] = '与君共扼王旗，焉能见死不救。',
}

-- 主动技能
jiuxianc:addEffect('active', {
  anim_type = "support",
  card_num = function(player)
    return (1 + player:getHandcardNum()) // 2
  end,
  target_num = 0,
  prompt = function(self, player)
    return "#jiuxianc:::"..(1 + player:getHandcardNum()) // 2
  end,
  can_use = function(player)
    return player:usedSkillTimes(jiuxianc.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected < (1 + player:getHandcardNum()) // 2 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip
  end,
  on_use = function(room, effect)
    local player = room:getPlayerById(effect.from)
    room:recastCard(effect.cards, player, jiuxianc.name)
    if not player.dead then
      U.askToUseVirtualCard(room, player, {
        pattern = "duel",
        skill_name = jiuxianc.name,
        cancelable = false
      })
    end
  end
})

-- 触发技能
jiuxianc:addEffect(fk.Damage, {
  mute = true,
  can_trigger = function(event, target, player, data)
    return target == player and player.room.logic:damageByCardEffect() and not player.dead and not data.to.dead
      and data.card and table.contains(data.card.skillNames, jiuxianc.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player), function(p) return data.to:inMyAttackRange(p) and p:isWounded() end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(player, {
        targets = table.map(targets, Util.IdMapper),
        min_num = 1,
        max_num = 1,
        skill_name = jiuxianc.name,
        prompt = "#jiuxianc-recover"
      })
      if #tos > 0 then
        room:recover({
          who = tos[1],
          num = 1,
          recoverBy = player,
          skillName = jiuxianc.name
        })
      end
    end
  end,
})

return jiuxianc
