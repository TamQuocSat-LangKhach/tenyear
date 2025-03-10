local huguan = fk.CreateSkill {
  name = "huguan"
}

Fk:loadTranslationTable{
  ['huguan'] = '护关',
  ['#huguan-invoke'] = '护关：你可以声明一种花色，令 %dest 本回合此花色牌不计入手牌上限',
  ['#huguan-choice'] = '护关：选择令 %dest 本回合不计入手牌上限的花色',
  ['@huguan-turn'] = '护关',
  [':huguan'] = '一名角色于其出牌阶段内使用第一张牌时，若为红色，你可以声明一个花色，本回合此花色的牌不计入其手牌上限。',
}

-- 主技能
huguan:addEffect(fk.CardUsing, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(huguan.name) and target.phase == Player.Play then
      local use_e = player.room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        return e.data[1].from == target.id
      end, Player.HistoryPhase)
      return #use_e > 0 and use_e[1].data[1] == data and data.card.color == Card.Red
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = huguan.name,
      prompt = "#huguan-invoke::"..target.id
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"log_spade", "log_heart", "log_club", "log_diamond"}
    local choices = table.map(suits, Util.TranslateMapper)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = huguan.name,
      prompt = "#huguan-choice::"..target.id
    })
    local mark = target:getMark("huguan-turn")
    if mark == 0 then mark = {} end
    table.insertIfNeed(mark, suits[table.indexOf(choices, choice)])
    room:setPlayerMark(target, "huguan-turn", mark)
    room:setPlayerMark(target, "@huguan-turn", table.concat(table.map(mark, Util.TranslateMapper)))
  end,
})

-- maxcards子技能
huguan:addEffect('maxcards', {
  exclude_from = function(self, player, card)
    return player:getMark("huguan-turn") ~= 0 and table.contains(player:getMark("huguan-turn"), card:getSuitString(true))
  end,
})

return huguan
