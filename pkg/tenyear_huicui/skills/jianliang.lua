local jianliang = fk.CreateSkill {
  name = "jianliang",
}

Fk:loadTranslationTable{
  ["jianliang"] = "简亮",
  [":jianliang"] = "摸牌阶段开始时，若你的手牌数不为全场最多，你可以令至多两名角色各摸一张牌。",

  ["#jianliang-choose"] = "简亮：你可以令至多两名角色各摸一张牌",

  ["$jianliang1"] = "岂曰少衣食，与君共袍泽！",
  ["$jianliang2"] = "义士同心力，粮秣应期来！"
}

jianliang:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jianliang.name) and player.phase == Player.Draw and
      table.find(player.room.alive_players, function(p)
        return player:getHandcardNum() < p:getHandcardNum()
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos = room:askToChoosePlayers(player, {
      targets = room.alive_players,
      min_num = 1,
      max_num = 2,
      prompt = "#jianliang-choose",
      skill_name = jianliang.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(event:getCostData(self).tos) do
      if not p.dead then
        p:drawCards(1, jianliang.name)
      end
    end
  end,
})

return jianliang
