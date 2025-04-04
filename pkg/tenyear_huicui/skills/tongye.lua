local tongye = fk.CreateSkill {
  name = "tongye",
  tags = { Skill.Compulsory },
  dynamic_desc = function (self, player, lang)
    local str = {}
    for i = 4, 1, -1 do
      if player:getMark(self.name) <= i then
        table.insert(str, "<font color=\'#E0DB2F\'>"..Fk:translate("tongye_"..i).."</font>")
      else
        table.insert(str, Fk:translate("tongye_"..i))
      end
    end
    return "tongye_inner:"..table.concat(str, "<br>")
  end,
}

Fk:loadTranslationTable{
  ["tongye"] = "统业",
  [":tongye"] = "锁定技，游戏开始时，或当其他角色死亡后，你根据场上势力数（对于其他角色仅计入魏蜀吴群）获得对应效果：<br>"..
  "不大于4，手牌上限+3；<br>不大于3，你的攻击范围+3；<br>不大于2，出牌阶段使用【杀】次数上限+3；<br>为1，你回复3点体力。<br>"..
  "每满足超过一项，你摸牌阶段摸牌数+1。",

  [":tongye_inner"] = "锁定技，游戏开始时，或当其他角色死亡后，你根据场上势力数（对于其他角色仅计入魏蜀吴群）获得对应效果：<br>{1}<br>"..
  "每满足超过一项，你摸牌阶段摸牌数+1。",
  ["tongye_4"] = "不大于4，手牌上限+3；",
  ["tongye_3"] = "不大于3，你的攻击范围+3；",
  ["tongye_2"] = "不大于2，出牌阶段使用【杀】次数上限+3；",
  ["tongye_1"] = "为1，你回复3点体力。",

  ["$tongye1"] = "白首全金瓯，著风流于春秋。",
  ["$tongye2"] = "长戈斩王气，统大业于四海。",
}

local sepc = {
  anim_type = "support",
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(tongye.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local kingdoms = {}
    for _, p in ipairs(room.alive_players) do
      if p ~= player then
        if table.contains({"wei", "shu", "wu", "qun"}, p.kingdom) then
          table.insertIfNeed(kingdoms, p.kingdom)
        end
      else
        table.insertIfNeed(kingdoms, p.kingdom)
      end
    end
    room:setPlayerMark(player, tongye.name, #kingdoms)
    if #kingdoms == 1 then
      room:recover{
        who = player,
        num = 3,
        recoverBy = player,
        skillName = tongye.name,
      }
    end
  end,
}

tongye:addEffect(fk.GameStart, sepc)
tongye:addEffect(fk.Deathed, sepc)

tongye:addEffect(fk.DrawNCards, {
  anim_type = "drawcard",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(tongye.name) and
      player:getMark(tongye.name) > 0 and player:getMark(tongye.name) < 4
  end,
  on_use = function(self, event, target, player, data)
    data.n = data.n + 4 - player:getMark(tongye.name)
  end,
})

tongye:addEffect("maxcards", {
  correct_func = function(self, player)
    if player:hasSkill(tongye.name) and player:getMark(tongye.name) > 0 and player:getMark(tongye.name) <= 4
    then
      return 3
    end
  end,
})

tongye:addEffect("atkrange", {
  correct_func = function (skill, from)
    if from:hasSkill(tongye.name) and from:getMark(tongye.name) > 0 and from:getMark(tongye.name) <= 3
    then
      return 3
    end
  end,
})

tongye:addEffect("targetmod", {
  residue_func = function(self, player, skill, scope)
    if skill.trueName == "slash_skill" and player:hasSkill(tongye.name) and
      player:getMark(tongye.name) > 0 and player:getMark(tongye.name) <= 2
    then
      return 3
    end
  end,
})

return tongye
