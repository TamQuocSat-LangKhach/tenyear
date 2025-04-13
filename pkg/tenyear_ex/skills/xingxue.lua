local xingxue = fk.CreateSkill {
  name = "ty_ex__xingxue",
  dynamic_desc = function (self, player)
    if player:getMark("ty_ex__yanzhu") > 0 then
      return "ty_ex__xingxue_update"
    end
  end,
}

Fk:loadTranslationTable{
  ["ty_ex__xingxue"] = "兴学",
  [":ty_ex__xingxue"] = "结束阶段，你可以令至多X名角色依次摸一张牌，然后其中手牌数大于体力值的角色依次将一张牌置于牌堆顶（X为你的体力值）。",

  [":ty_ex__xingxue_update"] = "结束阶段，你可以令至多X名角色依次摸一张牌，然后其中手牌数大于体力值的角色依次将一张牌置于牌堆顶"..
  "（X为你的体力上限）。",

  ["#ty_ex__xingxue-choose"] = "兴学：令至多%arg名角色依次摸一张牌，然后手牌数大于体力值的角色依次将一张牌置于牌堆顶",
  ["#ty_ex__xingxue-card"] = "兴学：将一张牌置于牌堆顶",

  ["$ty_ex__xingxue1"] = "案古置学官，以敦王化，以隆风俗。",
  ["$ty_ex__xingxue2"] = "志善好学，未来可期！"
}

xingxue:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xingxue.name) and player.phase == Player.Finish and
      (player:getMark("ty_ex__yanzhu") > 0 or player.hp > 0)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = player:getMark("ty_ex__yanzhu") == 0 and player.hp or player.maxHp
    local tos = room:askToChoosePlayers(player, {
      skill_name = xingxue.name,
      min_num = 1,
      max_num = n,
      targets = room.alive_players,
      prompt = "#ty_ex__xingxue-choose:::"..n,
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
    local targets = table.simpleClone(event:getCostData(self).tos)
    for _, to in ipairs(targets) do
      if not to.dead then
        to:drawCards(1, xingxue.name)
      end
    end
    for _, to in ipairs(targets) do
      if not to.dead and to:getHandcardNum() > to.hp then
        local card = room:askToCards(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          prompt = "#ty_ex__xingxue-card",
          skill_name = xingxue.name,
          cancelable = false,
        })
        room:moveCards({
          ids = card,
          from = to,
          toArea = Card.DrawPile,
          moveReason = fk.ReasonJustMove,
          skillName = xingxue.name,
        })
      end
    end
  end,
})

return xingxue
