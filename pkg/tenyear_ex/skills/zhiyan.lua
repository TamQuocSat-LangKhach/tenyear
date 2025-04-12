local zhiyan = fk.CreateSkill {
  name = "ty_ex__zhiyan",
}

Fk:loadTranslationTable{
  ["ty_ex__zhiyan"] = "直言",
  [":ty_ex__zhiyan"] = "结束阶段，你可以令一名角色摸一张牌并展示之，若此牌为：基本牌，你摸一张牌；装备牌，其使用此牌并回复1点体力。",

  ["#ty_ex__zhiyan-choose"] = "直言：你可以令一名角色摸一张牌并展示之",

  ["$ty_ex__zhiyan1"] = "此事，臣有一言要讲。",
  ["$ty_ex__zhiyan2"] = "还望将军听我一言。",
}

zhiyan:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiyan.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      skill_name = zhiyan.name,
      min_num = 1,
      max_num = 1,
      targets = room.alive_players,
      prompt = "#ty_ex__zhiyan-choose",
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local cards = to:drawCards(1, zhiyan.name)
    if #cards == 0 then return end
    local id = cards[1]
    if not table.contains(to:getCardIds("h"), id) then return end
    to:showCards(id)
    room:delay(1000)
    local card = Fk:getCardById(id)
    if card.type == Card.TypeEquip then
      if not table.contains(to:getCardIds("h"), id) or to.dead then return end
      if to:canUseTo(card, to) then
        room:useCard{
          from = to,
          tos = {to},
          card = card,
        }
        if to:isWounded() and not to.dead then
          room:recover{
            who = to,
            num = 1,
            recoverBy = player,
            skillName = zhiyan.name,
          }
        end
      end
    elseif card.type == Card.TypeBasic and not player.dead then
      player:drawCards(1, zhiyan.name)
    end
  end,
})

return zhiyan
