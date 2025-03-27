local huiji = fk.CreateSkill {
  name = "huiji"
}

Fk:loadTranslationTable{
  ['huiji'] = '惠济',
  ['#huiji-active'] = '发动 惠济，选择一名角色',
  ['huiji_equip'] = '使用装备',
  [':huiji'] = '出牌阶段限一次，你可以令一名角色摸两张牌或使用牌堆中的一张随机装备牌。若其手牌数不小于存活角色数，其视为使用【五谷丰登】（改为从该角色的手牌中挑选）。',
  ['$huiji1'] = '云鬓释远，彩衣婀娜。',
  ['$huiji2'] = '明眸善睐，瑰姿艳逸。',
}

huiji:addEffect('active', {
  target_num = 1,
  card_num = 0,
  prompt = "#huiji-active",
  anim_type = "control",
  interaction = function()
    return UI.ComboBox{
      choices = {"draw2", "huiji_equip"}
    }
  end,
  can_use = function(self, player)
    return player:usedSkillTimes(huiji.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected, selected_cards)
    return #selected == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    if self.interaction.data == "draw2" then
      target:drawCards(2, huiji.name)
    else
      local cards = {}
      for i = 1, #room.draw_pile do
        local card = Fk:getCardById(room.draw_pile[i])
        if card.type == Card.TypeEquip and target:canUseTo(card, target) then
          table.insertIfNeed(cards, card)
        end
      end
      if #cards > 0 then
        room:useCard{
          from = target.id,
          card = cards[math.random(1, #cards)],
          tos = {{target.id}},
        }
      end
    end
    if target.dead or target:getHandcardNum() < #room.alive_players then return end
    local amazing_grace = Fk:cloneCard("amazing_grace")
    amazing_grace.skillName = huiji.name
    if target:prohibitUse(amazing_grace) or table.every(room.alive_players, function (p)
      return target:isProhibited(p, amazing_grace)
    end) then return end
    amazing_grace.skill = huiji__amazingGraceSkill
    room:askToAG(target, {
      id_list = {amazing_grace},
      skill_name = huiji.name,
    })
  end,
})

return huiji
