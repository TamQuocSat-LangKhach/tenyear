local zhuangdan = fk.CreateSkill {
  name = "zhuangdan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['zhuangdan'] = '壮胆',
  ['liedan'] = '裂胆',
  ['@@zhuangdan'] = '裂胆失效',
  [':zhuangdan'] = '锁定技，其他角色的回合结束时，若你的手牌数为全场唯一最大，〖裂胆〗失效直到你的回合结束。',
  ['$zhuangdan1'] = '假丞相虎威，壮豪将龙胆。',
  ['$zhuangdan2'] = '我家丞相在此，哪个有胆敢动我？',
}

zhuangdan:addEffect(fk.TurnEnd, {
  anim_type = "special",
  
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(zhuangdan.name) and target ~= player and player:hasSkill("liedan") and
      table.every(player.room:getOtherPlayers(player), function(p)
        return player:getHandcardNum() > p:getHandcardNum()
      end)
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 1)
    player.room:invalidateSkill(player, "liedan")
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark("@@zhuangdan") > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "@@zhuangdan", 0)
    player.room:validateSkill(player, "liedan")
  end,
})

return zhuangdan
