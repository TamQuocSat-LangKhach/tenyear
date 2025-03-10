local ty__biluan = fk.CreateSkill {
  name = "ty__biluan"
}

Fk:loadTranslationTable{
  ['ty__biluan'] = '避乱',
  ['#ty__biluan-invoke'] = '避乱：你可弃一张牌，令其他角色计算与你距离+%arg',
  ['@ty__shixie_distance'] = '距离',
  [':ty__biluan'] = '结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为全场角色数且至多为4）。',
  ['$ty__biluan1'] = '天下攘攮，难觅避乱之地。',
  ['$ty__biluan2'] = '乱世纷扰，唯避居，方为良策。',
}

ty__biluan:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player)
    if target == player and player:hasSkill(ty__biluan) and player.phase == Player.Finish then
      return table.find(player.room:getOtherPlayers(player), function(p) return p:distanceTo(player) == 1 end)
    end
  end,
  on_cost = function (self, event, target, player)
    local x = math.min(4, #player.room.alive_players)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = ty__biluan.name,
      cancelable = true,
      prompt = "#ty__biluan-invoke:::"..x
    })
    if #card > 0 then
      event:setCostData(self, card)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:throwCard(event:getCostData(self), ty__biluan.name, player, player)
    local x = math.min(4, #player.room.alive_players)
    local num = tonumber(player:getMark("@ty__shixie_distance")) + x
    room:setPlayerMark(player,"@ty__shixie_distance",num > 0 and "+"..num or num)
  end,
})

local ty__biluan_distance = fk.CreateSkill {
  name = "#ty__biluan_distance"
}

ty__biluan_distance:addEffect('distance', {
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num > 0 then
      return num
    end
  end,
})

return ty__biluan
