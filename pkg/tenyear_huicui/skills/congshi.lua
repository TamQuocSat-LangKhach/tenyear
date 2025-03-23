local congshi = fk.CreateSkill {
  name = "congshi"
}

Fk:loadTranslationTable{
  ['congshi'] = '从势',
  [':congshi'] = '锁定技，当一名角色使用一张装备牌结算结束后，若其装备区里的牌数为全场最多的，你摸一张牌。',
  ['$congshi1'] = '阁下奉天子以令诸侯，珪自当相从。',
  ['$congshi2'] = '将军率六师以伐不臣，珪何敢相抗？',
}

congshi:addEffect(fk.CardUseFinished, {
  global = true,
  can_trigger = function(self, event, target, player, data)
    return not target.dead and player:hasSkill(skill.name) and data.card.type == Card.TypeEquip and
      table.every(player.room.alive_players, function(p)
        return #target:getCardIds("e") >= #p:getCardIds("e")
      end)
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, congshi.name)
  end
})

return congshi
