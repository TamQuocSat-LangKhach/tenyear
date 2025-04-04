local jianshu = fk.CreateSkill {
  name = "ty__jianshu",
}

Fk:loadTranslationTable{
  ["ty__jianshu"] = "间书",
  [":ty__jianshu"] = "出牌阶段限一次，你可以将一张黑色手牌交给一名其他角色，然后选择另一名其他角色，令这两名角色拼点：赢的角色随机弃置一张牌，"..
  "没赢的角色失去1点体力。若有角色因此死亡，此技能视为未发动过。",

  ["#ty__jianshu"] = "间书：将一张黑色手牌交给一名角色，令其与你选择的角色拼点，赢者弃牌，没赢者失去体力",
  ["#ty__jianshu-choose"] = "间书：选择另一名其他角色，令其和 %dest 拼点",

  ["$ty__jianshu1"] = "令其相疑，则一鼓可破也。",
  ["$ty__jianshu2"] = "貌合神离，正合用反间之计。",
}

jianshu:addEffect("active", {
  anim_type = "control",
  prompt = "#ty__jianshu",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(jianshu.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black and
      table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    room:obtainCard(target, Fk:getCardById(effect.cards[1]), false, fk.ReasonGive)
    if player.dead or target.dead then return end
    local targets = table.filter(room:getOtherPlayers(target, false), function (p)
      return target:canPindian(p)
    end)
    if #targets == 0 then return end
    local to = room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty__jianshu-choose::"..target.id,
      skill_name = jianshu.name,
      cancelable = false,
    })[1]
    local pindian = target:pindian({to}, jianshu.name)
    if pindian.results[to].winner then
      local winner, loser
      if pindian.results[to].winner == target then
        winner = target
        loser = to
      else
        winner = to
        loser = target
      end
      if not winner.dead then
        local cards = table.filter(winner:getCardIds("he"), function (id)
          return not winner:prohibitDiscard(id)
        end)
        if #cards > 0 then
          room:throwCard(table.random(cards), jianshu.name, winner, winner)
        end
      end
      if not loser.dead then
        room:loseHp(loser, 1, jianshu.name)
      end
    else
      targets = {target, to}
      room:sortByAction(targets)
      for _, p in ipairs(targets) do
        if not p.dead then
          room:loseHp(p, 1, jianshu.name)
        end
      end
    end
  end,
})

jianshu:addEffect(fk.Deathed, {
  can_refresh = function(self, event, target, player, data)
    if player:usedSkillTimes(jianshu.name, Player.HistoryPhase) > 0 then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.LoseHp)
      if e and e.data.skillName == jianshu.name then
        local skill_event = e:findParent(GameEvent.SkillEffect)
        return skill_event and skill_event.data.skill.name == jianshu.name and skill_event.data.who == player
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory(jianshu.name, 0, Player.HistoryPhase)
  end,
})

return jianshu
