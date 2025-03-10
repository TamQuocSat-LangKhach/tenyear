local xiongmang = fk.CreateSkill {
  name = "xiongmang"
}

Fk:loadTranslationTable{
  ['xiongmang'] = '雄莽',
  [':xiongmang'] = '你可以将任意张花色不同的手牌当【杀】使用，此【杀】目标数上限等于用于转化的牌数。此【杀】结算结束后，若此【杀】：未造成伤害，你减1点体力上限；造成伤害，此阶段你使用【杀】的次数上限+1。',
  ['$xiongmang1'] = '力逮千军，唯武为雄！',
  ['$xiongmang2'] = '莽行沙场，乱世称雄！',
}

xiongmang:addEffect('viewas', {
  anim_type = "offensive",
  pattern = "slash",
  card_filter = function(self, player, to_select, selected)
    if Fk:currentRoom():getCardArea(to_select) == Player.Equip then return end
    if #selected == 0 then
      return true
    else
      return table.every(selected, function (id) return Fk:getCardById(to_select).suit ~= Fk:getCardById(id).suit end)
    end
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = xiongmang.name
    card:addSubcards(cards)
    return card
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

xiongmang:addEffect(fk.CardUseFinished, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      table.contains(data.card.skillNames, xiongmang.name) and
      player:isAlive()
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if data.damageDealt then
      room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase")
    else
      room:changeMaxHp(player, -1)
    end
  end,
})

xiongmang:addEffect('targetmod', {
  extra_target_func = function(self, player, skill, card)
    if player:hasSkill(xiongmang) and skill.trueName == "slash_skill" and table.contains(card.skillNames, xiongmang.name) then
      return #card.subcards - 1
    end
  end,
})

return xiongmang
