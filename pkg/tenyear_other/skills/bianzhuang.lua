local bianzhuang = fk.CreateSkill {
  name = "bianzhuang"
}

Fk:loadTranslationTable{
  ['bianzhuang'] = '变装',
  ['#bianzhuang'] = '变装：你可以进行“变装”！然后视为使用一张【杀】',
  ['#bianzhuang-choice'] = '变装：选择你“变装”获得的技能效果',
  ['#bianzhuang-slash'] = '变装：视为使用一张【杀】，附带“%arg”的技能效果！',
  [':bianzhuang'] = '出牌阶段限一次，你可以从两名武将中选择一个进行变装，然后视为使用一张【杀】（无距离和次数限制），根据变装此【杀】获得额外效果。当你使用装备牌后，重置本阶段〖变装〗发动次数。当你发动三次〖变装〗后，本局游戏你进行变装时增加一个选项。',
  ['$bianzhuang1'] = '须知少日凌云志，曾许人间第一流。',
  ['$bianzhuang2'] = '愿尽绵薄之力，盼国风盛行。',
}

-- 主动技能部分
bianzhuang:addEffect('active', {
  anim_type = "special",
  card_num = 0,
  target_num = 0,
  prompt = "#bianzhuang",
  can_use = function(self, player)
    return player:usedSkillTimes(bianzhuang.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local n = player:usedSkillTimes(bianzhuang.name, Player.HistoryGame) > 3 and 3 or 2
    local all_choices = table.filter(bianzhuang_choices, function (c)
      return Fk.generals[c[1]] ~= nil and Fk.skills[c[2]] ~= nil
    end)
    local choices = table.random(all_choices, n)
    local generals = table.map(choices, function(c) return c[1] end)
    local skills = table.map(choices, function(c) return {c[2]} end)

    local result = player.room:askToCustomDialog(player, {
      skill_name = bianzhuang.name,
      qml_path = "packages/tenyear/qml/ChooseGeneralSkillsBox.qml",
      extra_data = {generals, skills, 1, 1, "#bianzhuang-choice", false}
    })
    local skill_name = skills[1][1]
    if result ~= "" then
      skill_name = json.decode(result)[1]
    end
    local general_name = table.find(generals, function (g, i)
      return skills[i][1] == skill_name
    end)
    local general = Fk.generals[general_name]

    local bianzhuang_info = {player.general, player.gender, player.kingdom}
    player.general = general_name
    room:broadcastProperty(player, "general")
    player.gender = general.gender
    room:broadcastProperty(player, "gender")
    player.kingdom = general.kingdom
    room:broadcastProperty(player, "kingdom")
    local acquired = (not player:hasSkill(skill_name, true))
    if acquired then
      room:handleAddLoseSkills(player, skill_name, nil, false)
    end

    U.askForUseVirtualCard(room, player, "slash", nil, bianzhuang.name, "#bianzhuang-slash:::"..skill_name, false, true, true, true)

    if acquired then
      room:handleAddLoseSkills(player, "-"..skill_name, nil, false)
    end
    player.general = bianzhuang_info[1]
    room:broadcastProperty(player, "general")
    player.gender = bianzhuang_info[2]
    room:broadcastProperty(player, "gender")
    player.kingdom = bianzhuang_info[3]
    room:broadcastProperty(player, "kingdom")
  end,
})

-- 触发技能部分
bianzhuang:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeEquip and player:usedSkillTimes(bianzhuang.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory(bianzhuang.name, 0, Player.HistoryPhase)
  end,
})

return bianzhuang
