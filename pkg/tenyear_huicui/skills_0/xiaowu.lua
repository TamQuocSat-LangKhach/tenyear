local xiaowu = fk.CreateSkill {
  name = "xiaowu"
}

Fk:loadTranslationTable{
  ['xiaowu'] = '绡舞',
  ['#xiaowu'] = '发动 绡舞，选择按逆时针（行动顺序）或顺时针顺序结算，并选择作为终点的目标角色',
  ['xiaowu_anticlockwise'] = '逆时针顺序',
  ['xiaowu_clockwise'] = '顺时针顺序',
  ['xiaowu_draw1'] = '令其摸一张牌',
  ['#xiawu_draw'] = '绡舞：选择令%src摸一张牌或自己摸一张牌',
  ['@xiaowu_sand'] = '沙',
  [':xiaowu'] = '出牌阶段限一次，你可以从你的上家或下家起选择任意名座位连续的其他角色，每名角色依次选择一项：1.令你摸一张牌；2.自己摸一张牌。选择完成后，若令你摸牌的选择人数较多，你获得一个“沙”标记；若自己摸牌的选择人数较多，你对这些角色各造成1点伤害。',
  ['$xiaowu1'] = '繁星临云袖，明月耀舞衣。',
  ['$xiaowu2'] = '逐舞飘轻袖，传歌共绕梁。',
}

xiaowu:addEffect('active', {
  anim_type = "offensive",
  prompt = "#xiaowu",
  max_card_num = 0,
  target_num = 1,
  interaction = function(self)
    return UI.ComboBox { choices = {"xiaowu_anticlockwise", "xiaowu_clockwise"} }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(xiaowu.name, Player.HistoryPhase) < 1
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local players = room:getOtherPlayers(player)
    local targets = {}
    local choice = self.interaction.data
    for i = 1, #players, 1 do
      local real_i = i
      if choice == "xiaowu_clockwise" then
        real_i = #players + 1 - real_i
      end
      local temp = players[real_i]
      table.insert(targets, temp)
      if temp == target then break end
    end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    local x = 0
    local to_damage = {}
    for _, p in ipairs(targets) do
      if not p.dead and not player.dead then
        choice = room:askToChoice(p, {
          choices = {"xiaowu_draw1", "draw1"},
          skill_name = xiaowu.name,
          prompt = "#xiawu_draw:" .. player.id
        })
        if choice == "xiaowu_draw1" then
          player:drawCards(1, xiaowu.name)
          x = x + 1
        elseif choice == "draw1" then
          p:drawCards(1, xiaowu.name)
          table.insert(to_damage, p.id)
        end
      end
    end
    if not player.dead then
      if x > #to_damage then
        room:addPlayerMark(player, "@xiaowu_sand")
      elseif x < #to_damage then
        room:sortPlayersByAction(to_damage)
        for _, pid in ipairs(to_damage) do
          local p = room:getPlayerById(pid)
          if not p.dead then
            room:damage{ from = player, to = p, damage = 1, skillName = xiaowu.name }
          end
        end
      end
    end
  end,
})

return xiaowu
