local fuxie = fk.CreateSkill {
  name = "fuxie"
}

Fk:loadTranslationTable{
  ['fuxie'] = '伏械',
  ['fuxie_weapon'] = '弃置武器牌',
  ['#fuxie_weapon'] = '伏械：弃置一张武器牌，令一名其他角色弃置两张手牌',
  ['#fuxie_skill'] = '伏械：失去一个技能，令一名其他角色弃置两张手牌',
  [':fuxie'] = '出牌阶段，你可以弃置一张武器牌或失去一个其他技能，令一名其他角色弃置两张牌。',
  ['$fuxie1'] = '箭射辕角，夏侯老贼必中疑兵之计。',
  ['$fuxie2'] = '借父三矢以诱敌，佯装黄汉升在此。',
}

fuxie:addEffect('active', {
  target_num = 1,
  prompt = function (skill, player)
    if skill.interaction.data == "fuxie_weapon" then
      return "#fuxie_weapon"
    else
      return "#fuxie_skill"
    end
  end,
  interaction = function(self, player)
    local choices = {"fuxie_weapon"}
    local skills = table.map(table.filter(player.player_skills, function (s)
      return s:isPlayerSkill(player) and s.visible and s.name ~= fuxie.name
    end), Util.NameMapper)
    if #skills > 0 then
      table.insertTable(choices, skills)
    end
    return UI.ComboBox { choices = choices }
  end,
  can_use = Util.TrueFunc,
  card_filter = function(self, player, to_select, selected)
    if skill.interaction.data == "fuxie_weapon" then
      return Fk:getCardById(to_select).sub_type == Card.SubtypeWeapon and not player:prohibitDiscard(Fk:getCardById(to_select))
        and #selected == 0
    else
      return false
    end
  end,
  target_filter = function(self, player, to_select, selected, cards)
    return #selected == 0 and to_select ~= player.id and (skill.interaction.data ~= "fuxie_weapon" or #cards == 1)
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if #effect.cards > 0 then
      room:throwCard(effect.cards, fuxie.name, player)
    else
      room:handleAddLoseSkills(player, "-"..skill.interaction.data, nil, true, false)
    end
    if not target.dead and not target:isNude() then
      room:askToDiscard(target, {
        min_num = 2,
        max_num = 2,
        include_equip = true,
        skill_name = fuxie.name,
        cancelable = false,
      })
    end
  end,
})

return fuxie
