local ty__yongjue = fk.CreateSkill {
  name = "ty__yongjue"
}

Fk:loadTranslationTable{
  ['ty__yongjue'] = '勇决',
  ['#ty__yongjue-invoke'] = '勇决：你可以令此%arg不计入使用次数，或获得之',
  ['ty__yongjue_time'] = '不计入次数',
  ['ty__yongjue_obtain'] = '获得之',
  [':ty__yongjue'] = '当你于出牌阶段内使用第一张【杀】时，你可以令其不计入使用次数或获得之。',
  ['$ty__yongjue1'] = '能救一个是一个！',
  ['$ty__yongjue2'] = '扶幼主，成霸业！',
}

ty__yongjue:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__yongjue.name) and player.phase == Player.Play and data.card.trueName == "slash" and
      player:usedCardTimes("slash", Player.HistoryPhase) == 1 and player:usedSkillTimes(ty__yongjue.name, Player.HistoryPhase) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty__yongjue.name,
      prompt = "#ty__yongjue-invoke:::" .. data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choices = {"ty__yongjue_time"}
    if room:getCardArea(data.card) == Card.Processing then
      table.insert(choices, "ty__yongjue_obtain")
    end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = ty__yongjue.name
    })
    if choice == "ty__yongjue_time" then
      player:addCardUseHistory(data.card.trueName, -1)
    else
      room:obtainCard(player, data.card, true, fk.ReasonJustMove)
    end
  end,
})

return ty__yongjue
