local lvxin = fk.CreateSkill {
  name = "lvxin",
}

Fk:loadTranslationTable{
  ["lvxin"] = "滤心",
  [":lvxin"] = "出牌阶段限一次，你可以交给一名其他角色一张手牌，然后选择一项：1.令其摸X张牌；2.令其随机弃置X张手牌（X为游戏轮数且至多为5）。"..
  "若其以此法摸到/弃置与你交给其的牌名相同的牌，则其下次发动技能时，其回复1点体力/失去1点体力。<br/>"..
  "<font color=><b>注</b>：请不要反馈此技能相关的任何问题</font>",

  ["#lvxin"] = "滤心：你可以交给一名角色一张牌，令其摸牌或弃牌",
  ["#lvxin-choice"] = "滤心：选择令 %dest 执行的一项",
  ["lvxin_draw"] = "摸%arg张牌，下次发动技能时可能回复体力",
  ["lvxin_discard"] = "随机弃置%arg张手牌，下次发动技能时可能失去体力",
  ["@@lvxin_loseHp"] = "滤心 失去体力",
  ["@@lvxin_recover"] = "滤心 回复体力",

  ["$lvxin1"] = "医病非难，难在医人之心。",
  ["$lvxin2"] = "知人者有验于天，知天者有验于人。",
}

lvxin:addEffect("active", {
  anim_type = "control",
  prompt = "#lvxin",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lvxin.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and table.contains(player:getCardIds("h"), to_select)
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]

    room:obtainCard(target, effect.cards, false, fk.ReasonGive, player, lvxin.name)
    local num = math.min(5, room:getBanner("RoundCount"))
    local choice = room:askToChoice(player, {
      choices = { "lvxin_draw:::" .. num, "lvxin_discard:::" .. num },
      skill_name = lvxin.name,
      prompt = "#lvxin-choice::" .. target.id,
    })
    if choice:startsWith("lvxin_discard") then
      local cards = table.filter(target:getCardIds("h"), function(id) return not target:prohibitDiscard(id) end)
      if #cards == 0 then return end
      cards = table.random(cards, num)

      local yes = table.find(cards, function(id)
        return Fk:getCardById(id).trueName == Fk:getCardById(effect.cards[1]).trueName
      end)
      room:throwCard(cards, lvxin.name, target, target)
      if yes and not target.dead then
        room:setPlayerMark(target, "@@lvxin_loseHp", 1)
      end
    else
      local cards = target:drawCards(num, lvxin.name)
      if table.find(cards, function(id)
        return Fk:getCardById(id).trueName == Fk:getCardById(effect.cards[1]).trueName
      end) and not target.dead then
        room:setPlayerMark(target, "@@lvxin_recover", 1)
      end
    end
  end,
})

lvxin:addEffect(fk.SkillEffect, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and
      data.skill:isPlayerSkill(target) and target:hasSkill(data.skill:getSkeleton().name, true, true) and
      (target:getMark("@@lvxin_loseHp") ~= 0 or target:getMark("@@lvxin_recover") ~= 0)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if target:getMark("@@lvxin_recover") > 0 then
      room:setPlayerMark(target, "@lvxin_recover", 0)
      room:recover{
        who = target,
        num = 1,
        skillName = lvxin.name,
      }
    end
    if target:getMark("@@lvxin_loseHp") > 0 then
      room:setPlayerMark(target, "@lvxin_loseHp", 0)
      room:loseHp(target, 1, lvxin.name)
    end
  end,
})

return lvxin
