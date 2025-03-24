local dangchen = fk.CreateSkill {
  name = "dangchen",
}

Fk:loadTranslationTable{
  ["dangchen"] = "荡尘",
  [":dangchen"] = "出牌阶段开始时，你可以令一名其他角色交给你至少一张牌，然后你可以弃置等量的牌，若你弃置了牌，本阶段【杀】或普通锦囊牌指定"..
  "其为目标后，你可以进行判定，若判定结果点数为X的倍数，此牌额外结算一次效果。（X为弃牌数）",

  ["#dangchen-choose"] = "荡尘：你可以令一名角色交给你至少一张牌",
  ["#dangchen-give"] = "荡尘：请交给 %src 至少一张牌",
  ["#dangchen-discard"] = "荡尘：你可以弃置%arg张牌，令你本阶段对 %dest 使用的【杀】或普通锦囊牌可能额外结算一次",
  ["@dangchen-phase"] = "荡尘",
  ["#dangchen-invoke"] = "荡尘：是否进行判定？若为%arg的倍数，此%arg2额外结算一次",

  ["$dangchen1"] = "举帆据徐塘，寒夜荡敌尘！",
  ["$dangchen2"] = "无恃敌之不至，恃吾有以胜之！",
}

dangchen:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(dangchen.name) and player.phase == Player.Play and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function(p)
      return not p:isNude()
    end)
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = targets,
      skill_name = dangchen.name,
      prompt = "#dangchen-choose",
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
    local cards = room:askToCards(to, {
      min_num = 1,
      max_num = 999,
      include_equip = true,
      skill_name = dangchen.name,
      prompt = "#dangchen-give:"..player.id,
      cancelable = false,
    })
    room:moveCardTo(cards, Card.PlayerHand, player, fk.ReasonGive, self.name, nil, false, to)
    if not player.dead and not player:isNude() then
      cards = room:askToDiscard(player, {
        min_num = #cards,
        max_num = #cards,
        include_equip = true,
        skill_name = dangchen.name,
        prompt = "#dangchen-discard::"..to.id..":"..#cards,
        cancelable = true,
      })
      if #cards > 0 and not player.dead and not to.dead then
        room:setPlayerMark(to, "@dangchen-phase", #cards)
      end
    end
  end,
})
dangchen:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(dangchen.name, Player.HistoryPhase) > 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data.to:getMark("@dangchen-phase") > 0 and not player.dead
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = dangchen.name,
      prompt = "#dangchen-invoke:::"..data.to:getMark("@dangchen-phase")..":"..data.card:toLogString(),
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local numbers = {}
    for i = 1, 13, 1 do
      if i % data.to:getMark("@dangchen-phase") == 0 then
        table.insert(numbers, tostring(i))
      end
    end
    local judge = {
      who = player,
      reason = dangchen.name,
      pattern = ".|"..table.concat(numbers, ","),
    }
    room:judge(judge)
    if judge.card:matchPattern(judge.pattern) then
      data.use.additionalEffect = (data.use.additionalEffect or 0) + 1
    end
  end,
})

return dangchen
