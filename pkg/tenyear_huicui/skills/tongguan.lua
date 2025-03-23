local tongguan = fk.CreateSkill {
  name = "tongguan"
}

Fk:loadTranslationTable{
  ['tongguan'] = '统观',
  ['#tongguan-choice'] = '统观：为 %dest 选择一项属性（每种属性至多被选择两次）',
  [':tongguan'] = '一名角色的第一个回合开始时，你为其选择一项属性（每种属性至多被选择两次）。',
  ['$tongguan1'] = '极目宇宙，可观如织之命数。',
  ['$tongguan2'] = '命河长往，唯我立于川上。',
}

tongguan:addEffect(fk.TurnStart, {
  anim_type = "special",
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(tongguan.name) and target:getMark("tongguan_info") == 0 then
      local events = player.room.logic:getEventsOfScope(GameEvent.Turn, 1, function(e)
        return e.data[1] == target
      end, Player.HistoryGame)
      return #events > 0 and events[1] == player.room.logic:getCurrentEvent()
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local record = room:getTag("tongguan_record") or {2, 2, 2, 2, 2}
    local choices = {}
    for i = 1, 5 do
      if record[i] > 0 then
        table.insert(choices, tg_list[i])
      end
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = tongguan.name,
      prompt = "#tongguan-choice::" .. target.id,
      detailed = true
    })
    room:setPlayerMark(target, "tongguan_info", choice)
    local i = table.indexOf(tg_list, choice)
    record[i] = record[i] - 1
    room:setTag("tongguan_record", record)
    U.setPrivateMark(target, ":tongguan", {choice}, {player.id})
  end,
})

return tongguan
