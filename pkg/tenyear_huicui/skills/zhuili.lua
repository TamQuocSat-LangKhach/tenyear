local zhuili = fk.CreateSkill {
  name = "zhuili",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zhuili"] = "惴栗",
  [":zhuili"] = "锁定技，当你成为其他角色使用黑色牌的目标后，若此时〖漂萍〗状态为：阳，令〖托献〗可使用次数+1，然后若〖托献〗可使用次数超过3，"..
  "此技能本回合失效；阴，令〖漂萍〗状态转换为阳。",

  ["$zhuili1"] = "近况艰难，何不忧愁？",
  ["$zhuili2"] = "形势如此，惴惕难当。",
}

local U = require "packages/utility/utility"

zhuili:addEffect(fk.TargetConfirmed, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zhuili.name) and
      data.card.color == Card.Black and data.from ~= player and
      player:hasSkill("piaoping", true)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getSwitchSkillState("piaoping", false) == fk.SwitchYang then
      if player:hasSkill("tuoxian", true) then
        room:addPlayerMark(player, "tuoxian", 1)
        if player:getMark("tuoxian") - player:usedSkillTimes("tuoxian", Player.HistoryGame) > 2 then
          room:invalidateSkill(player, zhuili.name, "-turn")
        end
      end
    else
      U.SetSwitchSkillState(player, "piaoping", fk.SwitchYang)
    end
  end,
})

return zhuili
