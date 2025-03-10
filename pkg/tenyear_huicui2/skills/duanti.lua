local duanti = fk.CreateSkill {
  name = "duanti"
}

Fk:loadTranslationTable{
  ['duanti'] = '锻体',
  ['@duanti'] = '锻体',
  [':duanti'] = '锁定技，当你每使用或打出五张牌结算结束后，你回复1点体力，加1点体力上限（最多加5）。',
  ['$duanti1'] = '流水不腐，户枢不蠹。',
  ['$duanti2'] = '五禽锻体，百病不侵。',
}

duanti:addEffect(fk.CardUseFinished, {
  global = false,
  can_trigger = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@duanti") < 4 then
      room:addPlayerMark(player, "@duanti")
      return false
    else
      room:setPlayerMark(player, "@duanti", 0)
    end
    if player:isWounded() then
      room:recover{
        who = player,
        recoverBy = player,
        num = 1,
        skillName = duanti.name
      }
      if player.dead then return false end
    end
    if player:getMark("duanti_addmaxhp") < 5 then
      room:addPlayerMark(player, "duanti_addmaxhp")
      room:changeMaxHp(player, 1)
    end
  end,
})

duanti:addEffect(fk.EventLoseSkill, {
  can_refresh = function(self, event, target, player, data)
    return player == target and data == duanti
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@duanti", 0)
    player.room:setPlayerMark(player, "duanti_addmaxhp", 0)
  end,
})

return duanti
