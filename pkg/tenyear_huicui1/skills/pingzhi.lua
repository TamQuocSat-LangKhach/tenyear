local pingzhi = fk.CreateSkill {
  name = "pingzhi"
}

Fk:loadTranslationTable{
  ['pingzhi'] = '评骘',
  ['#pingzhi-use'] = '评骘：请使用这张牌',
  [':pingzhi'] = '转换技，出牌阶段限一次，你可以观看一名角色手牌并选择其中一张牌令其展示，阳：你弃置此牌，其视为对你使用【火攻】，若未造成伤害此技能视为未发动；阴：其使用此牌，若造成伤害则此技能视为未发动。',
  ['$pingzhi1'] = '陈祗何许人也？我等当重其虚！',
  ['$pingzhi2'] = '这满朝朱紫，鲜有非酒囊饭袋之徒。',
}

pingzhi:addEffect('active', {
  switch_skill_name = "pingzhi",
  anim_type = "switch",
  card_num = 0,
  target_num = 1,
  prompt = function (self, player, selected_cards, selected_targets)
    return "#pingzhi-"..player:getSwitchSkillState(pingzhi.name, false, true)
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(pingzhi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local card
    local prompt = "#pingzhi_show-"..player:getSwitchSkillState(pingzhi.name, true, true).."::"..target.id
    if target == player then
      if player:getSwitchSkillState(pingzhi.name, true) == fk.SwitchYang then
        card = room:askToDiscard(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = pingzhi.name,
          cancelable = false,
          pattern = nil,
          prompt = prompt,
          skip = true,
        })
        if #card == 0 then return end
      else
        card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = pingzhi.name,
          cancelable = false,
          pattern = nil,
          prompt = prompt,
        })
      end
    else
      card = room:askToChooseCardsAndPlayers(player, {
        min_card_num = 1,
        max_card_num = 1,
        targets = target:getCardIds("h"),
        min_target_num = 0,
        max_target_num = 0,
        pattern = nil,
        prompt = prompt,
        skill_name = pingzhi.name,
      })
    end
    room:showCards(card, target)
    if player:getSwitchSkillState(pingzhi.name, true) == fk.SwitchYang then
      if not player:prohibitDiscard(card[1]) then
        room:throwCard(card, pingzhi.name, target, player)
        if not player.dead and not target.dead then
          local use = room:useVirtualCard("fire_attack", nil, target, player, pingzhi.name)
          if not (use and use.damageDealt) then
            player:setSkillUseHistory(pingzhi.name, 0, Player.HistoryPhase)
          end
        end
      end
    else
      card = Fk:getCardById(card[1])
      if target:canUse(card, {bypass_times = true}) and
        table.find(room.alive_players, function (p)
          return target:canUseTo(card, p, {bypass_times = true})
        end) then
        local use = room:askToUseRealCard(target, {
          pattern = {card.id},
          skill_name = pingzhi.name,
          prompt = "#pingzhi-use",
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
          cancelable = false,
          skip = false,
        })
        if use and use.damageDealt then
          player:setSkillUseHistory(pingzhi.name, 0, Player.HistoryPhase)
        end
      end
    end
  end,
})

return pingzhi
