local juanjia = fk.CreateSkill {
  name = "juanjia",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ["juanjia"] = "捐甲",
  [":juanjia"] = "锁定技，游戏开始时，你废除防具栏，然后获得一个额外的武器栏。<br>"..
  "<font color=>注：UI未适配多武器栏，需要等待游戏软件版本更新，请勿反馈显示问题。</font>",

  ["$juanjia1"] = "尚攻者弃守，其提双刃、斩万敌。",
  ["$juanjia2"] = "舍衣释力，提兵趋敌。",
}

juanjia:addEffect(fk.GameStart, {
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(juanjia.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:abortPlayerArea(player, { Player.ArmorSlot })
    room:addPlayerEquipSlots(player, { Player.WeaponSlot })
  end,
})

return juanjia
