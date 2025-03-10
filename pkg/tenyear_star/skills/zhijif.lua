local zhijif = fk.CreateSkill {
  name = "zhijif"
}

Fk:loadTranslationTable{
  ['zhijif'] = '知机',
  ['#zhijif-invoke'] = '知机：你可以弃置任意张手牌，然后将手牌摸至5张，根据弃牌数和摸牌数执行效果',
  ['#zhijif-choose'] = '知机：你可以对至多%arg名其他角色各造成1点伤害',
  ['@@zhijif-turn'] = '知机 不可响应',
  [':zhijif'] = '准备阶段，你可以弃置任意张手牌（可以不弃），然后将手牌摸至5张。若你因此弃牌数比摸牌数：多，你可以对至多X名其他角色各造成1点伤害（X为弃牌数比摸牌数多的数量）；相等，你本回合使用牌不能被响应；少，你本回合手牌上限+2。',
  ['$zhijif1'] = '筹谋部划，知天机，行人事。',
  ['$zhijif2'] = '渊孤军出寨，可一鼓击之。',
}

zhijif:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(zhijif.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player)
    local success, dat = player.room:askToUseActiveSkill(player, {
      skill_name = "discard_skill",
      prompt = "#zhijif-invoke",
      cancelable = true,
      extra_data = {
        num = 999,
        min_num = 0,
        include_equip = false,
        pattern = ".",
        skillName = zhijif.name
      }
    })
    if success then
      event:setCostData(self, {cards = dat.cards})
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    local cost_data = event:getCostData(self)
    if #cost_data.cards > 0 then
      room:throwCard(cost_data.cards, zhijif.name, player, player)
    end
    if player.dead then return end
    local n = 5 - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, zhijif.name)
    end
    if player.dead then return end
    n = #cost_data.cards - math.max(n, 0)
    if n > 0 then
      local targets = room:askToChoosePlayers(player, {
        targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        min_num = 1,
        max_num = n,
        prompt = "#zhijif-choose:::"..n,
        skill_name = zhijif.name
      })
      if #targets > 0 then
        room:sortPlayersByAction(targets)
        for _, p in ipairs(targets) do
          if not p.dead then
            room:damage{
              from = player,
              to = p,
              damage = 1,
              skillName = zhijif.name,
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

zhijif:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhijif-turn") > 0 and
      (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
  end,
})

return zhijif
