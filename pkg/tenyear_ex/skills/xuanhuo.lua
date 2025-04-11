local xuanhuo = fk.CreateSkill {
  name = "ty_ex__xuanhuo",
}

Fk:loadTranslationTable{
  ["ty_ex__xuanhuo"] = "眩惑",
  [":ty_ex__xuanhuo"] = "摸牌阶段结束时，你可以交给一名其他角色两张手牌，并选择另一名其他角色，该角色选择一项：1.视为对后者使用"..
  "任意一种【杀】或【决斗】，2.交给你所有手牌。",

  ["#ty_ex__xuanhuo-invoke"] = "眩惑：选择两名角色，交给第一名角色两张手牌，其选择视为对第二名角色使用【杀】或【决斗】，或交给你所有手牌",
  ["#ty_ex__xuanhuo-use"] = "眩惑：视为对 %dest 使用【杀】或【决斗】，或点“取消”交给 %src 所有手牌",

  ["$ty_ex__xuanhuo1"] = "光以眩目，言以惑人。",
  ["$ty_ex__xuanhuo2"] = "我法孝直如何会害你？",
}

local U = require "packages/utility/utility"

xuanhuo:addEffect(fk.EventPhaseEnd, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xuanhuo.name) and player.phase == Player.Draw and
      player:getHandcardNum() > 1 and #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "ty_ex__xuanhuo_active",
      prompt = "#ty_ex__xuanhuo-invoke",
      cancelable = true
    })
    if success and dat then
      event:setCostData(self, { cards = dat.cards, tos = dat.targets })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    room:moveCardTo(event:getCostData(self).cards, Card.PlayerHand, to, fk.ReasonGive, xuanhuo.name, nil, false, player)
    if to.dead then return end
    local victim = event:getCostData(self).tos[2]
    if victim.dead then
      if not player.dead and not to:isKongcheng() then
        room:moveCardTo(to:getCardIds("h"), Card.PlayerHand, player, fk.ReasonGive, xuanhuo.name, nil, false, to)
        return
      end
    end
    if player:getMark(xuanhuo.name) == 0 then
      local cards = table.filter(U.prepareUniversalCards(room), function (id)
        return Fk:getCardById(id).trueName == "slash" or Fk:getCardById(id).name == "duel"
      end)
      room:setPlayerMark(player, xuanhuo.name, cards)
    end
    local cards = player:getMark(xuanhuo.name)
    local use = room:askToUseRealCard(to, {
      pattern = cards,
      skill_name = xuanhuo.name,
      prompt = "#ty_ex__xuanhuo-use:"..player.id..":"..victim.id,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
        expand_pile = cards,
        exclusive_targets = {victim.id},
      },
      cancelable = true,
      skip = true,
    })
    if use then
      local card = Fk:cloneCard(use.card.name)
      card.skillName = xuanhuo.name
      room:useCard{
        from = to,
        tos = use.tos,
        card = card,
        extraUse = true,
      }
    elseif not to:isKongcheng() then
      room:moveCardTo(to:getCardIds("h"), Card.PlayerHand, player, fk.ReasonGive, xuanhuo.name, nil, false, to)
    end
  end,
})

return xuanhuo
