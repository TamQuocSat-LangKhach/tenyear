local tanbei = fk.CreateSkill {
  name = "tanbei"
}

Fk:loadTranslationTable{
  ['tanbei'] = '贪狈',
  ['#tanbei-prompt'] = '贪狈：令一名其他角色选择被你获得牌，或你对其使用牌无次数距离限制',
  ['tanbei2'] = '此回合对你使用牌无距离和次数限制',
  ['tanbei1'] = '其随机获得你区域内的一张牌，此回合不能再对你使用牌',
  ['@@tanbei-turn'] = '被贪狈',
  [':tanbei'] = '出牌阶段限一次，你可以令一名其他角色选择一项：1.令你随机获得其区域内的一张牌，此回合不能再对其使用牌；2.令你此回合对其使用牌无距离和次数限制。',
  ['$tanbei1'] = '此机，我怎么会错失。',
  ['$tanbei2'] = '你的东西，现在是我的了！',
}

tanbei:addEffect('active', {
  anim_type = "offensive",
  card_num = 0,
  target_num = 1,
  prompt = "#tanbei-prompt",
  can_use = function(self, player)
    return player:usedSkillTimes(tanbei.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, use)
    local player = room:getPlayerById(use.from)
    local target = room:getPlayerById(use.tos[1])
    local choices = {"tanbei2"}
    if not target:isAllNude() then
      table.insert(choices, 1, "tanbei1")
    end
    local choice = room:askToChoice(target, {
      choices = choices,
      skill_name = tanbei.name
    })
    room:addTableMark(player, choice.."-turn", target.id)
    if choice == "tanbei1" then
      local id = table.random(target:getCardIds{Player.Hand, Player.Equip, Player.Judge})
      room:obtainCard(player.id, id, false, fk.ReasonPrey, player.id, tanbei.name)
    else
      room:setPlayerMark(target, "@@tanbei-turn", 1)
    end
  end,
})

tanbei:addEffect(fk.PreCardUse, {
  can_refresh = function(self, event, target, player, data)
    if player == target then
      local mark = player:getTableMark("tanbei2-turn")
      return #mark > 0 and table.find(TargetGroup:getRealTargets(data.tos), function (pid)
        return table.contains(mark, pid)
      end)
    end
  end,
  on_refresh = function(self, event, target, player, data)
    data.extraUse = true
  end,
})

tanbei:addEffect('prohibit', {
  is_prohibited = function(self, from, to, card)
    return table.contains(from:getTableMark("tanbei1-turn"), to.id)
  end,
})

tanbei:addEffect('targetmod', {
  bypass_times = function(self, player, skill, scope, card, to)
    return card and to and table.contains(player:getTableMark("tanbei2-turn"), to.id)
  end,
  bypass_distances = function(self, player, skill, card, to)
    return card and to and table.contains(player:getTableMark("tanbei2-turn"), to.id)
  end,
})

return tanbei
