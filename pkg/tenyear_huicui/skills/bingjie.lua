local bingjie = fk.CreateSkill {
  name = "bingjie",
}

Fk:loadTranslationTable{
  ["bingjie"] = "秉节",
  [":bingjie"] = "出牌阶段开始时，你可以减1点体力上限，然后当你本回合使用【杀】或普通锦囊牌指定目标后，除你以外的目标角色各弃置一张牌，"..
  "若弃置的牌与你使用的牌颜色相同，其无法响应此牌。",

  ["@@bingjie-turn"] = "秉节",
  ["#bingjie-discard"] = "秉节：请弃置一张牌，若为%arg则无法响应此%arg2",

  ["$bingjie1"] = "秉节传旌，心存丹衷。",
  ["$bingjie2"] = "秉节刚劲，奸佞务尽。",
}

bingjie:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(bingjie.name) and player.phase == Player.Play
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, "@@bingjie-turn", 1)
    room:changeMaxHp(player, -1)
  end,
})

bingjie:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:getMark("@@bingjie-turn") > 0 and data.firstTarget and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      table.find(data.use.tos, function(p)
        return p ~= player and not p.dead
      end)
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local tos = table.filter(data.use.tos, function(p)
      return p ~= player and not p.dead
    end)
    room:sortByAction(tos)
    for _, to in ipairs(tos) do
      if not to.dead and not to:isNude() then
        local card = room:askToDiscard(to, {
          min_num = 1,
          max_num = 1,
          include_equip = true,
          skill_name = bingjie.name,
          cancelable = false,
          prompt = "#bingjie-discard:::"..data.card:getColorString()..":"..data.card:toLogString(),
        })
        if #card > 0 and Fk:getCardById(card[1]).color == data.card.color then
          data.use.disresponsiveList = data.use.disresponsiveList or {}
          table.insertIfNeed(data.use.disresponsiveList, to)
        end
      end
    end
  end,
})

return bingjie
