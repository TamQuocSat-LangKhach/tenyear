local jincui = fk.CreateSkill {
  name = "jincui",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["jincui"] = "尽瘁",
  [":jincui"] = "锁定技，游戏开始时，你将手牌补至7张。准备阶段，你的体力值调整为与牌堆中点数为7的游戏牌数量相等（至少为1），"..
  "然后观看牌堆顶X张牌（X为你的体力值），以任意顺序置于牌堆顶或牌堆底。",

  ["$jincui1"] = "情记三顾之恩，亮必继之以死。",
  ["$jincui2"] = "身负六尺之孤，臣当鞠躬尽瘁。",
}

jincui:addEffect(fk.EventPhaseStart, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(jincui.name) and player.phase == Player.Start
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = #table.filter(room.draw_pile, function (id)
      return Fk:getCardById(id).number == 7
    end)
    player.hp = math.min(player.maxHp, math.max(n, 1))
    room:broadcastProperty(player, "hp")
    room:askToGuanxing(player, {
      cards = room:getNCards(player.hp),
    })
  end,
})

jincui:addEffect(fk.GameStart, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(jincui.name) and player:getHandcardNum() < 7
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, jincui.name, "drawcard")
    player:broadcastSkillInvoke(jincui.name)
    local n = 7 - player:getHandcardNum()
    if n > 0 then
      player:drawCards(n, jincui.name)
    end
  end,
})

return jincui
