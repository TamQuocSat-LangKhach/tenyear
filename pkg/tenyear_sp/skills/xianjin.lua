local xianjin = fk.CreateSkill {
  name = "xianjin",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["xianjin"] = "险进",
  [":xianjin"] = "锁定技，当你造成或受到两次伤害后开发一个手牌副区域，摸X张牌（X为你已开发的手牌副区域数，若你手牌全场最多则改为1）。",

  ["#xianjin-choice"] = "险进：选择你要开发的手牌副区域",

  ["$xianjin1"] = "大风！大雨！大景！！",
  ["$xianjin2"] = "行役沙场，不战胜，则战死！",
}

local spec = {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianjin.name) and player:getMark("xianjin_damage") > 1
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "xianjin_damage", 0)
    local choices = table.filter({"1", "2", "3"}, function(n)
      return player:getMark("tuoyu"..n) == 0
      end)
    if #choices > 0 then
      local choice = room:askToChoice(player, {
        choices = table.map(choices, function(n) return "tuoyu"..n end),
        skill_name = xianjin.name,
        prompt = "#xianjin-choice",
        detailed = true,
      })
      room:setPlayerMark(player, choice, 1)
    end
    if table.every(room.alive_players, function(p)
      return player:getHandcardNum() >= p:getHandcardNum()
    end) then
      player:drawCards(1, xianjin.name)
    else
      player:drawCards(#table.filter({"1", "2", "3"}, function(n) return player:getMark("tuoyu"..n) > 0 end), xianjin.name)
    end
  end,

  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(xianjin.name, true)
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "xianjin_damage")
  end,
}

xianjin:addEffect(fk.Damage, spec)
xianjin:addEffect(fk.Damaged, spec)

return xianjin
