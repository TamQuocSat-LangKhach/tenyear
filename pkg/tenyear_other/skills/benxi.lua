local benxi = fk.CreateSkill {
  name = "tycl__benxi",
  tags = { Skill.Compulsory, Skill.Switch }
}

Fk:loadTranslationTable{
  ["tycl__benxi"] = "奔袭",
  [":tycl__benxi"] = "锁定技，转换技，当你失去手牌后，阳：随机念一句含有wuyi的技能台词；阴：获得你上次以此法念出台词的技能"..
  "直到你下回合开始，若已拥有则改为对一名角色造成1点伤害。",

  ["@tycl__benxi"] = "奔袭",
  ["#tycl__benxi-choose"] = "奔袭：对一名角色造成1点伤害",
}

local benxiPool = {
  {"mou__mingren", 1},
  {"longyuan", 1},
  {"os__fenwang", 1},
  {"shuyong", 1},
  {"dengli", 1},
  {"ty__zhengnan", 2},
  {"qingbei", 2},
  {"duorui", 2},
  {"jixian", 2},
  {"sijun", 2},
  {"zongfan", 2},
  {"chanshuang", 1},
  {"sp__youdi", 1},
  {"jishan", 1},
  {"qice", 1},
  {"ty_ex__yonglue", 2},
  {"pizhi", 1},
  {"quanmou", 1},
  {"fuxun", 1},
  {"os_ex__yuzhang", 1},
  {"minze", 1},
  {"porui", 2},
  {"qingtan", 1},
  {"choulue", 2},
  {"qizhi", 2},
  {"fujian", 2},
  {"xiuwen", 2},
  {"zhaoluan", 1},
  {"yisuan", 1},
  {"xiaowu", 1},
  {"fangdu", 2},
  {"ty__shefu", 1},
  {"os__juexing", 1},
  {"weiwu", 2},
  {"daigong", 2},
  {"zhaohan", 1},
  {"ol__wuji", 1},
  {"ol__hongyuan", 1},
  {"daiyan", 2},
  {"xiantu", 2},
  {"ol__duorui", 1},
}

benxi:addEffect(fk.AfterCardsMove, {
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(benxi.name) then
      for _, move in ipairs(data) do
        if move.from == player then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand then
              return true
            end
          end
        end
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local isYang = player:getSwitchSkillState(benxi.name, true) == fk.SwitchYang

    if isYang then
      local sData = table.random(benxiPool)
      player:chat(string.format("$%s:%d", sData[1], sData[2]))
      room:setPlayerMark(player, "@tycl__benxi", sData[1])
    else
      local skillName = player:getMark("@tycl__benxi")
      if not Fk.skills[skillName] then return end
      if player:hasSkill(skillName, true) then
        local to = room:askToChoosePlayers(player, {
          targets = room.alive_players,
          min_num = 1,
          max_num = 1,
          prompt = "#tycl__benxi-choose",
          skill_name = benxi.name,
          cancelable = false,
        })[1]
        room:damage{
          from = player,
          to = to,
          damage = 1,
          skillName = benxi.name,
        }
      else
        room:addTableMark(player, benxi.name, skillName)
        room:handleAddLoseSkills(player, skillName)
      end
    end
  end,
})

benxi:addEffect(fk.TurnStart, {
  can_refresh = function(self, event, target, player, data)
    return target == player and player:getMark(benxi.name) ~= 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    room:handleAddLoseSkills(player, "-"..table.concat(player:getTableMark(benxi.name), "|-"))
    room:setPlayerMark(player, benxi.name, 0)
  end,
})

return benxi
