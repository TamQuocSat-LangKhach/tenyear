local ty_ex__pojun = fk.CreateSkill {
  name = "ty_ex__pojun"
}

Fk:loadTranslationTable{
  ['ty_ex__pojun'] = '破军',
  ['#ty_ex__pojun-invoke'] = '破军：你可以扣置 %dest 至多 %arg 张牌',
  ['$ty_ex__pojun'] = '破军',
  ['$Throw'] = '弃置',
  ['#ty_ex__pojun-throw'] = '破军：弃置其中一张牌',
  ['#ty_ex__pojun_delay'] = '破军',
  [':ty_ex__pojun'] = '当你使用【杀】指定一个目标后，你可以将其至多X张牌扣置于该角色的武将牌旁（X为其体力值），若其中有：装备牌，你弃置其中一张牌；锦囊牌，你摸一张牌。当前回合结束后，该角色获得其武将牌旁的所有牌。',
  ['$ty_ex__pojun1'] = '奋身出命，为国建功！',
  ['$ty_ex__pojun2'] = '披甲持戟，先登陷陈！',
}

ty_ex__pojun:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(ty_ex__pojun.name) and data.card.trueName == "slash" then
      local to = player.room:getPlayerById(data.to)
      return to.hp > 0 and not to:isNude()
    end
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    local x = room:getPlayerById(data.to).hp
    if room:askToSkillInvoke(player, { skill_name = ty_ex__pojun.name, prompt = "#ty_ex__pojun-invoke::"..data.to..":"..x }) then
      event:setCostData(self, { tos = { data.to } })
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(event:getCostData(self).tos[1])
    local cards = room:askToChooseCards(player, {
      min = 1,
      max = to.hp,
      flag = "he",
      skill_name = ty_ex__pojun.name
    })
    to:addToPile("$ty_ex__pojun", cards, false, ty_ex__pojun.name, player.id)
    local equipC = table.filter(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeEquip
    end)
    if #equipC > 0 then
      local card = room:askToChooseCard(player, {
        target = to,
        flag = { card_data = { { "$Throw", equipC } }},
        skill_name = ty_ex__pojun.name,
        prompt = "#ty_ex__pojun-throw"
      })
      room:throwCard({card}, ty_ex__pojun.name, to, player)
    end
    if not player.dead and table.find(cards, function (id)
      return Fk:getCardById(id).type == Card.TypeTrick
    end) then
      player:drawCards(1, ty_ex__pojun.name)
    end
  end,
})

ty_ex__pojun:addEffect(fk.TurnEnd, {
  name = "#ty_ex__pojun_delay",
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return not player.dead and #player:getPile("$ty_ex__pojun") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    player.room:obtainCard(player.id, player:getPile("$ty_ex__pojun"), false)
  end,
})

return ty_ex__pojun
