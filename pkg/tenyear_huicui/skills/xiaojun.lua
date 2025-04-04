local xiaojun = fk.CreateSkill {
  name = "xiaojun",
}

Fk:loadTranslationTable{
  ["xiaojun"] = "骁隽",
  [":xiaojun"] = "你使用牌指定其他角色为唯一目标后，你可以弃置其一半手牌（向下取整），若其中有与你使用牌花色相同的牌，你弃置一张手牌。",

  ["#xiaojun-invoke"] = "骁隽：你可以弃置 %dest 一半手牌（%arg张），若其中有%arg2牌，你弃置一张手牌",

  ["$xiaojun1"] = "骁锐敢斗，威震江夏！",
  ["$xiaojun2"] = "得隽为雄，气贯大江！",
}

xiaojun:addEffect(fk.TargetSpecified, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(xiaojun.name) and
      data.to ~= player and data:isOnlyTarget(data.to) and data.to:getHandcardNum() > 1
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = xiaojun.name,
      prompt = "#xiaojun-invoke::"..data.to.id..":"..(data.to:getHandcardNum() // 2)..":"..data.card:getSuitString(),
    }) then
      event:setCostData(self, {tos = {data.to}})
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = data.to:getHandcardNum() // 2
    local cards = room:askToChooseCards(player, {
      target = data.to,
      min = n,
      max = n,
      flag = "h",
      skill_name = xiaojun.name,
    })
    local yes = table.find(cards, function(id)
      return Fk:getCardById(id):compareSuitWith(data.card)
    end)
    room:throwCard(cards, xiaojun.name, data.to, player)
    if yes and not player:isKongcheng() and not player.dead then
      room:askToDiscard(player, {
        min_num = 1,
        max_num = 1,
        include_equip = false,
        skill_name = xiaojun.name,
        cancelable = false,
      })
    end
  end,
})

return xiaojun
