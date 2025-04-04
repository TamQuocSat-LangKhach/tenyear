local qiexie = fk.CreateSkill {
  name = "qiexie",
  tags = { Skill.Compulsory },
}

Fk:loadTranslationTable{
  ['qiexie'] = '挈挟',
  ['#qiexie-choose'] = '请选择武将牌作为你的装备牌（右键或长按查看技能）',
  ['@qiexie_right'] = '右臂',
  ['@qiexie_left'] = '左膀',
  [':qiexie'] = '锁定技，准备阶段开始时，若你有空置的武器栏，则你随机观看武将牌堆中五张武将牌（须带有描述中含有“【杀】”且不具有除锁定技以外标签的技能），将其中至少一张当武器牌置入装备区（称为【左膀】和【右臂】，无花色点数，攻击范围为对应武将牌的体力上限，效果为其符合上述条件的技能，离开你的装备区时销毁）。',
  ['$qiexie1'] = '今挟双戟搏战，定护主公太平。',
  ['$qiexie2'] = '吾乃典韦是也，谁敢向前？谁敢向前！',
}

qiexie:addEffect(fk.EventPhaseStart, {
  
  can_trigger = function(self, event, target, player, data)
    return
      target == player and
      player:hasSkill(qiexie.name) and
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

      local result = player.room:askToCustomDialog(
        player,
        {
          skill_name = qiexie.name,
          qml_path = "packages/utility/qml/ChooseGeneralsAndChoiceBox.qml",
          extra_data = {
            availableGenerals,
            {"OK"},
            "#qiexie-choose",
            {},
            1,
            weaponEmpty,
          }
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
            room:moveCardIntoEquip(player, rightArm, qiexie.name, false)
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
            room:moveCardIntoEquip(player, leftArm, qiexie.name, false)
          end
        end
      end
    end
  end,
})

local qiexieFilter = fk.CreateSkill { name = "#qiexie_filter" }
qiexieFilter:addEffect("filter", {
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
})

return qiexie
