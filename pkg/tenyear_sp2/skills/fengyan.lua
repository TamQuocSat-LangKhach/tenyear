local fengyan = fk.CreateSkill {
  name = "fengyan"
}

Fk:loadTranslationTable{
  ['fengyan'] = '讽言',
  ['fengyan1-phase'] = '令一名体力值不大于你的角色交给你一张手牌',
  ['fengyan2-phase'] = '视为对一名手牌数不大于你的角色使用【杀】',
  ['#fengyan-give'] = '讽言：你须交给 %src 一张手牌',
  [':fengyan'] = '出牌阶段每项限一次，你可以选择一名其他角色，若其体力值小于等于你，你令其交给你一张手牌；若其手牌数小于等于你，你视为对其使用【杀】（无距离限制）。',
  ['$fengyan1'] = '既将我儿杀之，何复念之！',
  ['$fengyan2'] = '乞问曹公，吾儿何时归还？'
}

fengyan:addEffect('active', {
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  interaction = function(skill)
    local choices = {}
    if skill.player:getMark("fengyan1-phase") == 0 then
      table.insert(choices, "fengyan1-phase")
    end
    if skill.player:getMark("fengyan2-phase") == 0 then
      table.insert(choices, "fengyan2-phase")
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = function(self, player)
    return player:getMark("fengyan1-phase") == 0 or player:getMark("fengyan2-phase") == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    if #selected == 0 and to_select ~= skill.player.id then
      local target = Fk:currentRoom():getPlayerById(to_select)
      if skill.interaction.data == "fengyan1-phase" then
        return target.hp <= skill.player.hp and not target:isKongcheng()
      elseif skill.interaction.data == "fengyan2-phase" then
        return target:getHandcardNum() <= skill.player:getHandcardNum() and not skill.player:isProhibited(target, Fk:cloneCard("slash"))
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    room:setPlayerMark(player, skill.interaction.data, 1)
    if skill.interaction.data == "fengyan1-phase" then
      local card = room:askToCards(target, {
        min_num = 1,
        max_num = 1,
        pattern = ".|.|.|hand",
        prompt = "#fengyan-give:"..player.id,
        skill_name = fengyan.name
      })
      if #card > 0 then
        room:obtainCard(player.id, card[1], false, fk.ReasonGive, target.id)
      end
    elseif skill.interaction.data == "fengyan2-phase" then
      room:useVirtualCard("slash", nil, player, target, fengyan.name, true)
    end
  end,
})

return fengyan
