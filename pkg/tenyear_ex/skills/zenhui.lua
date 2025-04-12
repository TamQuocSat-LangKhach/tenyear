local zenhui = fk.CreateSkill {
  name = "ty_ex__zenhui",
}

Fk:loadTranslationTable{
  ["ty_ex__zenhui"] = "谮毁",
  [":ty_ex__zenhui"] = "当你使用【杀】或普通锦囊牌指定唯一目标时，你可以令另一名其他角色选择一项：1.交给你一张牌，然后代替你"..
  "成为此牌的使用者；2.也成为此牌的目标，然后〖谮毁〗本回合失效。",

  ["#ty_ex__zenhui-choose"] = "谮毁：令一名角色选择：交给你一张牌并成为%arg的使用者；或成为此牌的额外目标",
  ["#ty_ex__zenhui-give"] = "谮毁：交给 %dest 一张牌以成为此牌使用者，否则你成为此牌额外目标",

  ["$ty_ex__zenhui1"] = "稍稍谮毁，万劫不复！",
  ["$ty_ex__zenhui2"] = "萋兮斐兮，谋欲谮人！"
}

zenhui:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(zenhui.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and
      data:isOnlyTarget(data.tos[1]) and
      table.find(player.room:getOtherPlayers(player, false), function (p)
        return not player:isProhibited(p, data.card) and not table.contains(data.tos, p)
      end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.filter(room:getOtherPlayers(player, false), function (p)
      return not player:isProhibited(p, data.card) and not table.contains(data.tos, p)
    end)
    local to = room:askToChoosePlayers(player, {
      skill_name = zenhui.name,
      targets = targets,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zenhui-choose:::"..data.card:toLogString(),
      cancelable = true,
    })
    if #to > 0 then
      event:setCostData(self, {tos = to})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = event:getCostData(self).tos[1]
    if to:isNude() then
      data:addTarget(to)
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = zenhui.name,
        arg2 = data.card:toLogString(),
      }
      return
    end
    local card = room:askToCards(to, {
      skill_name = zenhui.name,
      include_equip = true,
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zenhui-give::"..player.id,
      cancelable = true,
    })
    if #card > 0 then
      room:obtainCard(player, card, false, fk.ReasonGive, to, zenhui.name)
      data.from = to
      --room.logic:trigger(fk.PreCardUse, to, data)
    else
      data:addTarget(to)
      room:sendLog{
        type = "#AddTargetsBySkill",
        from = player.id,
        to = {to.id},
        arg = zenhui.name,
        arg2 = data.card:toLogString(),
      }
      room:invalidateSkill(player, zenhui.name, "-turn")
    end
  end,
})

return zenhui
