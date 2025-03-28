local yirang = fk.CreateSkill{
  name = "ty__yirang",
}

Fk:loadTranslationTable{
  ["ty__yirang"] = "揖让",
  [":ty__yirang"] = "出牌阶段开始时，你可以将所有非基本牌（至少一张）交给一名其他角色。若其体力上限大于你，你将体力上限增加至与该角色相同，"..
  "然后你回复X点体力（X为你以此法交给其的牌数）。",

  ["#ty__yirang-choose"] = "揖让：你可以将所有非基本牌交给一名角色，将体力上限增至与其相同并回复体力",

  ["$ty__yirang1"] = "百万黎庶，尽嘱明公！",
  ["$ty__yirang2"] = "徐州之主，舍君其谁！",
}

yirang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yirang.name) and player.phase == Player.Play and
      not player:isNude() and
      #player.room:getOtherPlayers(player, false) > 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if not table.find(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end) then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = yirang.name,
        pattern = "false",
        prompt = "#ty__yirang-choose",
        cancelable = true,
      })
      return
    end
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = room:getOtherPlayers(player, false),
      skill_name = yirang.name,
      prompt = "#ty__yirang-choose",
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
    local cards = table.filter(player:getCardIds("he"), function (id)
      return Fk:getCardById(id).type ~= Card.TypeBasic
    end)
    room:obtainCard(to, cards, false, fk.ReasonGive, player, yirang.name)
    if player.dead or to.maxHp <= player.maxHp then return end
    room:changeMaxHp(player, to.maxHp - player.maxHp)
    if not player.dead and player:isWounded() then
      room:recover {
        num = #cards,
        who = player,
        recoverBy = player,
        skillName = yirang.name,
      }
    end
  end,
})

return yirang
