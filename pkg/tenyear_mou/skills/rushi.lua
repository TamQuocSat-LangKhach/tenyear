local rushi = fk.CreateSkill {
  name = "rushi",
  tags = { Skill.Limited },
}

Fk:loadTranslationTable{
  ["rushi"] = "入世",
  [":rushi"] = "限定技，出牌阶段，你可以将体力值、手牌数和〖覆谋〗的阴阳状态依次调整为〖肃身〗记录值且视为于此阶段内未发动过〖覆谋〗。",

  ["#rushi"] = "入世：将体力值调整为%arg、手牌数调整为%arg2",

  ["$rushi1"] = "孤立川上，观逝者如东去之流水。",
  ["$rushi2"] = "九州如画，怎可空老人间？"
}

local U = require "packages/utility/utility"

rushi:addEffect("active", {
  anim_type = "control",
  prompt = function (self, player)
    return "#rushi:::" .. player:getMark("sushen_hp") .. ":" .. player:getMark("sushen_handcardnum")
  end,
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(rushi.name, Player.HistoryGame) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = player.hp - player:getMark("sushen_hp")
    if n > 0 then
      room:loseHp(player, n, rushi.name)
    elseif n < 0 and player:isWounded() then
      room:recover{
        who = player,
        num = math.min(-n, player:getLostHp()),
        recoverBy = player,
        skillName = rushi.name
      }
    end
    if player.dead then return end
    n = player:getHandcardNum() - player:getMark("sushen_handcardnum")
    if n > 0 then
      room:askToDiscard(player, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = rushi.name,
        cancelable = false,
      })
    elseif n < 0 then
      player:drawCards(-n, rushi.name)
    end
    if player:hasSkill("fumouj", true) then
      U.SetSwitchSkillState(player, "fumouj", player:getMark("sushen_state"))
      if player:usedSkillTimes("fumouj", Player.HistoryPhase) > 0 then
        player:setSkillUseHistory("fumouj", 0, Player.HistoryPhase)
      end
    end
  end,
})

return rushi
