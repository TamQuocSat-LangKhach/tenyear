local yanzhengn = fk.CreateSkill {
  name = "yanzhengn"
}

Fk:loadTranslationTable{
  ['yanzhengn'] = '言政',
  ['#yanzhengn-invoke'] = '言政：你可以选择保留一张手牌，弃置其余的手牌，对至多%arg名角色各造成1点伤害',
  [':yanzhengn'] = '准备阶段，若你的手牌数大于1，你可以选择一张手牌并弃置其余的牌，然后对至多等于弃置牌数的角色各造成1点伤害。',
}

yanzhengn:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(yanzhengn.name) and player.phase == Player.Start and player:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player)
    local targets = table.map(player.room.alive_players, Util.IdMapper)
    local tos, card = player.room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      targets = targets,
      min_target_num = 0,
      max_target_num = player:getHandcardNum() - 1,
      pattern = ".|.|.|hand",
      prompt = "#yanzhengn-invoke:::"..(player:getHandcardNum() - 1),
      skill_name = yanzhengn.name,
      cancelable = true
    })
    if #tos > 0 and card then
      player.room:sortPlayersByAction(tos)
      event:setCostData(self, {tos, card})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local ids = player:getCardIds("h")
    table.removeOne(ids, event:getCostData(self)[2])
    room:throwCard(ids, yanzhengn.name, player, player)
    for _, id in ipairs(event:getCostData(self)[1]) do
      local p = room:getPlayerById(id)
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          skillName = yanzhengn.name,
        }
      end
    end
  end,
})

return yanzhengn
