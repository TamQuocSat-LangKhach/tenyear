local jingyu = fk.CreateSkill {
  name = "jingyu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jingyu"] = "静域",
  [":jingyu"] = "锁定技，每项技能每轮限一次，当一名角色发动除〖静域〗外的技能时，你摸一张牌。<br/>"..
  "<font color=><b>注</b>：请不要反馈此技能相关的任何问题</font>",

  ["$jingyu1"] = "人身疾苦，与我无异。",
  ["$jingyu2"] = "医以济世，其术贵在精诚。",
}

jingyu:addEffect(fk.SkillEffect, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jingyu.name) and target and
      data.skill:isPlayerSkill(target) and data.skill ~= self and target:hasSkill(data.skill:getSkeleton().name, true, true) and
      not table.contains(player:getTableMark("jingyu_skills-round"), data.skill:getSkeleton().name) and
      player.room.logic:getCurrentEvent():findParent(GameEvent.Round, true) ~= nil
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "jingyu_skills-round", data.skill:getSkeleton().name)
    player:drawCards(1, jingyu.name)
  end,
})

return jingyu
