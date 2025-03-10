local xiaoyan = fk.CreateSkill {
  name = "xiaoyan"
}

Fk:loadTranslationTable{
  ['xiaoyan'] = '硝焰',
  ['#xiaoyan-give'] = '硝焰：你可以选择一张牌交给%src来回复1点体力',
  [':xiaoyan'] = '游戏开始时，所有其他角色各受到你造成的1点火焰伤害，然后这些角色可以依次交给你一张牌并回复1点体力。',
  ['$xiaoyan1'] = '万军付薪柴，戾火燃苍穹。',
  ['$xiaoyan2'] = '九州硝烟起，烽火灼铁衣。',
}

xiaoyan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(xiaoyan.name)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local targets = room:getOtherPlayers(player)
    if #targets == 0 then return false end
    room:doIndicate(player.id, table.map(targets, Util.IdMapper))
    for _, p in ipairs(targets) do
      if not p.dead then
        room:damage{
          from = player,
          to = p,
          damage = 1,
          damageType = fk.FireDamage,
          skillName = xiaoyan.name,
        }
      end
    end
    for _, p in ipairs(targets) do
      if player.dead then break end
      if not p.dead then
        local card = room:askToCards(p, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = xiaoyan.name,
          cancelable = true,
          prompt = "#xiaoyan-give:"..player.id,
        })
        if #card > 0 then
          room:moveCardTo(card, Card.PlayerHand, player, fk.ReasonGive, xiaoyan.name, nil, false, p.id)
          if not p.dead and p:isWounded() then
            room:recover{
              who = p,
              num = 1,
              recoverBy = player,
              skillName = xiaoyan.name,
            }
          end
        end
      end
    end
  end,
})

return xiaoyan
