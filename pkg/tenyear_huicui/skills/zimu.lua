local zimu = fk.CreateSkill {
  name = "zimu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["zimu"] = "自牧",
  [":zimu"] = "锁定技，当你受到伤害后，有〖自牧〗的角色各摸一张牌，然后你失去〖自牧〗。",

  ["@@zimu"] = "自牧",

  ["$zimu"] = "既为汉吏，当遵汉律。",
}

zimu:addEffect(fk.Damaged, {
  anim_type = "masochism",
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, p in ipairs(room:getAlivePlayers()) do
      if p:hasSkill(zimu.name, true) then
        p:drawCards(1, zimu.name)
      end
    end
    room:handleAddLoseSkills(player, "-zimu")
  end,
})

zimu:addAcquireEffect(function (self, player, is_start)
  player.room:setPlayerMark(player, "@@zimu", 1)
end)

zimu:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@@zimu", 0)
end)

return zimu
