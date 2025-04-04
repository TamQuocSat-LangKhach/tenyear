local zixi = fk.CreateSkill {
  name = "zixi",
}

Fk:loadTranslationTable{
  ["zixi"] = "姊希",
  [":zixi"] = "出牌阶段开始时和结束时，你可以将一张“琴”置入一名角色的判定区。当你使用基本牌或普通锦囊牌指定唯一目标后，你可以根据"..
  "其判定区牌的张数执行效果：1张，此牌对其额外结算1次；2张，你摸两张牌；3张，弃置其判定区所有牌，对其造成3点伤害。",

  ["#zixi-choose"] = "姊希：你可以将一张“琴”置入一名角色的判定区",
  ["#zixi-invoke1"] = "姊希：你可以令%arg对 %dest 额外结算一次",
  ["#zixi-invoke2"] = "姊希：你可以摸两张牌",
  ["#zixi-invoke3"] = "姊希：你可以弃置 %dest 判定区所有牌并对其造成3点伤害！",

  ["$zixi1"] = "日暮飞伯劳，倦梳头，坐看鸥鹭争舟。",
  ["$zixi2"] = "姊折翠柳寄江北，念君心悠悠。",
}

local spec = {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zixi.name) and player.phase == Player.Play and
      not player:isKongcheng() and
      table.find(player.room.alive_players, function (p)
        return not table.contains(p.sealedSlots, Player.JudgeSlot) and #p:getCardIds("j") < 3
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local ids = table.filter(player:getCardIds("h"), function (id)
      return Fk:getCardById(id):getMark("@@qiqin-inhand") > 0
    end)
    local targets = table.filter(room.alive_players, function (p)
      return not table.contains(p.sealedSlots, Player.JudgeSlot) and #p:getCardIds("j") < 3
    end)
    local to, cards = room:askToChooseCardsAndPlayers(player, {
      min_card_num = 1,
      max_card_num = 1,
      min_num = 1,
      max_num = 1,
      targets = targets,
      pattern = tostring(Exppattern{ id = ids }),
      skill_name = zixi.name,
      prompt = "#zixi-choose",
      cancelable = true,
    })
    if #to > 0 and #cards > 0 then
      event:setCostData(self, {tos = to, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local card = Fk:cloneCard("zixi_trick")
    card:addSubcards(event:getCostData(self).cards)
    target:addVirtualEquip(card)
    room:moveCardTo(card, Player.Judge, to, fk.ReasonJustMove, zixi.name, nil, true, player)
  end,
}

zixi:addEffect(fk.EventPhaseStart, spec)
zixi:addEffect(fk.EventPhaseEnd, spec)

zixi:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zixi.name) and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) and
      not table.contains(data.card.skillNames, zixi.name) and
      data:isOnlyTarget(data.to) and #data.to:getCardIds("j") > 0 and #data.to:getCardIds("j") < 4
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = zixi.name,
      prompt = "#zixi-invoke"..#data.to:getCardIds("j").."::"..data.to.id..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = #data.to:getCardIds("j")
    if x == 1 then
      data.extra_data = data.extra_data or {}
      data.extra_data.zixi = {
        from = player,
        to = data.to,
        subTos = data.use.subTos,
      }
    elseif x == 2 then
      room:drawCards(player, 2, zixi.name)
    elseif x == 3 then
      data.to:throwAllCards("j", zixi.name)
      if not data.to.dead then
        room:damage{
          from = player,
          to = data.to,
          damage = 3,
          skillName = zixi.name,
        }
      end
    end
  end,
})

zixi:addEffect(fk.CardUseFinished, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if data.extra_data and data.extra_data.zixi and not player.dead then
      local use = table.simpleClone(data.extra_data.zixi)
      if use.from == player then
        local card = Fk:cloneCard(data.card.name)
        card.skillName = zixi.name
        if player:prohibitUse(card) then return end
        use.card = card
        if not use.to.dead and not player:isProhibited(use.to, card) then
          return true
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local use = table.simpleClone(data.extra_data.zixi)
    local card = Fk:cloneCard(data.card.name)
    card.skillName = zixi.name
    room:useCard{
      from = player,
      tos = {use.to},
      card = card,
      extraUse = true,
      subTos = use.subTos,
    }
  end,
})

zixi:addEffect(fk.EventPhaseProceeding, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasDelayedTrick("zixi_trick") and player.phase == Player.Judge
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    local cards = table.filter(player:getCardIds(Player.Judge), function (id)
      return not (player:getVirualEquip(id) and player:getVirualEquip(id).name == "zixi_trick")
    end)
    while #cards > 0 do
      if data.phase_end then break end
      local cid = table.remove(cards)
      if not cid then return end
      local card = player:removeVirtualEquip(cid)
      if not card then
        card = Fk:getCardById(cid)
      end
      if table.contains(player:getCardIds(Player.Judge), cid) then
        room:moveCardTo(card, Card.Processing, nil, fk.ReasonPut, "phase_judge")

        local effect_data = CardEffectData:new {
          card = card,
          to = player,
          tos = { player },
        }
        room:doCardEffect(effect_data)
        if effect_data.isCancellOut and card.skill then
          card.skill:onNullified(room, effect_data)
        end
      end
    end
    data.phase_end = true
  end,
})

return zixi
