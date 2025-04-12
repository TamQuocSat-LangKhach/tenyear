local zhuikong = fk.CreateSkill {
  name = "ty_ex__zhuikong",
}

Fk:loadTranslationTable{
  ["ty_ex__zhuikong"] = "惴恐",
  [":ty_ex__zhuikong"] = "其他角色的准备阶段，若你已受伤，你可以与其拼点：若你赢，本回合该角色其使用牌不能指定除其以外的角色为目标；"..
  "若你没赢，你获得其拼点的牌，然后其视为对你使用一张【杀】。",

  ["#ty_ex__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢，其只能对自己使用牌，若没赢，你获得其拼点牌，其视为对你使用【杀】",
  ["@@ty_ex__zhuikong-turn"] = "惴恐",

  ["$ty_ex__zhuikong1"] = "曹贼！你怎可如此不尊汉室！",
  ["$ty_ex__zhuikong2"] = "密信之事，不可被曹贼知晓。",
}

zhuikong:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target ~= player and player:hasSkill(zhuikong.name) and target.phase == Player.Start and
      player:isWounded() and player:canPindian(target) and not target.dead
  end,
  on_cost = function (self, event, target, player, data)
    if player.room:askToSkillInvoke(player, {
      skill_name = zhuikong.name,
      prompt = "#ty_ex__zhuikong-invoke::"..target.id,
    }) then
      event:setCostData(self, {tos = {target}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local pindian = player:pindian({target}, zhuikong.name)
    if pindian.results[target].winner == player then
      if not target.dead then
        room:setPlayerMark(target, "@@ty_ex__zhuikong-turn", 1)
      end
    elseif not player.dead then
      if pindian.results[target] and pindian.results[target].toCard and
        room:getCardArea(pindian.results[target].toCard) == Card.DiscardPile then
        room:moveCardTo(pindian.results[target].toCard, Card.PlayerHand, player, fk.ReasonJustMove, zhuikong.name, nil, true, player)
      end
      if not target.dead and not player.dead then
        room:useVirtualCard("slash", nil, target, player, zhuikong.name, true)
      end
    end
  end,
})

zhuikong:addEffect("prohibit", {
  is_prohibited = function (self, from, to, card)
    return from:getMark("@@ty_ex__zhuikong-turn") > 0 and card and from ~= to
  end,
})

return zhuikong
