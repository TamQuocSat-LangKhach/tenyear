local lvli = fk.CreateSkill {
  name = "lvli",
  dynamic_desc = function (self, player, lang)
    if player:usedSkillTimes("beishui", Player.HistoryGame) > 0 then
      return "lvli_ex2"
    end
    if player:usedSkillTimes("choujue", Player.HistoryGame) > 0 then
      return "lvli_ex1"
    end
  end,
}

Fk:loadTranslationTable{
  ["lvli"] = "膂力",
  [":lvli"] = "每名角色的回合限一次，当你造成伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。",

  [":lvli_ex1"] = "每名角色的回合限一次（你的回合限两次），当你造成伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。",
  [":lvli_ex2"] = "每名角色的回合限一次，当你造成或受到伤害后，你可以将手牌摸至与体力值相同或将体力回复至与手牌数相同。",

  ["#lvli-invoke"] = "膂力：是否将手牌/体力值回复至与体力值/手牌数相同？",

  ["$lvli1"] = "此击若中，万念俱灰！",
  ["$lvli2"] = "姿器膂力，万人之雄。",
}

local spec = {
  on_cost = function (self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = lvli.name,
      prompt = "#lvli-invoke",
    })
  end,
  on_use = function(self, event, target, player, data)
    local n = player:getHandcardNum() - player.hp
    if n < 0 then
      player:drawCards(-n, lvli.name)
    else
      player.room:recover{
        who = player,
        num = math.min(n, player.maxHp - player.hp),
        recoverBy = player,
        skillName = lvli.name,
      }
    end
  end,}

lvli:addEffect(fk.Damage, {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lvli.name) and
      player:getHandcardNum() ~= player.hp and
      player:usedSkillTimes(lvli.name, Player.HistoryTurn) <
        (player:usedSkillTimes("choujue", Player.HistoryGame) > 0 and player.room.current == player and 2 or 1)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

lvli:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(lvli.name) and
      player:usedSkillTimes("beishui", Player.HistoryGame) > 0 and
      player:getHandcardNum() ~= player.hp and
      player:usedSkillTimes(lvli.name, Player.HistoryTurn) <
        (player:usedSkillTimes("choujue", Player.HistoryGame) > 0 and player.room.current == player and 2 or 1)
  end,
  on_cost = spec.on_cost,
  on_use = spec.on_use,
})

return lvli
