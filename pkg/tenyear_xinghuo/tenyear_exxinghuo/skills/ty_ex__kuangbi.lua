local ty_ex__kuangbi = fk.CreateSkill {
  name = "ty_ex__kuangbi"
}

Fk:loadTranslationTable{
  ['ty_ex__kuangbi'] = '匡弼',
  ['#ty_ex__kuangbi-choose'] = '匡弼：你可以令一名其他角色将一至三张牌置于你的武将牌上',
  ['#ty_ex__kuangbi-card'] = '匡弼：将一至三张牌置为 %src 的“匡弼”牌',
  [':ty_ex__kuangbi'] = '出牌阶段开始时，你可以令一名其他角色将一至三张牌置于你的武将牌上，本阶段结束时将“匡弼”牌置入弃牌堆。当你于有“匡弼”牌时使用牌时，若你：有与之花色相同的“匡弼”牌，则随机将其中一张置入弃牌堆，然后你与该角色各摸一张牌；没有与之花色相同的“匡弼”牌，则随机将一张置入弃牌堆，然后你摸一张牌。',
  ['$ty_ex__kuangbi1'] = '江东多娇，士当弼国以全方圆。',
  ['$ty_ex__kuangbi2'] = '吴垒锦绣，卿当匡佐使延万年。',
}

ty_ex__kuangbi:addEffect(fk.EventPhaseStart, {
  derived_piles = "ty_ex__kuangbi",
  can_trigger = function(self, event, target, player, data)
    return target:hasSkill(ty_ex__kuangbi.name) and target.phase == Player.Play
  end,
  on_cost = function (self, event, target, player, data)
    local room = target.room
    local targets = table.filter(room:getOtherPlayers(target), function(p) return not p:isNude() end)
    if #targets > 0 then
      local tos = room:askToChoosePlayers(target, {
        min_num = 1,
        max_num = 1,
        prompt = "#ty_ex__kuangbi-choose",
        skill_name = ty_ex__kuangbi.name,
        cancelable = true,
        targets = targets
      })
      if #tos > 0 then
        event:setCostData(skill, tos[1])
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = target.room
    local to = room:getPlayerById(event:getCostData(skill))
    local cards = room:askToDiscard(to, {
      min_num = 1,
      max_num = 3,
      include_equip = true,
      skill_name = ty_ex__kuangbi.name,
      cancelable = false,
      prompt = "#ty_ex__kuangbi-card:"..target.id
    })
    room:setPlayerMark(target, ty_ex__kuangbi.name, to.id)
    target:addToPile(ty_ex__kuangbi.name, cards, true, ty_ex__kuangbi.name, to.id)
  end,
})

ty_ex__kuangbi:addEffect(fk.CardUsing, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return #target:getPile("ty_ex__kuangbi") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = target.room
    if event == fk.CardUsing then
      local cards = target:getPile("ty_ex__kuangbi")
      local ids = table.filter(cards, function(id) return Fk:getCardById(id).suit == data.card.suit end)
      local throw = #ids > 0 and table.random(ids) or table.random(cards)
      room:moveCards({ids = {throw}, from = target.id ,toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
      if not target.dead then
        target:drawCards(1, ty_ex__kuangbi.name)
      end
      if #ids == 0 then return end
      local to = room:getPlayerById(target:getMark(ty_ex__kuangbi.name))
      if to and not to.dead then
        room:doIndicate(target.id, {to.id})
        to:drawCards(1, ty_ex__kuangbi.name)
      end
    else
      room:moveCards({ids = target:getPile("ty_ex__kuangbi"), from = target.id, toArea = Card.DiscardPile, moveReason = fk.ReasonPutIntoDiscardPile })
    end
  end,
})

return ty_ex__kuangbi
