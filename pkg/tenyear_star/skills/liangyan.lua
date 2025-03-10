local liangyan = fk.CreateSkill {
  name = "liangyan"
}

Fk:loadTranslationTable{
  ['liangyan'] = '梁燕',
  ['liangyan_discard'] = '弃置至多两张牌',
  ['#liangyan1-active'] = '发动 梁燕，弃置1-2张牌，令一名其他角色摸等量的牌',
  ['#liangyan2-active'] = '发动 梁燕，摸1-2张牌，令一名其他角色弃置等量的牌',
  ['@@liangyan'] = '梁燕',
  ['#liangyan_delay'] = '梁燕',
  [':liangyan'] = '出牌阶段限一次，你可以选择一名其他角色并选择：1.你摸一至两张牌，其弃置等量的牌，若你与其手牌数相同，你跳过下个弃牌阶段；2.你弃置一至两张牌，其摸等量的牌，若你与其手牌数相同，其跳过下个弃牌阶段。',
  ['$liangyan1'] = '家燕并头语，不恋雕梁而归于万里。',
  ['$liangyan2'] = '灵禽非醴泉不饮，非积善之家不栖。',
}

liangyan:addEffect('active', {
  target_num = 1,
  min_card_num = 0,
  max_card_num = 2,
  prompt = function(self, player, selected_cards, selected_targets)
    if self.interaction.data == "liangyan_discard" then
      return "#liangyan1-active"
    else
      return "#liangyan2-active"
    end
  end,
  interaction = function()
    return UI.ComboBox {
      choices = {"draw2", "draw1", "liangyan_discard"}
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(liangyan.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, player, to_select, selected)
    return self.interaction.data == "liangyan_discard" and #selected < 2 and not player:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= player.id and (#selected_cards > 0 or self.interaction.data ~= "liangyan_discard")
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local n = #effect.cards
    if n > 0 then
      room:throwCard(effect.cards, liangyan.name, player, player)
      if target.dead then return end
      target:drawCards(n, liangyan.name)
      if not (player.dead or target.dead) and player:getHandcardNum() == target:getHandcardNum() then
        room:setPlayerMark(target, "@@liangyan", 1)
      end
    else
      n = 1
      if self.interaction.data == "draw2" then
        n = 2
      end
      player:drawCards(n, liangyan.name)
      if target.dead then return end
      room:askToDiscard(target, {
        min_num = n,
        max_num = n,
        include_equip = true,
        skill_name = liangyan.name,
        cancelable = false,
      })
      if not (player.dead or target.dead) and player:getHandcardNum() == target:getHandcardNum() then
        room:setPlayerMark(player, "@@liangyan", 1)
      end
    end
  end,
})

liangyan:addEffect(fk.EventPhaseChanging, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@liangyan") > 0 and data.to == Player.Discard
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@liangyan", 0)
    player:skip(Player.Discard)
    return true
  end,
})

return liangyan
