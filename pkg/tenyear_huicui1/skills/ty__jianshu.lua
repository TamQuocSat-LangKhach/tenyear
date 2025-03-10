local ty__jianshu = fk.CreateSkill {
  name = "ty__jianshu"
}

Fk:loadTranslationTable{
  ['ty__jianshu'] = '间书',
  ['#ty__jianshu-prompt'] = '间书：选择一张黑色手牌交给一名其他角色，令其与你选择的角色拼点，赢的弃牌，没赢失去体力',
  ['#ty__jianshu-choose'] = '间书：选择另一名其他角色，令其和 %dest 拼点',
  [':ty__jianshu'] = '出牌阶段限一次，你可以将一张黑色手牌交给一名其他角色，然后选择另一名其他角色，令这两名角色拼点：赢的角色随机弃置一张牌，没赢的角色失去1点体力。若有角色因此死亡，此技能视为未发动过。',
  ['$ty__jianshu1'] = '令其相疑，则一鼓可破也。',
  ['$ty__jianshu2'] = '貌合神离，正合用反间之计。',
}

ty__jianshu:addEffect('active', {
  anim_type = "control",
  card_num = 1,
  target_num = 1,
  prompt = "#ty__jianshu-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__jianshu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
      and table.contains(Self.player_cards[Player.Hand], to_select)
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player.id and #cards == 1
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:obtainCard(target.id, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive, player.id, ty__jianshu.name)
    if target.dead or target:isKongcheng() or player.dead then return end
    local targets = table.filter(room.alive_players, function(p) return target:canPindian(p) and p ~= player end)
    if #targets == 0 then return end
    local to = room:getPlayerById(room:askToChoosePlayers(player, {
      targets = table.map(targets, Util.IdMapper),
      min_num = 1,
      max_num = 1,
      prompt = "#ty__jianshu-choose::" .. target.id,
      skill_name = ty__jianshu.name
    })[1])
    local pindian = target:pindian({to}, ty__jianshu.name)
    if pindian.results[to.id].winner then
      local winner, loser
      if pindian.results[to.id].winner == target then
        winner = target
        loser = to
      else
        winner = to
        loser = target
      end
      if not winner:isNude() and not winner.dead then
        local id = table.random(winner:getCardIds{Player.Hand, Player.Equip})
        room:throwCard({id}, ty__jianshu.name, winner, winner)
      end
      if not loser.dead then
        room:loseHp(loser, 1, ty__jianshu.name)
      end
    else
      if not target.dead then
        room:loseHp(target, 1, ty__jianshu.name)
      end
      if not to.dead then
        room:loseHp(to, 1, ty__jianshu.name)
      end
    end
  end
})

ty__jianshu:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    if player:usedSkillTimes(ty__jianshu.name, Player.HistoryPhase) > 0 then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.LoseHp)
      if e then
        return e.data[3] == ty__jianshu.name
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory(ty__jianshu.name, 0, Player.HistoryPhase)
  end,
})

return ty__jianshu
