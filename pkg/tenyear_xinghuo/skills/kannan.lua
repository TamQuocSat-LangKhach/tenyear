local kannan = fk.CreateSkill {
  name = "kannan"
}

Fk:loadTranslationTable{
  ['kannan'] = '戡难',
  ['@kannan'] = '戡难',
  [':kannan'] = '出牌阶段，若你于此阶段内发动过此技能的次数小于X（X为你的体力值），你可与你于此阶段内未以此法拼点过的一名角色拼点。若：你赢，你使用的下一张【杀】的伤害值基数+1且你于此阶段内不能发动此技能；其赢，其使用的下一张【杀】的伤害值基数+1。',
  ['$kannan1'] = '俊才之杰，材匪戡难。',
  ['$kannan2'] = '戡，克也，难，攻之。',
}

kannan:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return not player:isKongcheng() and player:getMark("kannan-phase") == 0 and player:usedSkillTimes(kannan.name, Player.HistoryPhase) < player.hp
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    local target = Fk:currentRoom():getPlayerById(to_select)
    return #selected == 0 and to_select ~= player.id and target:getMark("kannan-phase") == 0 and player:canPindian(target)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(target, "kannan-phase", 1)
    local pindian = player:pindian({target}, kannan.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(player, "@kannan", 1)
      room:setPlayerMark(player, "kannan-phase", 1)
    elseif pindian.results[target.id].winner == target then
      room:addPlayerMark(target, "@kannan", 1)
    end
  end,
})

kannan:addEffect(fk.PreCardUse, {
  global = true,
  can_trigger = function(self, event, player, data)
    return player:getMark("@kannan") > 0 and data.card.trueName == "slash"
  end,
  on_use = function(self, event, player, data)
    data.additionalDamage = (data.additionalDamage or 0) + player:getMark("@kannan")
    player.room:setPlayerMark(player, "@kannan", 0)
  end,
})

return kannan
