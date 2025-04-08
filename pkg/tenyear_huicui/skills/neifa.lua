local neifa = fk.CreateSkill{
  name = "ty__neifa",
}

Fk:loadTranslationTable{
  ["ty__neifa"] = "内伐",
  [":ty__neifa"] = "出牌阶段开始时，你可以摸三张牌，然后弃置一张牌。若弃置的牌：是基本牌，你本回合不能使用锦囊牌，"..
  "本阶段使用【杀】次数上限+X，目标上限+1；锦囊牌，你本回合不能使用基本牌，使用普通锦囊牌的目标+1或-1"..
  "（X为发动技能时手牌中因本技能不能使用的牌且至多为5）。",

  ["#ty__neifa-discard"] = "内伐：请弃置一张牌：若弃基本牌，你不能使用锦囊牌；若弃锦囊牌，你不能使用基本牌",
  ["@ty__neifa-turn"] = "内伐",
  ["#ty__neifa_trigger-choose"] = "内伐：你可以为%arg增加/减少1个目标",

  ["$ty__neifa1"] = "同室操戈，胜者王、败者寇。",
  ["$ty__neifa2"] = "兄弟无能，吾当继袁氏大统。",
}

neifa:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(neifa.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(3, neifa.name)
    if player.dead or player:isNude() then return end
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = neifa.name,
      prompt = "#ty__neifa-discard",
      cancelable = false,
      skip = true,
    })
    local type = Fk:getCardById(card[1]).type
    room:throwCard(card, neifa.name, player, player)
    if player.dead then return end
    local list = {}
    if type == Card.TypeBasic then
      local cards = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).type == Card.TypeTrick
      end)
      list = {"basic_char", math.min(#cards, 5)}
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-phase", math.min(#cards, 5))
    elseif type == Card.TypeTrick then
      local cards = table.filter(player:getCardIds("h"), function(id)
        return Fk:getCardById(id).type == Card.TypeBasic
      end)
      list = {"trick_char", math.min(#cards, 5)}
    end
    local mark = player:getTableMark("@ty__neifa-turn")
    if mark[1] == list[1] then
      mark[2] = list[2]
    else
      table.insertTable(mark, list)
    end
    room:setPlayerMark(player, "@ty__neifa-turn", mark)
  end,
})

neifa:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local mark = player:getTableMark("@ty__neifa-turn")
      if #mark == 0 then return false end
      if data.card:isCommonTrick() and table.contains(mark, "trick_char") then
        local targets = data:getExtraTargets()
        if #data.tos > 1 then
          table.insertTable(targets, data.tos)
        end
        if #targets > 0 then
          event:setCostData(self, {tos = targets})
          return true
        end
      elseif data.card.trueName == "slash" and table.contains(mark, "basic_char") then
        local targets = data:getExtraTargets()
        if #targets > 0 then
          event:setCostData(self, {tos = targets})
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      min_num = 1,
      max_num = 1,
      targets = event:getCostData(self).tos,
      skill_name = neifa.name,
      prompt = "#ty__neifa_trigger-choose:::"..data.card:toLogString(),
      cancelable = true,
      extra_data = table.map(data.tos, Util.IdMapper),
      target_tip_name = "addandcanceltarget_tip",
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if table.contains(data.tos, to) then
      data:removeTarget(to)
      room:sendLog{
        type = "#RemoveTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = neifa.name,
        arg2 = data.card:toLogString(),
      }
    else
      data:addTarget(to)
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = neifa.name,
        arg2 = data.card:toLogString(),
      }
    end
  end,
})

neifa:addEffect("prohibit", {
  prohibit_use = function(self, player, card)
    if player:getMark("@ty__neifa-turn") ~= 0 and card then
      local mark = player:getTableMark("@ty__neifa-turn")
      if card.type == Card.TypeBasic then
        return table.contains(mark, "trick_char")
      elseif card.type == Card.TypeTrick then
        return table.contains(mark, "basic_char")
      end
    end
  end,
})

return neifa
