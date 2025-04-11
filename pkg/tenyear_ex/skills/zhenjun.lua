local zhenjun = fk.CreateSkill {
  name = "ty_ex__zhenjun",
}

Fk:loadTranslationTable{
  ["ty_ex__zhenjun"] = "镇军",
  [":ty_ex__zhenjun"] = "准备阶段或结束阶段，你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1），若其中没有装备牌，你选择一项："..
  "1.弃置一张牌；2.该角色摸等量的牌。",

  ["#ty_ex__zhenjun-choose"] = "镇军：选择一名角色，弃置其手牌数减体力值张牌（至少一张）",
  ["#ty_ex__zhenjun-card"] = "镇军：弃置 %dest %arg张牌，若没有装备牌，你须弃牌或令其摸牌",
  ["#ty_ex__zhenjun-discard"] = "镇军：弃置一张牌，或点“取消” %dest 摸%arg张牌",

  ["$ty_ex__zhenjun1"] = "奉令无犯，当敌制决！",
  ["$ty_ex__zhenjun2"] = "质中性一，守执节义，自当无坚不陷。",
}

zhenjun:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhenjun.name) and
      (player.phase == Player.Start or player.phase == Player.Finish) and
      table.find(player.room.alive_players, function(p)
        return not p:isNude()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room.alive_players, function(p)
      return not p:isNude()
    end)
    if table.contains(targets, player) and
      not table.find(player:getCardIds("he"), function (id)
        return not player:prohibitDiscard(id)
      end) then
      table.removeOne(targets, player)
    end
    if #targets == 0 then
      room:askToCards(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = zhenjun.name,
        pattern = "false",
        prompt = "#ty_ex__zhenjun-choose",
        cancelable = true,
      })
    else
      local to = room:askToChoosePlayers(player, {
        min_num = 1,
        max_num = 1,
        targets = targets,
        skill_name = zhenjun.name,
        prompt = "#ty_ex__zhenjun-choose",
        cancelable = true,
      })
      if #to > 0 then
        event:setCostData(self, {tos = to})
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    local num = math.min(math.max(1, to:getHandcardNum() - to.hp), #to:getCardIds("he"))
    local cards
    if to == player then
      cards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = zhenjun.name,
        cancelable = false,
        prompt = "#ty_ex__zhenjun-card::"..to.id..":"..num,
        skip = true,
      })
    else
      cards = room:askToChooseCards(player, {
        target = to,
        min = num,
        max = num,
        flag = "he",
        skill_name = zhenjun.name,
        prompt = "#ty_ex__zhenjun-card::"..to.id..":"..num
      })
    end
    num = #cards
    room:throwCard(cards, zhenjun.name, to, player)
    if player.dead or to.dead or table.find(cards, function(id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end) then return end
    if player:isNude() or
      #room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = zhenjun.name,
        prompt = "#ty_ex__zhenjun-discard::"..to.id..":"..num,
      }) == 0 then
      to:drawCards(num, zhenjun.name)
    end
  end,
})

return zhenjun
