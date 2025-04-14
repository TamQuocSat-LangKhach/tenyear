local pingzhi = fk.CreateSkill {
  name = "pingzhi",
  tags = { Skill.Switch },
}

Fk:loadTranslationTable{
  ["pingzhi"] = "评骘",
  [":pingzhi"] = "转换技，出牌阶段限一次，你可以观看一名角色手牌并选择其中一张牌令其展示，阳：你弃置此牌，其视为对你使用【火攻】，"..
  "若未造成伤害此技能视为未发动；阴：其使用此牌，若造成伤害则此技能视为未发动。",

  ["#pingzhi-yang"] = "评骘：观看并选择一名角色一张手牌，你弃置之，其视为对你使用【火攻】",
  ["#pingzhi-yin"] = "评骘：观看并选择一名角色一张手牌，其使用之",
  ["#pingzhi_show-yang"] = "评骘：弃置 %dest 的一张手牌，其视为对你使用【火攻】",
  ["#pingzhi_show-yin"] = "评骘：选择 %dest 的一张手牌，其使用之",
  ["#pingzhi-use"] = "评骘：请使用这张牌",

  ["$pingzhi1"] = "陈祗何许人也？我等当重其虚！",
  ["$pingzhi2"] = "这满朝朱紫，鲜有非酒囊饭袋之徒。",
}

pingzhi:addEffect("active", {
  anim_type = "switch",
  prompt = function (self, player, selected_cards, selected_targets)
    return "#pingzhi-"..player:getSwitchSkillState(pingzhi.name, false, true)
  end,
  card_num = 0,
  target_num = 1,
  can_use = function(self, player)
    return player:usedSkillTimes(pingzhi.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected == 0 and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
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
        card = card[1]
      else
        card = room:askToCards(player, {
          min_num = 1,
          max_num = 1,
          include_equip = false,
          skill_name = pingzhi.name,
          cancelable = false,
          prompt = prompt,
        })
        card = card[1]
      end
    else
      card = room:askToChooseCard(player, {
        target = target,
        flag = { card_data = {{ target.general, target:getCardIds("h") }} },
        skill_name = pingzhi.name,
        prompt = prompt,
      })
    end
    target:showCards(card)
    if player:getSwitchSkillState(pingzhi.name, true) == fk.SwitchYang then
      if not player:prohibitDiscard(card) then
        room:throwCard(card, pingzhi.name, target, player)
        if not player.dead and not target.dead then
          local use = room:useVirtualCard("fire_attack", nil, target, player, pingzhi.name)
          if not (use and use.damageDealt) then
            player:setSkillUseHistory(pingzhi.name, 0, Player.HistoryPhase)
          end
        end
      end
    else
      card = Fk:getCardById(card)
      if #card:getDefaultTarget(target, {bypass_times = true}) > 0 then
        local use = room:askToUseRealCard(target, {
          pattern = {card.id},
          skill_name = pingzhi.name,
          prompt = "#pingzhi-use",
          extra_data = {
            bypass_times = true,
            extraUse = true,
          },
          cancelable = false,
        })
        if use and use.damageDealt then
          player:setSkillUseHistory(pingzhi.name, 0, Player.HistoryPhase)
        end
      end
    end
  end,
})

return pingzhi
