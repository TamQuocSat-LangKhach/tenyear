
local ruyi = fk.CreateActiveSkill{
  name = "ruyi",
  prompt = "#ruyi",
  frequency = Skill.Compulsory,
  card_num = 0,
  target_num = 0,
  interaction = function()
    return UI.Spin { from = 1, to = 4 }
  end,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "@ruyi", self.interaction.data)
  end,
}
local ruyi_attackrange = fk.CreateAttackRangeSkill{
  name = "#ruyi_attackrange",
  fixed_func = function (self, player)
    if player:hasSkill(ruyi) and player:getMark("@ruyi") ~= 0 then
      return player:getMark("@ruyi")
    end
  end,
}
local ruyi_filter = fk.CreateFilterSkill{
  name = "#ruyi_filter",
  card_filter = function(self, card, player)
    return player:hasSkill(ruyi) and card.sub_type == Card.SubtypeWeapon and table.contains(player.player_cards[Player.Hand], card.id)
  end,
  view_as = function(self, card)
    local c = Fk:cloneCard("slash", card.suit, card.number)
    c.skillName = "ruyi"
    return c
  end,
}
local ruyi_targetmod = fk.CreateTargetModSkill{
  name = "#ruyi_targetmod",
  bypass_times = function(self, player, skill, scope)
    return player:hasSkill(ruyi) and player:getMark("@ruyi") <= 1 and skill.trueName == "slash_skill" and scope == Player.HistoryPhase
  end,
}
local ruyi_trigger = fk.CreateTriggerSkill{
  name = "#ruyi_trigger",
  mute = true,
  events = {fk.AfterCardUseDeclared, fk.AfterCardTargetDeclared, fk.EventAcquireSkill, fk.GameStart},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if event == fk.EventAcquireSkill then
      return data == ruyi and target == player and player.room:getBanner("RoundCount")
    elseif event == fk.GameStart then
      return player:hasShownSkill(ruyi, true)
    end
    if player == target and player:hasSkill(ruyi) and data.card.trueName == "slash" then
      if event == fk.AfterCardUseDeclared then
        return player:getMark("@ruyi") == 2 or player:getMark("@ruyi") == 3
      else
        return player:getMark("@ruyi") == 4 and #player.room:getUseExtraTargets(data) > 0
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill or event == fk.GameStart then
      room:setPlayerMark(player, "@ruyi", 3)
      if table.contains(player:getAvailableEquipSlots(), Player.WeaponSlot) then
        room:abortPlayerArea(player, Player.WeaponSlot)
      end
    else
      if player:getMark("@ruyi") == 2 then
        data.additionalDamage = (data.additionalDamage or 0) + 1
      elseif player:getMark("@ruyi") == 3 then
        data.disresponsiveList = table.map(room.alive_players, Util.IdMapper)
      else
        local to = room:askForChoosePlayers(player, room:getUseExtraTargets(data),
        1, 1, "#ruyi-choose:::"..data.card:toLogString(), ruyi.name, true)
        if #to > 0 then
          table.insert(data.tos, to)
        end
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["ruyi"] = "如意",
  [":ruyi"] = "锁定技，你手牌中的武器牌均视为【杀】，你废除武器栏。你的攻击范围基数为3，出牌阶段限一次，你可以调整攻击范围（1~4）。若你的攻击范围基数为：1，使用【杀】无次数限制；2，使用【杀】伤害+1；3，使用【杀】无法响应；4，使用【杀】可额外选择一个目标。",
  ["@ruyi"] = "如意",
  ["#ruyi"] = "如意：选择你的攻击范围",
  ["#ruyi-choose"] = "如意：%arg 可额外选择一个目标",

  ["$ruyi1"] = "俺老孙来也！",
  ["$ruyi2"] = "吃俺老孙一棒！",
}

local getArm = function(room, armName)
  local arm
  for _, id in ipairs(room.void) do
    if Fk:getCardById(id).name == armName then
      room:setCardMark(Fk:getCardById(id), MarkEnum.DestructOutMyEquip, 1)
      arm = id
      break
    end
  end
  if not arm then
    local card = room:printCard(armName, Card.NoSuit, 0)
    room:setCardMark(card, MarkEnum.DestructOutMyEquip, 1)
    arm = card.id
  end
  return arm
end

