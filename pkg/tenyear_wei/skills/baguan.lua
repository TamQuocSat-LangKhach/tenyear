local baguan = fk.CreateSkill {
  name = "baguan",
}

Fk:loadTranslationTable{
  ["baguan"] = "霸关",
  [":baguan"] = "连招技（单目标牌+武器牌），你可以将至多X张手牌当一张【杀】使用（X为此武器牌的牌名字数），伤害基数等于你用于转化的牌数。",

  ["baguan_viewas"] = "霸关",
  ["#baguan-use"] = "霸关：你可以将至多%arg张手牌当【杀】使用（伤害基数为你选择的牌数）",

  ["$baguan1"] = "颅献白骨观，血祭黄沙场！",
  ["$baguan2"] = "拥酒炙胡马，北虏复唱匈奴歌！",
}

baguan:addEffect(fk.CardUseFinished, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(baguan.name) and
      data.card.sub_type == Card.SubtypeWeapon and
      data.extra_data and data.extra_data.combo_skill and data.extra_data.combo_skill[baguan.name] and
      table.contains(player:getEquipments(Card.SubtypeWeapon), data.card.id) and
      #player:getHandlyIds() > 0
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = Fk:translate(data.card.name, "zh_CN"):len()
    local success, dat = room:askToUseActiveSkill(player, {
      skill_name = "baguan_viewas",
      prompt = "#baguan-use:::"..n,
      cancelable = true,
      extra_data = {
        bypass_times = true,
        baguan = n,
      },
    })
    if success and dat then
      event:setCostData(self, {extra_data = dat})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local dat = event:getCostData(self).extra_data
    local card = Fk:cloneCard("slash")
    card.skillName = baguan.name
    card:addSubcards(dat.cards)
    local use = {
      from = player,
      tos = dat.targets,
      card = card,
      extraUse = true,
      additionalDamage = #dat.cards - 1,
    }
    room:useCard(use)
  end,
})
baguan:addEffect(fk.AfterCardUseDeclared, {
  can_refresh = function (self, event, target, player, data)
    return target == player and player:hasSkill(baguan.name, true)
  end,
  on_refresh = function (self, event, target, player, data)
    local room = player.room
    if data.card.sub_type == Card.SubtypeWeapon then
      room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e ~= room.logic:getCurrentEvent() then
          local use = e.data
          if use.from == player then
            if not use.card.is_passive and not use.card.multiple_targets then
              data.extra_data = data.extra_data or {}
              data.extra_data.combo_skill = data.extra_data.combo_skill or {}
              data.extra_data.combo_skill[baguan.name] = true
            else
              room:setPlayerMark(player, baguan.name, 0)
            end
            return true
          end
        end
      end, 1)
      if player:getMark(baguan.name) == 0 and
        not data.card.is_passive and not data.card.multiple_targets then
        room:setPlayerMark(player, baguan.name, 1)
      end
    else
      room:setPlayerMark(player, baguan.name, 0)
    end
  end,
})

return baguan
