local ty_ex__chunlao = fk.CreateSkill {
  name = "ty_ex__chunlao"
}

Fk:loadTranslationTable{
  ['ty_ex__chunlao'] = '醇醪',
  ['ty_ex__chengpu_chun'] = '醇',
  ['#ty_ex__chunlao-cost'] = '醇醪：你可以将任意张【杀】置为“醇”',
  ['#ty_ex__chunlao-invoke'] = '醇醪：你可以将一张“醇”置入弃牌堆，视为 %dest 使用一张【酒】',
  [':ty_ex__chunlao'] = '出牌阶段结束时，若你没有“醇”，你可以将任意张【杀】置为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”置入弃牌堆，视为该角色使用一张【酒】；若你此法置入弃牌堆的是：火【杀】，你回复1点体力；雷【杀】，你摸两张牌。',
  ['$ty_ex__chunlao1'] = '醉里披甲执坚，梦中杀敌破阵。',
  ['$ty_ex__chunlao2'] = '醇醪须与明君饮，沙场无还亦不悔。',
}

ty_ex__chunlao:addEffect(fk.EventPhaseEnd, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target == player and player.phase == Player.Play and #player:getPile("ty_ex__chengpu_chun") == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = #player.player_cards[Player.Hand],
      pattern = "slash",
      prompt = "#ty_ex__chunlao-cost"
    })
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:addToPile("ty_ex__chengpu_chun", event:getCostData(skill), true, skill.name)
  end,
})

ty_ex__chunlao:addEffect(fk.AskForPeaches, {
  global = false,
  can_trigger = function(self, event, target, player, data)
    return target.dying and #player:getPile("ty_ex__chengpu_chun") > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|ty_ex__chengpu_chun|.|.",
      prompt = "#ty_ex__chunlao-invoke::" .. target.id,
      expand_pile = "ty_ex__chengpu_chun"
    })
    if #cards > 0 then
      event:setCostData(skill, cards)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:moveCards({
      from = player.id,
      ids = event:getCostData(skill),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = skill.name,
      specialName = skill.name,
    })
    room:useCard({
      card = Fk:cloneCard("analeptic"),
      from = target.id,
      tos = {{target.id}},
      extra_data = {analepticRecover = true},
      skillName = skill.name,
    })
    if player.dead then return end
    local card_name = Fk:getCardById(event:getCostData(skill)[1]).name
    if card_name == "fire__slash" and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = skill.name
      })
    elseif card_name == "thunder__slash" then
      player:drawCards(2, skill.name)
    end
  end,
})

return ty_ex__chunlao
