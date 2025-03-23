local cuirui = fk.CreateSkill {
  name = "cuirui"
}

Fk:loadTranslationTable{
  ['cuirui'] = '摧锐',
  [':cuirui'] = '限定技，出牌阶段，你可以选择至多X名其他角色（X为你的体力值），你获得这些角色各一张手牌。',
  ['$cuirui1'] = '摧折锐气，未战先衰。',
  ['$cuirui2'] = '挫其锐气，折其旌旗。',
}

cuirui:addEffect('active', {
  anim_type = "offensive",
  frequency = Skill.Limited,
  card_num = 0,
  min_target_num = 1,
  max_target_num = function(player)
    return player:hp()
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(cuirui.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    local p = Fk:currentRoom():getPlayerById(to_select)
    return #selected < player:hp() and to_select ~= player:id() and not p:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      local card = room:askToChooseCard(player, {
        target = p,
        flag = "h",
        skill_name = cuirui.name
      })
      room:obtainCard(player, card, false, fk.ReasonPrey)
    end
  end,
})

return cuirui
