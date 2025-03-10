local lvxin = fk.CreateSkill {
  name = "lvxin"
}

Fk:loadTranslationTable{
  ['lvxin'] = '滤心',
  ['#lvxin'] = '滤心：你可交给其他角色手牌，令其摸牌或弃牌',
  ['lvxin_draw'] = '令其摸%arg张牌',
  ['lvxin_discard'] = '令其随机弃置%arg张手牌',
  ['@lvxinLoseHp'] = '滤心',
  ['lvxin_loseHp'] = '失去体力',
  ['@lvxinRecover'] = '滤心',
  ['lvxin_recover'] = '回复体力',
  ['#lvxin_delayed_effect'] = '滤心',
  [':lvxin'] = '出牌阶段限一次，你可以交给一名其他角色一张手牌，然后选择一项：1.令其摸X张牌；2.令其随机弃置X张手牌（X为游戏轮数且至多为5）。若其以此法摸到/弃置与你交给其的牌牌名相同的牌，则其下次发动技能时，其回复1点体力/失去1点体力。<br/><font color=><b>注</b>：请不要反馈此技能相关的任何问题。</font>',
  ['$lvxin1'] = '医病非难，难在医人之心。',
  ['$lvxin2'] = '知人者有验于天，知天者有验于人。',
}

-- Active Skill
lvxin:addEffect('active', {
  name = "lvxin",
  anim_type = "control",
  prompt = "#lvxin",
  card_num = 1,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(lvxin.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])

    room:obtainCard(target, effect.cards[1], false, fk.ReasonGive, player.id)
    local round = math.min(5, room:getBanner("RoundCount"))
    local choice = room:askToChoice(
      player,
      {
        choices = { "lvxin_draw:::" .. round, "lvxin_discard:::" .. round },
        skill_name = lvxin.name,
        prompt = "#lvxin-choose::" .. target.id
      }
    )
    if choice:startsWith("lvxin_discard") then
      local canDiscard = table.filter(target:getCardIds("h"), function(id) return not target:prohibitDiscard(id) end)
      if #canDiscard == 0 then
        return false
      end

      local toDiscard = canDiscard
      if #canDiscard > round then
        toDiscard = table.random(canDiscard, round)
      end

      local hasSameName = table.find(
        toDiscard,
        function(id)
          return Fk:getCardById(id).trueName == Fk:getCardById(effect.cards[1]).trueName
        end
      )
      room:throwCard(toDiscard, lvxin.name, target, target)
      if hasSameName then
        room:setPlayerMark(target, "@lvxinLoseHp", "lvxin_loseHp")
      end
    else
      local idsDrawn = target:drawCards(round, lvxin.name)
      if table.find(idsDrawn, function(id) return Fk:getCardById(id).trueName == Fk:getCardById(effect.cards[1]).trueName end) then
        room:setPlayerMark(target, "@lvxinRecover", "lvxin_recover")
      end
    end
  end,
})

-- Trigger Skill
lvxin:addEffect(fk.SkillEffect, {
  name = "#lvxin_delayed_effect",
  mute = true,
  can_trigger = function(self, _, target, player, data)
    return
      target == player and
      data.visible and
      target:hasSkill(data.name, true, true) and
      not table.contains({ "m_feiyang", "m_bahu" }, data.name) and
      (target:getMark("@lvxinLoseHp") ~= 0 or target:getMark("@lvxinRecover") ~= 0)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, _, target, player, data)
    local room = player.room
    local lvxinLoseHp = target:getMark("@lvxinLoseHp")
    local lvxinRecover = target:getMark("@lvxinRecover")
    room:setPlayerMark(target, "@lvxinLoseHp", 0)
    room:setPlayerMark(target, "@lvxinRecover", 0)
    if lvxinRecover ~= 0 then
      room:recover{
        who = target,
        num = 1,
        skillName = lvxin.name
      }
    end

    if lvxinLoseHp ~= 0 then
      room:loseHp(target, 1, lvxin.name)
    end
  end,
})

return lvxin
