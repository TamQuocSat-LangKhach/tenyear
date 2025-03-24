local zhiji = fk.CreateSkill {
  name = "zhijif",
}

Fk:loadTranslationTable{
  ["zhijif"] = "知机",
  [":zhijif"] = "准备阶段，你可以弃置任意张手牌（可以不弃），然后将手牌摸至5张。若你因此弃牌数比摸牌数：多，你可以对至多X名其他角色"..
  "各造成1点伤害（X为弃牌数比摸牌数多的数量）；相等，你本回合使用牌不能被响应；少，你本回合手牌上限+2。",

  ["#zhijif-invoke"] = "知机：你可以弃置任意张手牌，然后将手牌摸至5张，根据弃牌数和摸牌数执行效果",
  ["#zhijif-choose"] = "知机：你可以对至多%arg名其他角色各造成1点伤害",
  ["@@zhijif-turn"] = "知机 不可响应",

  ["$zhijif1"] = "筹谋部划，知天机，行人事。",
  ["$zhijif2"] = "渊孤军出寨，可一鼓击之。",
}

zhiji:addEffect(fk.EventPhaseStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhiji.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#zhijif-invoke",
      cancelable = true,
      extra_data = {
        num = 999,
        min_num = 0,
        include_equip = false,
        pattern = ".",
        skillName = zhiji.name,
      }
    })
    if success and dat then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = event:getCostData(self).cards
    if #cards > 0 then
      room:throwCard(cards, zhiji.name, player, player)
      if player.dead then return end
    end
    local n = 5 - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, zhiji.name)
      if player.dead then return end
    end
    n = #cards - math.max(n, 0)
    if n > 0 and #room:getOtherPlayers(player, false) > 0 then
      local tos = room:askToChoosePlayers(player, {
        skill_name = zhiji.name,
        min_num = 1,
        max_num = n,
        targets = room:getOtherPlayers(player, false),
        prompt = "#zhijif-choose:::"..n,
        cancelable = true,
      })
      if #tos > 0 then
        room:sortByAction(tos)
        for _, p in ipairs(tos) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = zhiji.name,
            }
          end
        end
      end
    elseif n == 0 then
      room:setPlayerMark(player, "@@zhijif-turn", 1)
    elseif n < 0 then
      room:addPlayerMark(player, MarkEnum.AddMaxCards.."-turn", 2)
    end
  end,
})

zhiji:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhijif-turn") > 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

return zhiji
