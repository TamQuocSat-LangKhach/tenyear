local ty_ex__zhenjun = fk.CreateSkill {
  name = "ty_ex__zhenjun"
}

Fk:loadTranslationTable{
  ['ty_ex__zhenjun'] = '镇军',
  ['#ty_ex__zhenjun-choose'] = '镇军：选择一名角色，弃置其X张牌（X为其手牌数减体力值且至少为1）',
  ['#ty_ex__zhenjun-card'] = '镇军：弃置 %dest %arg张牌，若没有装备牌，你须弃牌或令其摸牌',
  ['#ty_ex__zhenjun-discard'] = '镇军：你须弃置一张牌，否则  %dest 摸 %arg 张牌',
  [':ty_ex__zhenjun'] = '准备阶段或结束阶段，你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1），若其中没有装备牌，你选择一项：1.你弃置一张牌；2.该角色摸等量的牌。',
  ['$ty_ex__zhenjun1'] = '奉令无犯，当敌制决！',
  ['$ty_ex__zhenjun2'] = '质中性一，守执节义，自当无坚不陷。',
}

ty_ex__zhenjun:addEffect(fk.EventPhaseStart, {
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__zhenjun) and (player.phase == Player.Start or player.phase == Player.Finish)
  end,
  on_cost = function(self, event, target, player, data)
    local targets = table.filter(player.room.alive_players, function(p) return not p:isNude() end)
    if #targets == 0 then return false end
    local tos = player.room:askToChoosePlayers(player, {
      targets = targets,
      min_num = 1,
      max_num = 1,
      skill_name = ty_ex__zhenjun.name,
      prompt = "#ty_ex__zhenjun-choose",
    })
    if #tos > 0 then
      event:setCostData(self, tos[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    local num = math.min(math.max(1, to:getHandcardNum() - to.hp), #to:getCardIds("he"))
    local cards = room:askToChooseCards(player, {
      target = to,
      min = num,
      max = num,
      flag = "he",
      skill_name = ty_ex__zhenjun.name,
      prompt = "#ty_ex__zhenjun-card::"..to.id..":"..num
    })
    room:throwCard(cards, ty_ex__zhenjun.name, to, player)
    if player.dead or to.dead or table.find(cards, function(id) return Fk:getCardById(id).type == Card.TypeEquip end) then return end
    if not player:isNude() then
      local discards = room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = ty_ex__zhenjun.name,
        prompt = "#ty_ex__zhenjun-discard::"..to.id..":"..num
      })
      if #discards > 0 then return end
    end
    to:drawCards(num, ty_ex__zhenjun.name)
  end,
})

return ty_ex__zhenjun
