local ty_ex__zenhui = fk.CreateSkill {
  name = "ty_ex__zenhui"
}

Fk:loadTranslationTable{
  ['ty_ex__zenhui'] = '谮毁',
  ['#ty_ex__zenhui-choose'] = '谮毁：选择一名能成为%arg的目标的角色',
  ['#ty_ex__zenhui-give'] = '谮毁：交给 %dest 一张牌，成为%arg的使用者；或成为%arg的目标',
  ['#ChangeUserBySkill'] = '由于 %arg 的效果，%arg2的使用者由 %from 改为 %to',
  [':ty_ex__zenhui'] = '当你使用【杀】或普通锦囊牌指定一名角色为唯一目标时，你可以令能成为此牌目标的另一名其他角色选择一项：1.交给你一张牌，然后代替你成为此牌的使用者；2.也成为此牌的目标，然后你的〖谮毁〗本回合失效。',
  ['$ty_ex__zenhui1'] = '稍稍谮毁，万劫不复！',
  ['$ty_ex__zenhui2'] = '萋兮斐兮，谋欲谮人！'
}

ty_ex__zenhui:addEffect(fk.TargetSpecifying, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty_ex__zenhui.name) and
      (data.card.trueName == "slash" or data.card:isCommonTrick()) and data.firstTarget and
      U.isOnlyTarget(player.room:getPlayerById(data.to), data, event) and #player.room:getUseExtraTargets(data, true, true) > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askToChoosePlayers(player, {
      targets = room:getUseExtraTargets(data, true, true),
      min_num = 1,
      max_num = 1,
      prompt = "#ty_ex__zenhui-choose:::"..data.card:toLogString(),
      skill_name = ty_ex__zenhui.name,
      cancelable = true
    })
    if #to > 0 then
      event:setCostData(self, to[1])
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self))
    if not to:isNude() then
      local cards = room:askToCards(to, {
        min_num = 1,
        max_num = 1,
        include_equip = true,
        skill_name = ty_ex__zenhui.name,
        cancelable = true,
        pattern = ".",
        prompt = "#ty_ex__zenhui-give::"..player.id..":"..data.card:toLogString()
      })
      if #cards > 0 then
        room:obtainCard(player, cards[1], false, fk.ReasonPrey, to.id)
        data.from = to.id
        room:sendLog{
          type = "#ChangeUserBySkill",
          from = player.id,
          to = {to.id},
          arg = ty_ex__zenhui.name,
          arg2 = data.card:toLogString(),
        }
        return
      end
    end
    AimGroup:addTargets(room, data, to.id)
    room:invalidateSkill(player, ty_ex__zenhui.name, "-turn")
    room:sendLog{ type = "#AddTargetsBySkill", from = player.id, to = {to.id}, arg = ty_ex__zenhui.name, arg2 = data.card:toLogString() }
  end,
})

return ty_ex__zenhui
