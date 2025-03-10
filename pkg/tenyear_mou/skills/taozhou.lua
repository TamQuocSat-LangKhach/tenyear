local taozhou = fk.CreateSkill {
  name = "taozhou"
}

Fk:loadTranslationTable{
  ['taozhou'] = '讨州',
  ['#taozhou-active'] = '发动 讨州，从1-3中选择一个数字并选择一名有手牌的其他角色',
  ['#taozhou-give'] = '讨州：你可以选择1-3张手牌交给 %src',
  ['@taozhou_damage'] = '讨州',
  ['zijin'] = '自矜',
  ['#taozhou_trigger'] = '讨州',
  [':taozhou'] = '出牌阶段，你可以选择一名有手牌的其他角色并从1-3中秘密选择一个数字，此技能失效至对应轮数后恢复，其可以将至多三张手牌交给你，若其以此法交给你的牌数：大于等于你选择的数字，你与其各摸一张牌；小于你选择的数字，其下X次受到的伤害+1（X为两者差值），若X大于1，其获得〖自矜〗。',
  ['$taozhou1'] = '皇叔借荆州久矣，谨特来讨要。',
  ['$taozhou2'] = '荆州弹丸之地，诸君岂可食言而肥？',
}

taozhou:addEffect('active', {
  anim_type = "control",
  prompt = "#taozhou-active",
  card_num = 0,
  target_num = 1,
  interaction = function()
    return UI.Spin {
      from = 1,
      to = 3,
    }
  end,
  can_use = function(self, player)
    return player:getMark(taozhou.name) == 0
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and not Fk:currentRoom():getPlayerById(to_select):isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = skill.interaction.data
    room:setPlayerMark(player, taozhou.name, n)
    room:invalidateSkill(player, taozhou.name)
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 3,
      pattern = ".|.|.|hand",
      prompt = "#taozhou-give:"..player.id,
      skill_name = taozhou.name
    })
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, taozhou.name, nil, false, player.id)
    end
    if #cards < n then
      if target.dead then return end
      n = n - #cards
      room:addPlayerMark(target, "@taozhou_damage", n)
      if n > 1 and not target.dead then
        room:handleAddLoseSkills(target, "zijin", nil)
      end
    else
      if not player.dead then
        player:drawCards(1, taozhou.name)
      end
      if not target.dead then
        target:drawCards(1, taozhou.name)
      end
    end
  end,
})

taozhou:addEffect(fk.DamageInflicted, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return player == target and player:getMark("@taozhou_damage") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@taozhou_damage", 1)
    data.damage = data.damage + 1
  end,

  can_refresh = function(self, event, target, player, data)
    if event == fk.EventLoseSkill and (player ~= target or data ~= taozhou) then return false end
    return player:getMark(taozhou.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventLoseSkill then
      room:setPlayerMark(player, taozhou.name, 0)
    else
      room:removePlayerMark(player, taozhou.name, 1)
      if player:getMark(taozhou.name) < 1 then
        room:validateSkill(player, taozhou.name)
      end
    end
  end,
})

return taozhou
