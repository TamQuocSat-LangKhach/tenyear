local chushan = fk.CreateSkill {
  name = "chushan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["chushan"] = "出山",
  [":chushan"] = "锁定技，游戏开始时，你从随机六项技能中选择两项技能获得。",

  ["#chushan-choose"] = "出山：请选择两个技能出战（右键或长按可查看技能描述）",
  ["@chushan_skills"] = "",
}

chushan:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(chushan.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local generals = Fk:getGeneralsRandomly(6, nil, { "wuming" })
    local skills = {}
    for _, general in ipairs(generals) do
      table.insertIfNeed(skills, table.random(general:getSkillNameList()))
    end

    data = {
      path = "/packages/utility/qml/ChooseSkillBox.qml",
      data = {
        skills, 2, 2, "#chushan-choose", table.map(generals, Util.NameMapper)
      },
    }

    local req = Request:new(player, "CustomDialog")
    req:setData(player, data)
    req:setDefaultReply(player, table.random(skills, 2))
    req.focus_text = self.name
    req:ask()
    skills = req:getResult(player)

    if #skills > 0 then
      local realNames = table.map(skills, Util.TranslateMapper)
      room:setPlayerMark(player, "@chushan_skills", "<font color='burlywood'>" .. table.concat(realNames, " ") .. "</font>")
      room:handleAddLoseSkills(player, table.concat(skills, "|"))
    end
  end,
})

return chushan
