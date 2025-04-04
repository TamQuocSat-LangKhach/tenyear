local baobian = fk.CreateSkill {
  name = "ty__baobian",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["ty__baobian"] = "豹变",
  [":ty__baobian"] = "锁定技，当你受到伤害后，你依次获得以下一个技能：〖挑衅〗、〖咆哮〗、〖神速〗。",

  ["$ty__baobian1"] = "豹变分奇略，虎视肃戎威！",
  ["$ty__baobian2"] = "穷通须豹变，撄搏笑狼狞！",
}

baobian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baobian.name) and
      table.find({"tiaoxin", "ex__paoxiao", "ol_ex__shensu"}, function(s)
        return not player:hasSkill(s, true)
      end)
  end,
  on_use = function(self, event, target, player, data)
    for _, s in ipairs({"tiaoxin", "ex__paoxiao", "ol_ex__shensu"}) do
      if not player:hasSkill(s, true) then
        player.room:handleAddLoseSkills(player, s)
        return
      end
    end
  end,
})

return baobian
