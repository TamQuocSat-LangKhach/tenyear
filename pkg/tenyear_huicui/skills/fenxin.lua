local fenxin = fk.CreateSkill{
  name = "ty__fenxin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__fenxin"] = "焚心",
  [":ty__fenxin"] = "锁定技，当一名角色首次受到伤害后，你选择一项修改〖竭缘〗：减少伤害无体力值限制；增加伤害无体力值限制；"..
  "弃置牌时无颜色限制且可以弃置装备牌。",

  ["ty__fenxin1"] = "减少伤害无体力值限制",
  ["ty__fenxin2"] = "增加伤害无体力值限制",
  ["ty__fenxin3"] = "弃置牌时无颜色限制且可以弃置装备牌",

  ["$ty__fenxin1"] = "大仇如山在背，安能囿于情爱而付之东流。",
  ["$ty__fenxin2"] = "万般情爱在心上，慧剑难斩，唯付于薪火。",
}

fenxin:addEffect(fk.Damaged, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(fenxin.name) and
      player:hasSkill("ty__jieyuan", true) and
      not table.contains(player:getTableMark("ty__fenxin_targets"), target.id) and
      #player:getTableMark(fenxin.name) < 3
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addTableMark(player, "ty__fenxin_targets", target.id)
    local all_choices = {"ty__fenxin1", "ty__fenxin2", "ty__fenxin3"}
    local choices = table.filter({1, 2, 3}, function (i)
      return not table.contains(player:getTableMark(fenxin.name), i)
    end)
    choices = table.map(choices, function (i)
      return "ty__fenxin"..i
    end)
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = fenxin.name,
    })
    room:addTableMark(player, fenxin.name, table.indexOf(all_choices, choice))
  end,
})

return fenxin
