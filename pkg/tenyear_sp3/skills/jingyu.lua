local jingyu = fk.CreateSkill {
  name = "jingyu"
}

Fk:loadTranslationTable{
  ['jingyu'] = '静域',
  [':jingyu'] = '锁定技，每项技能每轮限一次，当一名角色发动除“静域”外的技能时，你摸一张牌。<br/><font color=><b>注</b>：请不要反馈此技能相关的任何问题。</font>',
  ['$jingyu1'] = '人身疾苦，与我无异。',
  ['$jingyu2'] = '医以济世，其术贵在精诚。',
}

jingyu:addEffect(fk.SkillEffect, {
  global = true,
  can_trigger = function(self, _, target, player, data)
    return player:hasSkill(jingyu.name) and data.visible and data ~= jingyu and target and target:hasSkill(data, true, true) and
      not table.contains({ "m_feiyang", "m_bahu" }, data.name) and
      not table.contains(player:getTableMark("jingyu_skills-round"), data.name) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Round, true) ~= nil
  end,
  on_use = function(self, _, target, player, data)
    local room = player.room
    room:addTableMark(player, "jingyu_skills-round", data.name)
    player:drawCards(1, jingyu.name)
  end,
})

return jingyu