local qiexie = fk.CreateTriggerSkill{
  name = "qiexie",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(self) and
      player.phase == Player.Start and
      player:hasEmptyEquipSlot(Card.SubtypeWeapon)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local availableGenerals = room:getTag("qiexieGenerals") or {}
    if #availableGenerals == 0 then
      for _, general in ipairs(room.general_pile) do
        if
          table.find(
            Fk.generals[general]:getSkillNameList(),
            function(skillName)
              local skill = Fk.skills[skillName]
              return
                table.contains({ Skill.Compulsory, Skill.Frequent, Skill.NotFrequent }, skill.frequency) and
                not skill:isSwitchSkill() and
                not skill.lordSkill and
                not skill.isHiddenSkill and
                #skill.attachedKingdom == 0 and
                string.find(Fk:translate(":" .. skill.name, "zh_CN"), "【杀】")
            end
          )
        then
          table.insert(availableGenerals, general)
        end
      end

      if #availableGenerals == 0 then
        return false
      end

      room:setTag("qiexieGenerals", availableGenerals)
    end

    availableGenerals = table.filter(
      room:getTag("qiexieGenerals") or {},
      function(general)
        return
          table.contains(room.general_pile, general) and
          not table.contains({ player.general, player.deputyGeneral }, general)
      end
    )

    if #availableGenerals > 0 then
      availableGenerals = table.random(availableGenerals, 5)
      local weaponEmpty = #player:getAvailableEquipSlots(Card.SubtypeWeapon) - #player:getEquipments(Card.SubtypeWeapon)
      local hasLeftArm = table.find(
        player:getCardIds("e"),
        function(id) return Fk:getCardById(id).name == "goddianwei_left_arm" end
      )
      local hasRightArm = table.find(
        player:getCardIds("e"),
        function(id) return Fk:getCardById(id).name == "goddianwei_right_arm" end
      )

      if weaponEmpty < 1 and not (hasLeftArm and hasRightArm) then
        return false
      end

      if hasLeftArm or hasRightArm then
        weaponEmpty = 1
      else
        weaponEmpty = math.min(2, weaponEmpty)
      end

      local result = player.room:askForCustomDialog(
        player,
        self.name,
        "packages/utility/qml/ChooseGeneralsAndChoiceBox.qml",
        {
          availableGenerals,
          {"OK"},
          "#qiexie-choose",
          {},
          1,
          weaponEmpty,
        }
      )

      local names
      if result == "" then
        names = table.random(availableGenerals, 1)
      else
        names = json.decode(result).cards
      end

      if #names > 0 then
        for i = 1, #names do
          local generalName = names[i]
          hasLeftArm = table.find(
            player:getCardIds("e"),
            function(id) return Fk:getCardById(id).name == "goddianwei_left_arm" end
          )
          hasRightArm = table.find(
            player:getCardIds("e"),
            function(id) return Fk:getCardById(id).name == "goddianwei_right_arm" end
          )
          if hasLeftArm and hasRightArm then
            break
          elseif hasLeftArm then
            room:setPlayerMark(player, "@qiexie_right", { generalName, Fk.generals[generalName].maxHp })
            table.removeOne(room.general_pile, generalName)
            local skillList = {}
            for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList()) do
              local skill = Fk.skills[skillName]
              if
                table.contains({ Skill.Compulsory, Skill.Frequent, Skill.NotFrequent }, skill.frequency) and
                not skill:isSwitchSkill() and
                not skill.lordSkill and
                not skill.isHiddenSkill and
                #skill.attachedKingdom == 0 and
                string.find(Fk:translate(":" .. skill.name, "zh_CN"), "【杀】")
              then
                table.insert(skillList, skillName)
              end
            end
            if #skillList > 0 then
              room:setPlayerMark(player, "qiexie_right_skills", skillList)
            end

            local rightArm = getArm(room, "goddianwei_right_arm")
            room:moveCardIntoEquip(player, rightArm, self.name, false)
          else
            room:setPlayerMark(player, "@qiexie_left", { generalName, Fk.generals[generalName].maxHp })
            table.removeOne(room.general_pile, generalName)
            local skillList = {}
            for _, skillName in ipairs(Fk.generals[generalName]:getSkillNameList()) do
              local skill = Fk.skills[skillName]
              if
                table.contains({ Skill.Compulsory, Skill.Frequent, Skill.NotFrequent }, skill.frequency) and
                not skill:isSwitchSkill() and
                not skill.lordSkill and
                not skill.isHiddenSkill and
                #skill.attachedKingdom == 0 and
                string.find(Fk:translate(":" .. skill.name, "zh_CN"), "【杀】")
              then
                table.insert(skillList, skillName)
              end
            end
            if #skillList > 0 then
              room:setPlayerMark(player, "qiexie_left_skills", skillList)
            end

            local leftArm = getArm(room, "goddianwei_left_arm")
            room:moveCardIntoEquip(player, leftArm, self.name, false)
          end
        end
      end
    end
  end,
}
local qiexieFilter = fk.CreateFilterSkill{
  name = "#qiexie_filter",
  equip_skill_filter = function(self, skill, player)
    if player then
      local leftSkills = player:getTableMark("qiexie_left_skills")
      local rightSkills = player:getTableMark("qiexie_right_skills")
      if table.contains(leftSkills, skill.name) then
        return "goddianwei_left_arm"
      elseif table.contains(rightSkills, skill.name) then
        return "goddianwei_right_arm"
      end
    end
  end,
}
Fk:loadTranslationTable{
  ["qiexie"] = "挈挟",
  [":qiexie"] = "锁定技，准备阶段开始时，若你有空置的武器栏，则你随机观看武将牌堆中五张武将牌" ..
  "（须带有描述中含有“【杀】”且不具有除锁定技以外标签的技能），将其中至少一张当武器牌置入装备区" ..
  "（称为【左膀】和【右臂】，无花色点数，攻击范围为对应武将牌的体力上限，效果为其符合上述条件的技能，" ..
  "离开你的装备区时销毁）。",
  ["#qiexie-choose"] = "请选择武将牌作为你的装备牌（右键或长按查看技能）",
  ["@qiexie_left"] = "左膀",
  ["@qiexie_right"] = "右臂",

  ["$qiexie1"] = "今挟双戟搏战，定护主公太平。",
  ["$qiexie2"] = "吾乃典韦是也，谁敢向前？谁敢向前！",
}

