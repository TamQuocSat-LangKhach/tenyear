local sushen = fk.CreateSkill {
  name = "sushen",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["sushen"] = "肃身",
  [":sushen"] = "限定技，出牌阶段，你可以记录你的体力值、手牌数和〖覆谋〗的阴阳状态，然后获得〖入世〗。",

  ["#sushen"] = "肃身：记录你的体力值、手牌数和“覆谋”的阴阳状态，获得“入世”（可以将状态调整至记录值）",

  ["$sushen1"] = "谋先于行则昌，行先于谋则亡。",
  ["$sushen2"] = "天行五色，雪覆林间睡狐，独我执白。",
}

sushen:addEffect("active", {
  anim_type = "control",
  prompt = "#sushen",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(sushen.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    room:setPlayerMark(player, "sushen_hp", player.hp)
    room:setPlayerMark(player, "sushen_handcardnum", player:getHandcardNum())
    if player:hasSkill("fumouj", true) then
      room:setPlayerMark(player, "sushen_state", player:getSwitchSkillState("fumouj", false, true))
    end
    room:handleAddLoseSkills(player, "rushi")
  end,
})

return sushen
