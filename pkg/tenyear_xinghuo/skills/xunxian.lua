local xunxian = fk.CreateSkill {
  name = "xunxian",
}

Fk:loadTranslationTable{
  ["xunxian"] = "逊贤",
  [":xunxian"] = "每回合限一次，你使用或打出的牌置入弃牌堆时，你可以将之交给一名手牌数或体力值大于你的角色。",

  ["#xunxian-choose"] = "逊贤：你可以将%arg交给一名手牌数大于你的角色",

  ["$xunxian1"] = "督军之才，子明强于我甚多。",
  ["$xunxian2"] = "此间重任，公卿可担之。",
}

local spec = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xunxian.name) and
      player.room:getCardArea(data.card) == Card.Processing and
      player:usedSkillTimes(xunxian.name, Player.HistoryTurn) == 0 and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return p:getHandcardNum() > player:getHandcardNum() or p.hp > player.hp
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return p:getHandcardNum() > player:getHandcardNum() or p.hp > player.hp
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = xunxian.name,
      min_num = 1,
      max_num = 1,
      targets = targets,
      prompt = "#xunxian-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(event:getCostData(self).tos[1], data.card, true, fk.ReasonGive, player)
  end,
}

xunxian:addEffect(fk.CardUseFinished, spec)
xunxian:addEffect(fk.CardRespondFinished, spec)

return xunxian
