local jinjian = fk.CreateSkill {
  name = "jinjian"
}

Fk:loadTranslationTable{
  ['jinjian'] = '进谏',
  ['@@jinjian_plus-turn'] = '进谏+',
  ['#jinjian1-invoke'] = '进谏：你可以令对 %dest 造成的伤害+1',
  ['@@jinjian_minus-turn'] = '进谏-',
  ['#jinjian2-invoke'] = '进谏：你可以令受到的伤害-1',
  [':jinjian'] = '当你造成伤害时，你可令此伤害+1，若如此做，你此回合下次造成的伤害-1且不能发动〖进谏〗；当你受到伤害时，你可令此伤害-1，若如此做，你此回合下次受到的伤害+1且不能发动〖进谏〗。',
  ['$jinjian1'] = '臣代天子牧民，闻苛自当谏之。',
  ['$jinjian2'] = '为将者死战，为臣者死谏！'
}

jinjian:addEffect(fk.DamageCaused, {
  on_cost = function(self, event, target, player, data)
    return player:getMark("@@jinjian_plus-turn") > 0 or player.room:askToSkillInvoke(player, { skill_name = jinjian.name, prompt = "#jinjian1-invoke::" .. data.to.id })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jinjian.name)
    if player:getMark("@@jinjian_plus-turn") > 0 then
      room:notifySkillInvoked(player, jinjian.name, "negative")
      room:setPlayerMark(player, "@@jinjian_plus-turn", 0)
      data.damage = data.damage - 1
    else
      room:notifySkillInvoked(player, jinjian.name, "offensive")
      room:setPlayerMark(player, "@@jinjian_plus-turn", 1)
      data.damage = data.damage + 1
    end
  end,
})

jinjian:addEffect(fk.DamageInflicted, {
  on_cost = function(self, event, target, player, data)
    return player:getMark("@@jinjian_minus-turn") > 0 or player.room:askToSkillInvoke(player, { skill_name = jinjian.name, prompt = "#jinjian2-invoke" })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(jinjian.name)
    if player:getMark("@@jinjian_minus-turn") > 0 then
      room:notifySkillInvoked(player, jinjian.name, "negative")
      room:setPlayerMark(player, "@@jinjian_minus-turn", 0)
      data.damage = data.damage + 1
    else
      room:notifySkillInvoked(player, jinjian.name, "defensive")
      room:setPlayerMark(player, "@@jinjian_minus-turn", 1)
      data.damage = data.damage - 1
    end
  end,
})

return jinjian