local huiwan = fk.CreateTriggerSkill {
  name = "huiwan",
  anim_type = "drawcard",
  events = {fk.BeforeDrawCard},
  can_trigger = function(self, event, target, player, data)
    if not (player == target and player:hasSkill(self) and data.num > 0) then
      return false
    end

    local availableNames = table.filter(
      player.room:getTag("huiwanAllCardNames") or {},
      function(name)
        return not table.contains(player:getTableMark("huiwan_card_names-turn"), name)
      end
    )

    if #availableNames > 0 then
      return 
        table.find(
          player.room.draw_pile,
          function(id) return table.contains(availableNames, Fk:getCardById(id).trueName) end
        )
    end

    return false
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local allCardNames = table.filter(
      room:getTag("huiwanAllCardNames") or {},
      function(name)
        return not table.contains(player:getTableMark("huiwan_card_names-turn"), name)
      end
    )

    local chioces = {}
    for _, name in ipairs(allCardNames) do
      if table.find(room.draw_pile, function(id) return Fk:getCardById(id).trueName == name end) then
        table.insert(chioces, name)
      end
    end

    local result = room:askForChoices(player, chioces, 1, data.num, self.name, "#huiwan-choice:::" .. data.num)
    if #result > 0 then
      self.cost_data = result
      return true
    end

    return false
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local namesChosen = table.simpleClone(self.cost_data)
    local cardNamesRecord = player:getTableMark("huiwan_card_names-turn")
    table.insertTableIfNeed(cardNamesRecord, table.map(namesChosen, function(name) return name end))
    room:setPlayerMark(player, "huiwan_card_names-turn", cardNamesRecord)

    local toDraw = {}
    for i = #room.draw_pile, 1, -1 do
      local card = Fk:getCardById(room.draw_pile[i])
      if table.contains(namesChosen, card.trueName) then
        table.removeOne(namesChosen, card.trueName)
        table.insert(toDraw, card.id)
      end
    end

    if #toDraw > 0 then
      room:obtainCard(player, toDraw, false, fk.ReasonPrey, player.id, self.name)
    end

    data.num = data.num - #toDraw
    return data.num < 1
  end,

  refresh_events = {fk.EventAcquireSkill},
  can_refresh = function(self, event, target, player, data)
    return target == player and data == self and not player.room:getTag("huiwanAllCardNames")
  end,
  on_refresh = function(self, event, target, player, data)
    local allCardNames = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if (card.type == Card.TypeBasic or card:isCommonTrick()) then
        table.insertIfNeed(allCardNames, card.trueName)
      end
    end

    player.room:setTag("huiwanAllCardNames", allCardNames)
  end,
}
Fk:loadTranslationTable{
  ["huiwan"] = "会玩",
  [":huiwan"] = "每回合每种牌名限一次，当你摸牌时，你可以选择至多等量牌堆中有的基本牌或普通锦囊牌牌名，然后改为从牌堆中获得你选择的牌。",
  ["#huiwan-choice"] = "会玩：你可选择至多 %arg 个牌名，本次改为摸所选牌名的牌",

  ["$huiwan1"] = "金珠弹黄鹂，玉带做秋千，如此游戏人间。",
  ["$huiwan2"] = "小爷横行江东，今日走马、明日弄鹰。",
}

