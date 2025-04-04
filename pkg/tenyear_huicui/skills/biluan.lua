local biluan = fk.CreateSkill {
  name = "ty__biluan",
}

Fk:loadTranslationTable{
  ["ty__biluan"] = "避乱",
  [":ty__biluan"] = "结束阶段，若有其他角色计算与你的距离为1，你可以弃置一张牌，令其他角色计算与你的距离+X（X为全场角色数且至多为4）。",

  ["#ty__biluan-invoke"] = "避乱：你可以弃一张牌，令其他角色计算与你距离+%arg",
  ["@ty__shixie_distance"] = "距离",

  ["$ty__biluan1"] = "天下攘攮，难觅避乱之地。",
  ["$ty__biluan2"] = "乱世纷扰，唯避居，方为良策。",
}

biluan:addEffect(fk.EventPhaseStart, {
  anim_type = "defensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(biluan.name) and player.phase == Player.Finish and
      table.find(player.room:getOtherPlayers(player, false), function(p)
        return p:distanceTo(player) == 1
      end)
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local x = math.min(4, #room.alive_players)
    local card = room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = biluan.name,
      cancelable = true,
      prompt = "#ty__biluan-invoke:::"..x,
      skip = true,
    })
    if #card > 0 then
      event:setCostData(self, {cards = card})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:throwCard(event:getCostData(self).cards, biluan.name, player, player)
    if player.dead then return end
    local x = math.min(4, #player.room.alive_players)
    local num = tonumber(player:getMark("@ty__shixie_distance")) + x
    room:setPlayerMark(player,"@ty__shixie_distance", num > 0 and "+"..num or num)
  end,
})

biluan:addEffect("distance", {
  correct_func = function(self, from, to)
    local num = tonumber(to:getMark("@ty__shixie_distance"))
    if num > 0 then
      return num
    end
  end,
})

return biluan
