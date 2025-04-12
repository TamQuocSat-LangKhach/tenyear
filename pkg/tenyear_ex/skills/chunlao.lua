local chunlao = fk.CreateSkill {
  name = "ty_ex__chunlao",
}

Fk:loadTranslationTable{
  ["ty_ex__chunlao"] = "醇醪",
  [":ty_ex__chunlao"] = "出牌阶段结束时，若你没有“醇”，你可以将任意张【杀】置为“醇”；当一名角色处于濒死状态时，你可以将一张“醇”"..
  "置入弃牌堆，视为该角色使用一张【酒】；若你此法置入弃牌堆的是：火【杀】，你回复1点体力；雷【杀】，你摸两张牌。",

  ["ty_ex__chengpu_chun"] = "醇",
  ["#ty_ex__chunlao-ask"] = "醇醪：你可以将任意张【杀】置为“醇”",
  ["#ty_ex__chunlao-invoke"] = "醇醪：你可以将一张“醇”置入弃牌堆，视为 %dest 使用一张【酒】",

  ["$ty_ex__chunlao1"] = "醉里披甲执坚，梦中杀敌破阵。",
  ["$ty_ex__chunlao2"] = "醇醪须与明君饮，沙场无还亦不悔。",
}

chunlao:addEffect(fk.EventPhaseEnd, {
  derived_piles = "ty_ex__chengpu_chun",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(chunlao.name) and player.phase == Player.Play and
      #player:getPile("ty_ex__chengpu_chun") == 0 and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      skill_name = chunlao.name,
      min_num = 1,
      max_num = 999,
      pattern = "slash",
      prompt = "#ty_ex__chunlao-ask",
    })
    if #cards > 0 then
      event:setCostData(self, {cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local cards = event:getCostData(self).cards
    player:addToPile("ty_ex__chengpu_chun", cards, true, chunlao.name)
  end,
})

chunlao:addEffect(fk.AskForPeaches, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chunlao.name) and #player:getPile("ty_ex__chengpu_chun") > 0 and
      target.dying and target:canUseTo(Fk:cloneCard("analeptic"), target)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local cards = room:askToCards(player, {
      skill_name = chunlao.name,
      min_num = 1,
      max_num = 1,
      pattern = ".|.|.|ty_ex__chengpu_chun",
      prompt = "#ty_ex__chunlao-invoke::"..target.id,
      expand_pile = "ty_ex__chengpu_chun",
    })
    if #cards > 0 then
      event:setCostData(self, {tos = {target}, cards = cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    room:moveCardTo(cards, Card.DiscardPile, nil, fk.ReasonPutIntoDiscardPile, chunlao.name, nil, true, player)
    if not target.dead then
      local analeptic = Fk:cloneCard("analeptic")
      analeptic.skillName = chunlao.name
      if target:canUseTo(analeptic, target) then
        room:useCard({
          from = target,
          tos = {target},
          card = analeptic,
          extra_data = {
            analepticRecover = true,
          },
        })
      end
    end
    if player.dead then return end
    local name = Fk:getCardById(cards[1]).name
    if name == "fire__slash" and player:isWounded() then
      room:recover{
        who = player,
        num = 1,
        recoverBy = player,
        skillName = chunlao.name,
      }
    elseif name == "thunder__slash" then
      player:drawCards(2, chunlao.name)
    end
  end,
})

return chunlao
