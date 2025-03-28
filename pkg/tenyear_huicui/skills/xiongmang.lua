local xiongmang = fk.CreateSkill {
  name = "xiongmang",
}

Fk:loadTranslationTable{
  ["xiongmang"] = "雄莽",
  [":xiongmang"] = "你可以将任意张花色不同的手牌当【杀】使用，此【杀】目标数上限等于用于转化的牌数。此【杀】结算结束后，若此【杀】："..
  "未造成伤害，你减1点体力上限；造成伤害，此阶段你使用【杀】的次数上限+1。",

  ["#xiongmang"] = "雄莽：将任意张花色不同的手牌当【杀】使用，目标数等于转化牌数",
  ["#xiongmang-choose"] = "雄莽：你可以为此%arg额外指定至多%arg2个目标",

  ["$xiongmang1"] = "力逮千军，唯武为雄！",
  ["$xiongmang2"] = "莽行沙场，乱世称雄！",
}

xiongmang:addEffect("viewas", {
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#xiongmang",
  handly_pile = true,
  card_filter = function(self, player, to_select, selected)
    return table.contains(player:getHandlyIds(), to_select) and
      table.every(selected, function (id)
        return Fk:getCardById(to_select):compareSuitWith(Fk:getCardById(id), true)
      end)
  end,
  view_as = function(self, player, cards)
    if #cards == 0 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = xiongmang.name
    card:addSubcards(cards)
    return card
  end,
  after_use = function (self, player, use)
    if not player.dead then
      if use.damageDealt then
        player.room:addPlayerMark(player, MarkEnum.SlashResidue .. "-phase")
      else
        player.room:changeMaxHp(player, -1)
      end
    end
  end,
  enabled_at_response = function(self, player, response)
    return not response
  end,
})

xiongmang:addEffect(fk.AfterCardTargetDeclared, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and data.card.trueName == "slash" and not player.dead and
      table.contains(data.card.skillNames, xiongmang.name) and
      #data:getExtraTargets() > 0 and #data.tos < #data.card.subcards
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = #data.card.subcards - #data.tos
    local tos = room:askToChoosePlayers(player, {
      targets = data:getExtraTargets(),
      min_num = 1,
      max_num = n,
      prompt = "#xiongmang-choose:::"..data.card:toLogString()..":"..n,
      skill_name = xiongmang.name,
      cancelable = true,
    })
    if #tos > 0 then
      room:sortByAction(tos)
      event:setCostData(self, {tos = tos})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local tos = table.simpleClone(event:getCostData(self).tos)
    player.room:sendLog{
      type = "#AddTargetsBySkill",
      from = target.id,
      to = table.map(tos, Util.IdMapper),
      arg = xiongmang.name,
      arg2 = data.card:toLogString(),
    }
    for _, p in ipairs(tos) do
      data:addTarget(p)
    end
  end,
})

return xiongmang
