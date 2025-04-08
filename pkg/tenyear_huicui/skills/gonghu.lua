local gonghu = fk.CreateSkill {
  name = "gonghu",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["gonghu"] = "共护",
  [":gonghu"] = "锁定技，当你于回合外一回合失去超过一张基本牌后，〖破锐〗改为“每轮限两次”；<br>"..
  "当你于回合外一回合造成或受到伤害超过1点伤害后，你删除〖破锐〗中交给牌的效果；<br>"..
  "若以上两个效果均已触发，则你本局游戏使用红色基本牌无法响应，使用红色普通锦囊牌可以额外指定一个目标。",

  ["#gonghu-choose"] = "共护：你可以为%arg额外指定一个目标",

  ["$gonghu1"] = "大都督中伏，吾等当舍命救之。",
  ["$gonghu2"] = "袍泽临难，但有共死而无坐视。",
}

gonghu:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(gonghu.name) and player.room.current ~= player and player:getMark("gonghu1") == 0 then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function (e)
        for _, move in ipairs(e.data) do
          if move.from == player and (move.to ~= player or
            (move.toArea ~= Card.PlayerHand and move.toArea ~= Card.PlayerEquip)) then
            for _, info in ipairs(move.moveInfo) do
              if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip) and
                Fk:getCardById(info.cardId).type == Card.TypeBasic then
                n = n + 1
                return n > 1
              end
            end
          end
        end
      end, Player.HistoryTurn)
      return n > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "gonghu1", 1)
  end,
})

local spec = {
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(gonghu.name) and
      player.room.current ~= player and player:getMark("gonghu2") == 0 then
      if data.damage > 1 then return true end
      local n = 0
      player.room.logic:getActualDamageEvents(1, function (e)
        local damage = e.data
        if damage.from == player or damage.to == player then
          n = n + damage.damage
          return n > 1
        end
      end, Player.HistoryTurn)
      return n > 1
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:setPlayerMark(player, "gonghu2", 1)
  end,
}

gonghu:addEffect(fk.Damage, spec)
gonghu:addEffect(fk.Damaged, spec)

gonghu:addEffect(fk.CardUsing, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("gonghu1") > 0 and player:getMark("gonghu2") > 0 and
      data.card.color == Card.Red and data.card.type == Card.TypeBasic
  end,
  on_use = function (self, event, target, player, data)
    data.disresponsiveList = table.simpleClone(player.room.players)
  end,
})

gonghu:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("gonghu1") > 0 and player:getMark("gonghu2") > 0 and
      data.card.color == Card.Red and data.card:isCommonTrick() and
      #data:getExtraTargets() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = 1,
      prompt = "#gonghu-choose:::"..data.card:toLogString(),
      skill_name = gonghu.name,
    })
    if #to > 0 then
    event:setCostData(self, {tos = to})
    return true
    end
  end,
  on_use = function(self, event, target, player, data)
    data:addTarget(event:getCostData(self).tos[1])
  end,
})

return gonghu
