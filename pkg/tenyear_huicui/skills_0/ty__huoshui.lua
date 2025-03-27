local ty__huoshui = fk.CreateSkill {
  name = "ty__huoshui"
}

Fk:loadTranslationTable{
  ['ty__huoshui'] = '祸水',
  ['ty__huoshui_active'] = '祸水',
  ['#ty__huoshui-choose'] = '祸水：选择至多%arg名角色，按照选择的顺序：<br>1.本回合非锁定技失效，2.交给你一张手牌，3.弃置装备区里的所有牌',
  [':ty__huoshui'] = '准备阶段，你可以令至多X名其他角色（X为你已损失体力值，至少为1，至多为3）按你选择的顺序依次执行一项：1.本回合所有非锁定技失效；2.交给你一张手牌；3.弃置装备区里的所有牌。',
  ['$ty__huoshui1'] = '呵呵，走不动了嘛。',
  ['$ty__huoshui2'] = '别走了，再玩一会儿嘛。',
}

ty__huoshui:addEffect(fk.EventPhaseStart, {
  anim_type = "control",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(ty__huoshui.name) and player.phase == Player.Start
  end,
  on_cost = function(self, event, target, player, data)
    local n = math.max(player:getLostHp(), 1)
    n = math.min(n, 3)
    return player.room:askToUseActiveSkill(player, {
      skill_name = "ty__huoshui_active",
      prompt = "#ty__huoshui-choose:::"..tostring(n),
      cancelable = true,
      extra_data = {},
      no_indicate = false
    })
  end,
})

return ty__huoshui
