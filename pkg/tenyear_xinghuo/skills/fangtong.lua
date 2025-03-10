local fangtong = fk.CreateSkill {
  name = "fangtong"
}

Fk:loadTranslationTable{
  ['fangtong'] = '方统',
  ['zhangliang_fang'] = '方',
  ['#fangtong-invoke'] = '方统：你可以弃置一张牌发动“方统”',
  ['#fangtong-discard'] = '方统：将至少一张“方”置入弃牌堆，若和之前弃置的牌点数之和为36则可电人',
  ['#fangtong-choose'] = '方统：对一名其他角色造成3点雷电伤害',
  [':fangtong'] = '结束阶段，你可以弃置一张牌，然后将至少一张“方”置入弃牌堆。若此牌与你以此法置入弃牌堆的所有“方”的点数之和为36，你对一名其他角色造成3点雷电伤害。',
  ['$fangtong1'] = '统领方队，为民意所举！',
  ['$fangtong2'] = '三十六方，必为大统！',
}

fangtong:addEffect(fk.EventPhaseStart, {
  anim_type = "offensive",
  can_trigger = function(self, player)
    return player.phase == Player.Finish and #player:getPile("zhangliang_fang") > 0 and
      not player:isNude()
  end,
  on_cost = function(self, player)
    local card = player.room:askToDiscard(player, {
      min_num = 1,
      max_num = 1,
      include_equip = true,
      skill_name = fangtong.name,
      cancelable = true,
      prompt = "#fangtong-invoke",
      skip = true
    })

    if #card > 0 then
      event:setCostData(self, card[1])
      return true
    end
  end,
  on_use = function(self, player)
    local room = player.room
    room:throwCard(event:getCostData(self), fangtong.name, player, player)
    local cards = room:askToCards(player, {
      min_num = 1,
      max_num = 0xFFFF,
      include_equip = false,
      pattern = ".|.|.|zhangliang_fang|.|.",
      prompt = "#fangtong-discard",
      expand_pile = "zhangliang_fang"
    })

    if #cards == 0 then
      cards = table.random(player:getPile("zhangliang_fang"), 1)
    end
    room:throwCard(cards, fangtong.name, player, player)

    local sum = Fk:getCardById(event:getCostData(self)).number
    for _, id in ipairs(cards) do
      sum = sum + Fk:getCardById(id).number
    end

    if sum == 36 then
      local targets = table.map(room:getOtherPlayers(player, false), Util.IdMapper)
      local tos = room:askToChoosePlayers(player, {
        targets = targets,
        min_num = 1,
        max_num = 1,
        prompt = "#fangtong-choose",
        skill_name = fangtong.name
      })
      room:damage {
        from = player,
        to = room:getPlayerById(tos[1]),
        damage = 3,
        damageType = fk.ThunderDamage,
        skillName = fangtong.name,
      }
    end
  end,
})

return fangtong
