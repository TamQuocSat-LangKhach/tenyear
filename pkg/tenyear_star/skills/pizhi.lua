local pizhi = fk.CreateSkill {
  name = "pizhi"
}

Fk:loadTranslationTable{
  ['pizhi'] = '圮秩',
  ['@canxi1-round'] = '「妄生」',
  ['@canxi2-round'] = '「向死」',
  ['@canxi_exist_kingdoms'] = '',
  [':pizhi'] = '锁定技，结束阶段，你摸X张牌；有角色死亡时，若其势力与当前生效的“玺角”势力相同或是该势力最后一名角色，你失去此“玺角”，然后摸X张牌并回复1点体力（X为你已失去的“玺角”数）。',
  ['$pizhi1'] = '春秋无义，秉笔汗青者，胜者尔。',
  ['$pizhi2'] = '大厦将倾，居危墙之下者，愚夫尔。',
}

pizhi:addEffect(fk.EventPhaseEnd, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(pizhi.name) then
      return target == player and player.phase == Player.Finish and player:getMark("canxi_removed_kingdoms") > 0
    end
  end,
  on_use = function (self, event, target, player, data)
    local room = player.room
    player:drawCards(player:getMark("canxi_removed_kingdoms"), pizhi.name)
  end,
})

pizhi:addEffect(fk.Death, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(pizhi.name) then
      return player:getMark("@canxi1-round") == target.kingdom or player:getMark("@canxi2-round") == target.kingdom or
        (not table.find(player.room.alive_players, function(p)
          return p.kingdom == target.kingdom
        end) and table.contains(player:getTableMark("@canxi_exist_kingdoms"), target.kingdom))
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@canxi1-round") == target.kingdom then
      room:setPlayerMark(player, "@canxi1-round", 0)
    end
    if player:getMark("@canxi2-round") == target.kingdom then
      room:setPlayerMark(player, "@canxi2-round", 0)
    end
    local mark = player:getTableMark("@canxi_exist_kingdoms")
    if table.removeOne(mark, target.kingdom) then
      room:setPlayerMark(player, "@canxi_exist_kingdoms", #mark > 0 and mark or 0)
      room:addPlayerMark(player, "canxi_removed_kingdoms")
    end
    player:drawCards(player:getMark("canxi_removed_kingdoms"), pizhi.name)
    if not player.dead and player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = pizhi.name
      })
    end
  end,
})

return pizhi
