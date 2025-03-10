local ty__xiongyi = fk.CreateSkill {
  name = "ty__xiongyi"
}

Fk:loadTranslationTable{
  ['ty__xiongyi'] = '雄异',
  ['#ty__xiongyi'] = '雄异：选择一名其他角色，与其各摸三张牌！',
  [':ty__xiongyi'] = '限定技，出牌阶段，你可以选择一名其他角色，你与其各摸三张牌，然后若你体力值全场唯一最少，你回复1点体力。当你进入濒死状态被救回后，若你发动过此技能，此技能视为未发动过并移除回复体力的效果。',
  ['$ty__xiongyi1'] = '弟兄们，我们的机会来啦！',
  ['$ty__xiongyi2'] = '此时不战，更待何时！'
}

ty__xiongyi:addEffect('active', {
  anim_type = "drawcard",
  target_num = 1,
  card_num = 0,
  frequency = Skill.Limited,
  prompt = "#ty__xiongyi",
  can_use = function(self, player)
    return player:usedSkillTimes(ty__xiongyi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    player:drawCards(3, ty__xiongyi.name)
    if not target.dead then
      target:drawCards(3, ty__xiongyi.name)
    end
    if player:isWounded() and not player.dead and player:getMark("ty__xiongyi") == 0 and
      table.every(room:getOtherPlayers(player), function (p)
        return p.hp > player.hp
      end) then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = ty__xiongyi.name,
      })
    end
  end,
})

ty__xiongyi:addEffect(fk.AfterDying, {
  can_refresh = function(self, event, target, player)
    return target == player and not player.dead and player:usedSkillTimes("ty__xiongyi", Player.HistoryGame) > 0
  end,
  on_refresh = function(self, event, target, player)
    player:setSkillUseHistory(ty__xiongyi.name, 0, Player.HistoryGame)
    player.room:setPlayerMark(player, "ty__xiongyi", 1)
  end,
})

return ty__xiongyi
