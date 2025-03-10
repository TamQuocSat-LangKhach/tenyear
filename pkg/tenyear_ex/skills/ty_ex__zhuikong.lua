local zhuikong = fk.CreateSkill {
  name = "ty_ex__zhuikong"
}

Fk:loadTranslationTable{
  ['ty_ex__zhuikong'] = '惴恐',
  ['#ty_ex__zhuikong-invoke'] = '惴恐：你可以与 %dest 点，若赢则其本回合使用牌只能指定自己为目标',
  ['@@ty_ex__zhuikong_prohibit-turn'] = '惴恐',
  ['#ty_ex__zhuikong_delay'] = '惴恐',
  [':ty_ex__zhuikong'] = '其他角色的回合开始时，若你已受伤，你可以与其拼点：若你赢，本回合该角色只能对自己使用牌；若你没赢，你获得其拼点的牌，然后其视为对你使用一张【杀】。',
  ['$ty_ex__zhuikong1'] = '曹贼！你怎可如此不尊汉室！',
  ['$ty_ex__zhuikong2'] = '密信之事，不可被曹贼知晓。',
}

zhuikong:addEffect(fk.TurnStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(zhuikong.name) and not target.dead and target ~= player and
      player:isWounded() and player:canPindian(target)
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = zhuikong.name,
      prompt = "#ty_ex__zhuikong-invoke::" .. target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, zhuikong.name)
    if pindian.results[target.id].winner == player then
      room:addPlayerMark(target, "@@ty_ex__zhuikong_prohibit-turn")
    elseif not player.dead then
      local slash = Fk:cloneCard("slash")
      if not target.dead and not player.dead and not target:prohibitUse(slash) and not target:isProhibited(player, slash) then
        room:useVirtualCard("slash", nil, target, player, zhuikong.name, true)
      end
    end
  end,
})

zhuikong:addEffect(fk.PindianResultConfirmed, {
  name = "#ty_ex__zhuikong_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if not player.dead and data.from == player and data.winner ~= player and
      data.toCard and player.room:getCardArea(data.toCard) == Card.Processing then
      return data.reason == zhuikong.name
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player, data.toCard, true, fk.ReasonPrey)
  end,
})

zhuikong:addEffect('prohibit', {
  name = "#ty_ex__zhuikong_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("@@ty_ex__zhuikong_prohibit-turn") > 0 and from ~= to
  end,
})

return zhuikong
