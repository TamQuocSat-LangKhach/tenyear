local xiongrao = fk.CreateSkill {
  name = "xiongrao"
}

Fk:loadTranslationTable{
  ['xiongrao'] = '熊扰',
  ['#xiongrao-invoke'] = '熊扰：你可以令其他角色本回合非锁定技无效，你体力上限增加至7！',
  ['@@xiongrao-turn'] = '熊扰',
  [':xiongrao'] = '限定技，准备阶段，你可以令所有其他角色本回合除锁定技、限定技、觉醒技以外的技能全部失效，然后你将体力上限增加至7并摸等同于增加体力上限张数的牌。',
  ['$xiongrao1'] = '势如熊罴，威震四海！',
  ['$xiongrao2'] = '啸聚熊虎，免走狐惊！',
}

xiongrao:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  frequency = Skill.Limited,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiongrao.name) and player.phase == Player.Start and
      player:usedSkillTimes(xiongrao.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = xiongrao.name,
      prompt = "#xiongrao-invoke"
    })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getOtherPlayers(player)) do
      room:setPlayerMark(p, "@@xiongrao-turn", 1)
    end
    local x = 7 - player.maxHp
    if x > 0 then
      room:changeMaxHp(player, x)
      player:drawCards(x, xiongrao.name)
    end
  end,
})

xiongrao:addEffect('invalidity', {
  name = "#xiongrao_invalidity",
  invalidity_func = function(self, from, skill_to_check)
    return from:getMark("@@xiongrao-turn") > 0 and
      skill_to_check.frequency ~= Skill.Compulsory and skill_to_check.frequency ~= Skill.Limited and skill_to_check.frequency ~= Skill.Wake and
      skill_to_check:isPlayerSkill(from)
  end
})

return xiongrao
