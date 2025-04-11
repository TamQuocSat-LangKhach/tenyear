local ty_ex__xingxue = fk.CreateSkill {
  name = "ty_ex__xingxue"
}

Fk:loadTranslationTable{
  ['ty_ex__xingxue'] = '兴学',
  ['ty_ex__yanzhu'] = '宴诛',
  ['#ty_ex__xingxue-choose'] = '兴学：你可以令至多%arg名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶',
  ['#ty_ex__xingxue-card'] = '兴学：将一张牌置于牌堆顶',
  [':ty_ex__xingxue'] = '结束阶段，你可以令X名角色依次摸一张牌，然后其中手牌数量大于体力值的角色依次将一张牌置于牌堆顶（X为你的体力值）。',
  ['$ty_ex__xingxue1'] = '案古置学官，以敦王化，以隆风俗。',
  ['$ty_ex__xingxue2'] = '志善好学，未来可期！'
}

ty_ex__xingxue:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__xingxue.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    local n = player.hp
    if player:getMark("ty_ex__yanzhu") > 0 then
      n = player.maxHp
    end
    local tos = player.room:askToChoosePlayers(player, {
      targets = table.map(player.room:getAlivePlayers(), Util.IdMapper),
      min_num = 1,
      max_num = n,
      prompt = "#ty_ex__xingxue-choose:::"..n,
      skill_name = ty_ex__xingxue.name,
      cancelable = true
    })
    if #tos > 0 then
      player.room:sortPlayersByAction(tos)
      event:setCostData(self, tos)
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(event:getCostData(self)) do
      local to = room:getPlayerById(id)
      if not to.dead then
        to:drawCards(1, ty_ex__xingxue.name)
      end
    end
    for _, id in ipairs(event:getCostData(self)) do
      local to = room:getPlayerById(id)
      if to:getHandcardNum() > to.hp then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = ty_ex__xingxue.name,
          prompt = "#ty_ex__xingxue-card"
        })
        room:moveCards({
          ids = card,
          from = id,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = ty_ex__xingxue.name,
        })
      end
    end
  end,
})

return ty_ex__xingxue
