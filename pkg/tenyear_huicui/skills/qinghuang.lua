local qinghuang = fk.CreateSkill {
  name = "qinghuang",
}

Fk:loadTranslationTable{
  ["qinghuang"] = "清荒",
  [":qinghuang"] = "出牌阶段开始时，你可以减1点体力上限，然后你本回合发动〖踏寂〗时随机额外执行一种效果。",

  ["#qinghuang-invoke"] = "清荒：你可以减1点体力上限，本回合发动“踏寂“随机额外执行一种效果",
  ["@@qinghuang-turn"] = "清荒",

  ["$qinghuang1"] = "上士无争，焉生妄心。",
  ["$qinghuang2"] = "心有草木，何畏荒芜？",
}

qinghuang:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(qinghuang.name) and player.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = qinghuang.name,
      prompt = "#qinghuang-invoke",
     })
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, -1)
    if not player.dead then
      room:setPlayerMark(player, "@@qinghuang-turn", 1)
    end
  end,
})

return qinghuang
