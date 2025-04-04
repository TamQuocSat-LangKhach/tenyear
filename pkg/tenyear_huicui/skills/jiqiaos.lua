local jiqiaos = fk.CreateSkill {
  name = "jiqiaos",
}

Fk:loadTranslationTable{
  ["jiqiaos"] = "激峭",
  [":jiqiaos"] = "出牌阶段开始时，你可以将牌堆顶X张牌置于武将牌上（X为你的体力上限）；当你使用一张牌结算结束后，若你的武将牌上"..
  "有“激峭”牌，你获得其中一张，然后若剩余其中两种颜色牌的数量相等，你回复1点体力，否则你失去1点体力；出牌阶段结束时，移去所有“激峭”牌。",

  ["#jiqiaos-ask"] = "激峭：获得一张“激峭”牌，若剩余牌红色等于黑色你回复体力，否则失去体力",

  ["$jiqiaos1"] = "为将者，当躬冒矢石！",
  ["$jiqiaos2"] = "吾承父兄之志，危又何惧？",
}

jiqiaos:addEffect(fk.EventPhaseStart, {
  derived_piles = "jiqiaos",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jiqiaos.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(jiqiaos.name, player.room:getNCards(player.maxHp), true, jiqiaos.name)
  end,
})

jiqiaos:addEffect(fk.CardUseFinished, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    return target == player and #player:getPile(jiqiaos.name) > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = player:getPile(jiqiaos.name)
    if #cards > 1 then
      cards = room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = jiqiaos.name,
        pattern = ".|.|.|jiqiaos",
        prompt = "#jiqiaos-ask",
        cancelable = false,
        expand_pile = jiqiaos.name,
      })
    end
    room:obtainCard(player, cards, true, fk.ReasonJustMove, player, jiqiaos.name)
    if player.dead then return end
    local red = #table.filter(player:getPile(jiqiaos.name), function (id)
      return Fk:getCardById(id, true).color == Card.Red
    end)
    local black = #table.filter(player:getPile(jiqiaos.name), function (id)
      return Fk:getCardById(id, true).color == Card.Black
    end)
    if red == black then
      if player:isWounded() then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = jiqiaos.name,
        }
      end
    else
      room:loseHp(player, 1, jiqiaos.name)
    end
  end,
})

jiqiaos:addEffect(fk.EventPhaseEnd, {
  mute = true,
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
      return target == player and #player:getPile(jiqiaos.name) > 0 and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    player.room:moveCards({
      from = player,
      ids = player:getPile(jiqiaos.name),
      toArea = Card.DiscardPile,
      moveReason = fk.ReasonPutIntoDiscardPile,
      skillName = jiqiaos.name,
    })
  end,
})

return jiqiaos
