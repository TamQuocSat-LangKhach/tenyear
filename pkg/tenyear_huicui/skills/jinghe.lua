local jinghe = fk.CreateSkill {
  name = "jinghe"
}

Fk:loadTranslationTable{
  ['jinghe'] = '经合',
  ['#jinghe'] = '经合：展示至多四张牌名各不同的手牌，令等量的角色获得技能',
  ['yinbingn'] = '阴兵',
  ['huoqi'] = '活气',
  ['guizhu'] = '鬼助',
  ['xianshou'] = '仙授',
  ['lundao'] = '论道',
  ['guanyue'] = '观月',
  ['yanzhengn'] = '言政',
  ['#jinghe-choice'] = '经合：选择你要获得的技能',
  [':jinghe'] = '出牌阶段限一次，你可展示至多四张牌名各不同的手牌，选择等量的角色，从“写满技能的天书”随机展示四个技能，这些角色依次选择并获得其中一个，直到你下回合开始或你死亡。',
  ['$jinghe1'] = '大哉乾元，万物资始。',
  ['$jinghe2'] = '无极之外，复无无极。',
}

jinghe:addEffect('active', {
  anim_type = "support",
  min_card_num = 1,
  min_target_num = 1,
  prompt = "#jinghe",
  can_use = function(self, player)
    return player:usedSkillTimes(jinghe.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    if #selected < 4 and Fk:currentRoom():getCardArea(to_select) == Player.Hand then
      if #selected == 0 then
        return true
      else
        return table.every(selected, function(id) return Fk:getCardById(to_select).trueName ~= Fk:getCardById(id).trueName end)
      end
    end
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected < #selected_cards
  end,
  feasible = function (skill, player, selected, selected_cards)
    return #selected > 0 and #selected == #selected_cards
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:sortPlayersByAction(effect.tos)
    local mark = player:getTableMark("jinghe_data")
    player:showCards(effect.cards)
    local skills = table.random(
      {"ex__leiji", "yinbingn", "huoqi", "guizhu", "xianshou", "lundao", "guanyue", "yanzhengn",
        "ex__biyue", "ex__tuxi", "ty_ex__mingce", "ty_ex__zhiyan"
      }, 4)
    local selected = {}
    for _, id in ipairs(effect.tos) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local choices = table.filter(skills, function(s) return not p:hasSkill(s, true) and not table.contains(selected, s) end)
        if #choices > 0 then
          local choice = room:askToChoice(p, {
            choices = choices,
            skill_name = jinghe.name,
            prompt = "#jinghe-choice",
            detailed = true,
            all_choices = skills
          })
          table.insert(selected, choice)
          room:handleAddLoseSkills(p, choice, nil, true, false)
          table.insert(mark, {p.id, choice})
          room:setPlayerMark(p, "jinghe-turn", 1)
        end
      end
    end
    room:setPlayerMark(player, "jinghe_data", mark)
  end,
})

jinghe:addEffect(fk.TurnStart + fk.Death, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("jinghe_data") ~= 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local mark = player:getMark("jinghe_data")
    room:setPlayerMark(player, "jinghe_data", 0)
    for _, dat in ipairs(mark) do
      local p = room:getPlayerById(dat[1])
      room:handleAddLoseSkills(p, "-"..dat[2], nil, true, false)
    end
  end,
})

return jinghe
