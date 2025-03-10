local huandao = fk.CreateSkill {
  name = "huandao"
}

Fk:loadTranslationTable{
  ['huandao'] = '寰道',
  ['#huandao'] = '寰道：你可令其他角色复原武将牌并获得同名武将技能',
  ['#huandao-choose'] = '寰道：你可以获得技能“%arg”，然后选择另一项技能失去',
  ['#huandao-lose'] = '寰道：请选择你要失去的技能',
  [':huandao'] = '限定技，出牌阶段，你可以选择一名其他角色，令其复原武将牌，然后其可随机获得一项同名武将的技能并选择失去一项其他技能。',
  ['$huandao1'] = '一语一默，道尽医者慈悲。',
  ['$huandao2'] = '亦疾亦缓，抚平世间苦难。',
}

huandao:addEffect('active', {
  anim_type = "support",
  prompt = "#huandao",
  card_num = 0,
  target_num = 1,
  frequency = Skill.Limited,
  can_use = function(self, player)
    return player:usedSkillTimes(huandao.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select.id ~= player.id
  end,
  on_use = function(self, room, effect)
    local target = room:getPlayerById(effect.tos[1])

    target:reset()
    local sameGenerals = Fk:getSameGenerals(target.general)
    local trueName = Fk.generals[target.general].trueName
    if trueName:startsWith("god") then
      table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals(string.sub(trueName, 4)))
    else
      table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals("god" .. trueName))
      if Fk.generals["god" .. trueName] then
        table.insertIfNeed(sameGenerals, "god" .. trueName)
      end
    end

    if target.deputyGeneral and target.deputyGeneral ~= "" then
      table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals(target.deputyGeneral))
      trueName = Fk.generals[target.deputyGeneral].trueName
      if trueName:startsWith("god") then
        table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals(string.sub(trueName, 4)))
      else
        table.insertTableIfNeed(sameGenerals, Fk:getSameGenerals("god" .. trueName))
        if Fk.generals["god" .. trueName] then
          table.insertIfNeed(sameGenerals, "god" .. trueName)
        end
      end
    end

    if #sameGenerals == 0 then
      return
    end

    local randomSkill = table.random(Fk.generals[table.random(sameGenerals)]:getSkillNameList())
    if room:askToSkillInvoke(target, { skill_name = huandao.name, prompt = "#huandao-choose:::" .. randomSkill }) then
      room:handleAddLoseSkills(target, randomSkill)
      local toLose = {}
      for _, s in ipairs(target.player_skills) do
        if s:isPlayerSkill(target) and s.name ~= randomSkill then
          table.insertIfNeed(toLose, s.name)
        end
      end

      if #toLose > 0 then
        local choice = room:askToChoice(target, { choices = toLose, skill_name = huandao.name, prompt = "#huandao-lose" })
        room:handleAddLoseSkills(target, "-" .. choice)
      end
    end
  end,
})

return huandao
