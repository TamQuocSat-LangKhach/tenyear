local faqi = fk.CreateSkill {
  name = "faqi"
}

Fk:loadTranslationTable{
  ['faqi'] = '法器',
  ['faqi_viewas'] = '法器',
  ['#faqi-invoke'] = '法器：你可以视为使用一张普通锦囊牌',
  [':faqi'] = '出牌阶段，当你使用装备牌后，你可以视为使用一张普通锦囊牌（每回合每种牌名限一次）。',
  ['$faqi1'] = '脚踏风火轮，金印翻天，剑辟阴阳！',
  ['$faqi2'] = '手执火尖枪，红绫混天，乾坤难困我！',
}

faqi:addEffect(fk.CardUseFinished, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(faqi.name) 
      and player.phase == Player.Play and data.card.type == Card.TypeEquip
  end,
  on_cost = function(self, event, target, player, data)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "faqi_viewas",
      prompt = "#faqi-invoke",
      cancelable = true
    })
    if success then
      event:setCostData(self, dat)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = table.simpleClone(event:getCostData(self))
    local card_name = dat.interaction
    local card = Fk:cloneCard(card_name)
    card.skillName = faqi.name
    room:addTableMark(player, "faqi-turn", card_name)
    room:useCard{
      from = player.id,
      tos = table.map(dat.targets, function(id) return {id} end),
      card = card,
    }
  end,
})

return faqi
