local taozhou = fk.CreateSkill {
  name = "taozhou",
}

Fk:loadTranslationTable{
  ["taozhou"] = "讨州",
  [":taozhou"] = "出牌阶段，你可以选择一名有手牌的其他角色并从1~3中秘密选择一个数字，此技能失效至对应轮数后恢复，其可以交给你至多三张手牌，"..
  "若其以此法交给你的牌数：<br>不小于你选择的数字，你与其各摸一张牌；<br>小于你选择的数字，其下X次受到的伤害+1（X为两者差值），若X大于1，"..
  "其获得〖自矜〗。",

  ["#taozhou"] = "讨州：选择1~3的数字并选择一名其他角色，根据其交给你牌数和你选择数字之差执行效果",
  ["#taozhou-give"] = "讨州：选择1~3张手牌交给 %src，根据交出牌数和其选择数字之差执行效果",
  ["@taozhou_damage"] = "讨州",

  ["$taozhou1"] = "皇叔借荆州久矣，谨特来讨要。",
  ["$taozhou2"] = "荆州弹丸之地，诸君岂可食言而肥？",
}

taozhou:addEffect("active", {
  anim_type = "control",
  prompt = "#taozhou",
  card_num = 0,
  target_num = 1,
  interaction = UI.Spin { from = 1, to = 3, },
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player and not to_select:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = effect.from
    local target = effect.tos[1]
    local n = self.interaction.data
    room:setPlayerMark(player, taozhou.name, n)
    room:invalidateSkill(player, taozhou.name)
    local cards = room:askToCards(target, {
      min_num = 1,
      max_num = 3,
      include_equip = false,
      prompt = "#taozhou-give:"..player.id,
      skill_name = taozhou.name,
    })
    if #cards > 0 then
      room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, taozhou.name, nil, false, player)
    end
    if #cards < n then
      if target.dead then return end
      n = n - #cards
      room:addPlayerMark(target, "@taozhou_damage", n)
      if n > 1 and not target.dead then
        room:handleAddLoseSkills(target, "zijin")
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
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@taozhou_damage") > 0
  end,
  on_use = function(self, event, target, player, data)
    player.room:removePlayerMark(player, "@taozhou_damage", 1)
    data:changeDamage(1)
  end,
})

taozhou:addEffect(fk.RoundEnd, {
  can_refresh = function(self, event, target, player, data)
    return player:getMark(taozhou.name) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:removePlayerMark(player, taozhou.name, 1)
    if player:getMark(taozhou.name) == 0 then
      room:validateSkill(player, taozhou.name)
    end
  end,
})

taozhou:addLoseEffect(function (self, player, is_death)
  if player:getMark(taozhou.name) > 0 then
    local room = player.room
    room:validateSkill(player, taozhou.name)
    room:setPlayerMark(player, taozhou.name, 0)
  end
end)

return taozhou