xiaosunquan:addSkill(huiwan)

local huanli = fk.CreateTriggerSkill {
  name = "huanli",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if not (target == player and player:hasSkill(self) and player.phase == Player.Finish) then
      return false
    end

    local aimedList = {}
    local canTrigger = false
    player.room.logic:getEventsOfScope(
      GameEvent.UseCard,
      1,
      function(e)
        local targets = TargetGroup:getRealTargets(e.data[1].tos)
        for _, pId in ipairs(targets) do
          aimedList[pId] = (aimedList[pId] or 0) + 1
          canTrigger = canTrigger or aimedList[pId] > 2
        end
        return false
      end,
      Player.HistoryTurn
    )

    if canTrigger then
      self.cost_data = aimedList
      return true
    end

    return false
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local aimedList = self.cost_data
    local usedTimes = 0
    local lastTarget
    if (aimedList[player.id] or 0) > 2 then
      local tos = room:askForChoosePlayers(
        player,
        table.map(room:getOtherPlayers(player, false), Util.IdMapper),
        1,
        1,
        "#huanli_zhangzhao-choose",
        self.name
      )

      if #tos > 0 then
        usedTimes = usedTimes + 1
        lastTarget = tos[1]

        local to = room:getPlayerById(tos[1])
        local zhangzhao = table.filter({ "zhijian", "guzheng" }, function(skill) return not to:hasSkill(skill, true, true) end)
        local skillsExist = to:getTableMark("@@huanli")
        table.insertTableIfNeed(skillsExist, zhangzhao)
        room:setPlayerMark(to, "@@huanli", skillsExist)

        if #zhangzhao > 0 then
          room:handleAddLoseSkills(to, table.concat(zhangzhao, "|"))
        end
      end
    end

    local availableTargets = {}
    for pId, num in pairs(aimedList) do
      if pId ~= player.id and pId ~= lastTarget and num > 2 then
        table.insert(availableTargets, pId)
      end
    end

    if #availableTargets == 0 then
      return false
    end

    local tos = room:askForChoosePlayers(player, availableTargets, 1, 1, "#huanli_zhouyu-choose", self.name)
    if #tos > 0 then
      usedTimes = usedTimes + 1
      local to = room:getPlayerById(tos[1])
      local zhouyu = table.filter({ "ex__yingzi", "ex__fanjian" }, function(skill) return not to:hasSkill(skill, true, true) end)
      local skillsExist = to:getTableMark("@@huanli")
      table.insertTableIfNeed(skillsExist, zhouyu)
      room:setPlayerMark(to, "@@huanli", skillsExist)

      if #zhouyu > 0 then
        room:handleAddLoseSkills(to, table.concat(zhouyu, "|"))
      end
    end

    if usedTimes > 1 and not player:hasSkill("ex__zhiheng") then
      room:setPlayerMark(player, "huanli_sunquan-turn", 1)
      player.tag["huanli_sunquan"] = true
      room:handleAddLoseSkills(player, "ex__zhiheng")
    end
  end,
}
local huanliLose = fk.CreateTriggerSkill {
  name = "#huanli_lose",
  mute = true,
  events = {fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      (
        player:getMark("@@huanli") ~= 0 or
        (player:getMark("huanli_sunquan-turn") == 0 and player.tag["huanli_sunquan"])
      )
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player:getMark("@@huanli") ~= 0 then
      local huanliSkills = table.simpleClone(player:getTableMark("@@huanli"))
      room:setPlayerMark(player, "@@huanli", 0)
      if #huanliSkills > 0 then
        room:handleAddLoseSkills(player, table.concat(table.map(huanliSkills, function(skill) return "-" .. skill end), "|"))
      end
    end

    if player:getMark("huanli_sunquan-turn") == 0 and player.tag["huanli_sunquan"] then
      player.tag["huanli_sunquan"] = nil
      room:handleAddLoseSkills(player, "-ex__zhiheng")
    end
  end,
}
local huanliNullify = fk.CreateInvaliditySkill {
  name = "#huanli_nullify",
  invalidity_func = function(self, from, skill)
    return
      from:getMark("@@huanli") ~= 0 and
      not table.contains(from:getTableMark("@@huanli"), skill.name) and
      skill:isPlayerSkill(from)
  end
}
Fk:loadTranslationTable{
  ["huanli"] = "唤理",
  [":huanli"] = "结束阶段开始时，若你于本回合内使用牌指定自己为目标至少三次，你可以令一名其他角色所有技能失效（因本技能而获得的技能除外），" ..
  "且其获得“直谏”和“固政”直到其下回合结束。若你于本回合内使用牌指定同一名其他角色为目标至少三次，你可选择这些角色中的一名（不能选择前者选择的角色），" ..
  "令其所有技能失效（因本技能而获得的技能除外），且其获得“英姿”和“反间”直到其下回合结束。若你两项均执行，则你获得“制衡”直到你下回合结束。",
  ["@@huanli"] = "唤理",
  ["#huanli_lose"] = "唤理",
  ["#huanli_zhangzhao-choose"] = "唤理：你可令一名其他角色技能失效且获得“直谏”“固政”直到其下回合结束",
  ["#huanli_zhouyu-choose"] = "唤理：你可令其中一名角色技能失效且获得“英姿”“反间”直到其下回合结束",

  ["$huanli1"] = "金乌当空，汝欲与我辩日否？",
  ["$huanli2"] = "童言无忌，童言有理！",
}

local qixin = fk.CreateActiveSkill{
  name = "qixin",
  anim_type = "switch",
  card_num = 0,
  target_num = 0,
  prompt = "#qixin-active",
  switch_skill_name = "qixin",
  can_use = function(self, player)
    return player:getMark("qixinUsed-phase") == 0 and player:getMark("qixin_restore") > 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:setPlayerMark(player, "qixinUsed-phase", 1)
    room:setPlayerProperty(
      player,
      "gender",
      player:getSwitchSkillState(self.name, true) == fk.SwitchYin and General.Male or General.Female
    )
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "male" or "female"), 1)
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "female" or "male"), 0)

    local hpRecord = player:getMark("qixin_restore")
    room:setPlayerMark(player, "qixin_restore", player.hp)
    room:changeHp(player, hpRecord - player.hp)
  end,
}
local qixinTrigger = fk.CreateTriggerSkill{
  name = "#qixin_trigger",
  mute = true,
  main_skill = qixin,
  switch_skill_name = "qixin",
  events = {fk.AskForPeachesDone},
  can_trigger = function (self, event, target, player, data)
    return target == player and player.dying and player:getMark("qixin_restore") > 0
  end,
  on_cost = Util.TrueFunc,
  on_use = function (self, event, target, player, data)
    local room = player.room

    room:setPlayerProperty(
      player,
      "gender",
      player:getSwitchSkillState("qixin", true) == fk.SwitchYin and General.Male or General.Female
    )
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "male" or "female"), 1)
    room:setPlayerMark(player, "@!qixi_" .. (player.gender == General.Male and "female" or "male"), 0)

    local hpRecord = player:getMark("qixin_restore")
    room:setPlayerMark(player, "qixin_restore", 0)
    room:changeHp(player, hpRecord - player.hp)
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.EventAcquireSkill, fk.EventLoseSkill},
  can_refresh = function(self, event, target, player, data)
    if event == fk.AfterCardUseDeclared then
      return target == player and player:getMark("qixinUsed-phase") > 0
    end

    return
      target == player and
      data == self and
      not (event == fk.EventLoseSkill and player:getMark("qixin_restore") == 0)
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "qixin_restore", player.maxHp)
      room:setPlayerProperty(player, "gender", General.Male)
      room:setPlayerMark(player, "@!qixi_male", 1)
    elseif event == fk.EventLoseSkill then
      room:setPlayerMark(player, "qixin_restore", 0)
    else
      room:setPlayerMark(player, "qixinUsed-phase", 0)
    end
  end,
}
Fk:loadTranslationTable{
  ["qixin"] = "齐心",
  [":qixin"] = "转换技，出牌阶段，你可以：阳，将性别变为女性，然后将体力值调整为“齐心”记录的数值并记录调整前的体力；" ..
  "阴，将性别变为男性，然后将体力调整为“齐心”记录的数值并记录调整前的体力。<br>" ..
  "隐藏效果：当你获得此技能时，记录你的体力上限并将你的性别改为男性；当濒死求桃结束后，若你仍处于濒死状态且“齐心”记录的数值大于0，" ..
  "则你将体力调整至记录的数值且清除此记录，将你的性别改为异性，“齐心”失效。",
  ["#qixin_trigger"] = "齐心",
}
