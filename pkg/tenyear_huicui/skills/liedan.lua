local liedan = fk.CreateSkill {
  name = "liedan",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["liedan"] = "裂胆",
  [":liedan"] = "锁定技，其他角色的准备阶段，你的手牌数、体力值和装备区里的牌数每有一项大于该角色，便摸一张牌。若均大于其，"..
  "你加1点体力上限（至多加至8）；若均不大于其，你失去1点体力并获得1枚“裂胆”标记。准备阶段，若“裂胆”标记不小于5，你死亡。",

  ["@liedan"] = "裂胆",

  ["$liedan1"] = "声若洪钟，震胆发聩！",
  ["$liedan2"] = "阴雷滚滚，肝胆俱颤！",
}

liedan:addEffect(fk.EventPhaseStart, {
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(liedan.name) and target.phase == Player.Start then
      if target ~= player then
        return true
      else
        return player:getMark("@liedan") > 4
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(liedan.name)
    if target ~= player then
      room:notifySkillInvoked(player, liedan.name, "drawcard")
      local n = 0
      if player:getHandcardNum() > target:getHandcardNum() then
        n = n + 1
      end
      if player.hp > target.hp then
        n = n + 1
      end
      if #player:getCardIds("e") > #target:getCardIds("e") then
        n = n + 1
      end
      if n > 0 then
        player:drawCards(n, liedan.name)
        if n == 3 and player.maxHp < 8 and not player.dead then
          room:changeMaxHp(player, 1)
        end
      else
        room:loseHp(player, 1, liedan.name)
        if not player.dead then
          room:addPlayerMark(player, "@liedan", 1)
        end
      end
    else
      room:notifySkillInvoked(player, liedan.name, "negative")
      room:killPlayer({who = player})
    end
  end,
})

liedan:addLoseEffect(function (self, player, is_death)
  player.room:setPlayerMark(player, "@liedan", 0)
end)

return liedan
