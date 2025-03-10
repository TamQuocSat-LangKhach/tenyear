local jianliang = fk.CreateSkill {
  name = "jianliang"
}

Fk:loadTranslationTable{
  ['jianliang'] = '简亮',
  ['#jianliang-invoke'] = '简亮：你可以令至多两名角色各摸一张牌',
  [':jianliang'] = '摸牌阶段开始时，若你的手牌数不为全场最多，你可以令至多两名角色各摸一张牌。',
  ['$jianliang1'] = '岂曰少衣食，与君共袍泽！',
  ['$jianliang2'] = '义士同心力，粮秣应期来！'
}

jianliang:addEffect(fk.EventPhaseStart, {
  global = false,
  can_trigger = function(self, event, target, player)
    return target == player and player:hasSkill(jianliang.name) and player.phase == Player.Draw and
      not table.every(player.room.alive_players, function(p) return player:getHandcardNum() >= p:getHandcardNum() end)
  end,
  on_cost = function(self, event, target, player)
    local tos = player.room:askToChoosePlayers(player, {
      targets = Util.map(player.room.alive_players, Util.IdMapper),
      min_num = 1,
      max_num = 2,
      prompt = "#jianliang-invoke",
      skill_name = jianliang.name,
      cancelable = true
    })
    if #tos > 0 then
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    for _, id in ipairs(event:getCostData(self)) do
      local p = room:getPlayerById(id)
      if not p.dead then
        p:drawCards(1, jianliang.name)
      end
    end
  end,
})

return jianliang
