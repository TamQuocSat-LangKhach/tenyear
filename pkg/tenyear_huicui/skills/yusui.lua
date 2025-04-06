local yusui = fk.CreateSkill {
  name = "yusui",
}

Fk:loadTranslationTable{
  ["yusui"] = "玉碎",
  [":yusui"] = "每回合限一次，当你成为其他角色使用黑色牌的目标后，你可以失去1点体力，然后选择一项：1.令其弃置手牌至与你相同；"..
  "2.令其失去体力值至与你相同。",

  ["#yusui"] = "玉碎：你可以失去1点体力，令 %dest 弃置手牌或失去体力至与你相同",
  ["yusui_discard"] = "%dest弃置手牌至与你相同",
  ["yusui_loseHp"] = "%dest失去体力至与你相同",

  ["$yusui1"] = "宁为玉碎，不为瓦全！",
  ["$yusui2"] = "生义相左，舍生取义。",
}

yusui:addEffect(fk.TargetConfirmed, {
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(yusui.name) and
      data.from ~= player and not data.from.dead and data.card.color == Card.Black and
      player:usedSkillTimes(yusui.name, Player.HistoryTurn) == 0
  end,
  on_cost = function (self, event, target, player, data)
    local room = player.room
    if room:askToSkillInvoke(player, {
      skill_name = yusui.name,
      prompt = "#yusui-invoke::"..data.from.id,
    }) then
      event:setCostData(self, {tos = {data.from}})
      return true
    end

  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, yusui.name)
    if player.dead or data.from.dead then return end
    local choices = {}
    if data.from:getHandcardNum() > player:getHandcardNum() then
      table.insert(choices, "yusui_discard::"..data.from.id)
    end
    if data.from.hp > player.hp then
      table.insert(choices, "yusui_loseHp::"..data.from.id)
    end
    if #choices == 0 then return end
    local choice = room:askToChoice(player, {
      choices = choices,
      skill_name = yusui.name
    })
    if choice:startsWith("yusui_discard") then
      local n = data.from:getHandcardNum() - player:getHandcardNum()
      room:askToDiscard(data.from, {
        min_num = n,
        max_num = n,
        include_equip = false,
        skill_name = yusui.name,
        cancelable = false,
      })
    else
      room:loseHp(data.from, data.from.hp - player.hp, yusui.name)
    end
  end,
})

return yusui
