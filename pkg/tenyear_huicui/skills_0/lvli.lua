local lvli = fk.CreateSkill {
  name = "lvli"
}

Fk:loadTranslationTable{
  ['lvli'] = '膂力',
  ['choujue'] = '仇决',
  ['beishui'] = '背水',
  [':lvli'] = '每名角色的回合限一次，当你造成伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。',
  ['$lvli1'] = '此击若中，万念俱灰！',
  ['$lvli2'] = '姿器膂力，万人之雄。',
}

lvli:addEffect(fk.Damage, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lvli) and player:getHandcardNum() ~= player.hp then
      local n = 1
      if player:usedSkillTimes("choujue", Player.HistoryGame) > 0 then
        if player.phase ~= Player.NotActive then
          n = 2
        end
      end
      return player:usedSkillTimes(lvli.name) < n
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player.hp
    if n < 0 then
      player:drawCards(-n, lvli.name)
    else
      player.room:recover{
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = lvli.name
      }
    end
  end
})

lvli:addEffect(fk.Damaged, {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(lvli) and player:getHandcardNum() ~= player.hp then
      local n = 1
      if player:usedSkillTimes("choujue", Player.HistoryGame) > 0 then
        if player.phase ~= Player.NotActive then
          n = 2
        end
      end
      return player:usedSkillTimes("beishui", Player.HistoryGame) > 0 and player:usedSkillTimes(lvli.name) < n
    end
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player.hp
    if n < 0 then
      player:drawCards(-n, lvli.name)
    else
      player.room:recover{
        who = player,
        num = math.min(n, player:getLostHp()),
        recoverBy = player,
        skillName = lvli.name
      }
    end
  end
})

return lvli
