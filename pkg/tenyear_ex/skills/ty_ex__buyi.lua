local ty_ex__buyi = fk.CreateSkill {
  name = "ty_ex__buyi"
}

Fk:loadTranslationTable{
  ['ty_ex__buyi'] = '补益',
  ['#ty_ex__buyi-invoke'] = '补益：你可以展示 %dest 一张手牌，若为非基本牌则弃置并回复1点体力，若弃置前为唯一手牌则其摸一张牌。',
  [':ty_ex__buyi'] = '当一名角色进入濒死状态时，你可以展示其一张手牌：若不为基本牌，则其弃置此牌并回复1点体力。若此牌移动前是其唯一的手牌，其摸一张牌。',
  ['$ty_ex__buyi1'] = '有老身在，阁下勿忧。',
  ['$ty_ex__buyi2'] = '如此佳婿，谁敢伤之？',
}

ty_ex__buyi:addEffect(fk.EnterDying, {
  anim_type = "support",
  can_trigger = function(self, event, target, player)
    return player:hasSkill(ty_ex__buyi.name) and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player)
    return player.room:askToSkillInvoke(player, {
      skill_name = ty_ex__buyi.name,
      prompt = "#ty_ex__buyi-invoke::" .. target.id
    })
  end,
  on_use = function(self, event, target, player)
    local room = player.room
    if #target.player_cards[Player.Hand] == 1 then
      event:setCostData(player, true)
    end
    local id = room:askToChooseCard(player, {
      target = target,
      flag = "h",
      skill_name = ty_ex__buyi.name
    })
    target:showCards({id})
    if Fk:getCardById(id).type ~= Card.TypeBasic then
      room:throwCard({id}, ty_ex__buyi.name, target, target)
      room:recover{
        who = target,
        num = 1,
        recoverBy = player,
        skillName = ty_ex__buyi.name
      }
      if event:getCostData(player) ~= nil then
        target:drawCards(1, ty_ex__buyi.name)
      end
    end
  end,
})

return ty_ex__buyi
