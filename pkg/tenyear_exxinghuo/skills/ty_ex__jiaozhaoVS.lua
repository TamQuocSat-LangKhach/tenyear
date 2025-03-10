local ty_ex__jiaozhao = fk.CreateSkill {
  name = "ty_ex__jiaozhao"
}

Fk:loadTranslationTable{
  ['ty_ex__jiaozhao&'] = '矫诏',
  ['#ty_ex__jiaozhaoVS'] = '矫诏：你可以将“矫诏”牌当本回合被声明的牌使用',
  ['ty_ex__jiaozhao'] = '矫诏',
  ['@ty_ex__jiaozhao'] = '矫诏',
  [':ty_ex__jiaozhao&'] = '你可以将“矫诏”牌当本回合被声明的牌使用。',
}

ty_ex__jiaozhao:addEffect('viewas', {
  pattern = ".",
  mute = true,
  prompt = "#ty_ex__jiaozhaoVS",
  card_filter = function(self, player, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select):getMark("ty_ex__jiaozhao-inhand") ~= 0
  end,
  view_as = function(self, player, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard(Fk:getCardById(cards[1]):getMark("ty_ex__jiaozhao-inhand"))
    card.skillName = ty_ex__jiaozhao.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function(self, player, use)
    player:broadcastSkillInvoke(ty_ex__jiaozhao.name)
  end,
  enabled_at_play = function(self, player)
    return table.find(player:getCardIds("h"), function(id) return Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand") ~= 0 end)
  end,
  enabled_at_response = function(self, player, response)
    if not response and not player:isKongcheng() and Fk.currentResponsePattern then
      local cards = {}
      for _, id in ipairs(player.player_cards[Player.Hand]) do
        local name = Fk:getCardById(id):getMark("ty_ex__jiaozhao-inhand")
        if name ~= 0 then
          local c = Fk:cloneCard(name)
          c:addSubcard(id)
          table.insert(cards, c)
        end
      end
      return table.find(cards, function(c) return Exppattern:Parse(Fk.currentResponsePattern):match(c) end)
    end
  end,
})

ty_ex__jiaozhao:addEffect('prohibit', {
  is_prohibited = function(self, player, from, to, card)
    return card and from == to and table.contains(card.skillNames, ty_ex__jiaozhao.name) and from:getMark("@" .. ty_ex__jiaozhao.name) < 2
  end,
})

return ty_ex__jiaozhao
