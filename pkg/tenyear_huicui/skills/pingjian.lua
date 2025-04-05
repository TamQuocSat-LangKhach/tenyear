local pingjian = fk.CreateSkill {
  name = "ty__pingjian",
}

local pinjian_skills = {
  ["play"] = {
    "qiangwu", "ol_ex__qiangxi", "ol_ex__luanji", "ty_ex__sanyao", "ol__xuehen", "ex__yijue", "daoshu", "m_ex__xianzhen",
    "tianyi", "mansi", "ty__lianji", "ty_ex__wurong", "xuezhao", "hs__kurou", "m_ex__mieji",
    "ex__zhiheng", "ex__guose", "guolun", "duliang", "os__gongxin", "lueming", "jijie", "busuan", "minsi", "ty__lianzhu",
    "ex__fanjian", "tanbei", "ty__qingcheng", "jinhui", "weimeng", "ty__songshu", "poxi", "m_ex__ganlu", "ty__kuangfu", "qice",
    "ty_ex__gongqi", "ty_ex__huaiyi", "shanxi", "cuijian", "ol_ex__tiaoxin", "qingnang", "quji", "ty_ex__anguo", "ex__jieyin",
    "m_ex__anxu", "ty_ex__mingce", "ziyuan", "mou__lijian", "mingjian", "ex__rende", "mizhao", "yanjiao", "ol_ex__dimeng",
    "quhu", "tunan", "nuchen", "feijun", "yingshui", "qiongying", "zigu", "weiwu", "chiying",

    "yangjie", "m_ex__junxing", "m_ex__yanzhu", "ol_ex__changbiao", "yanxi", "xuanbei", "yushen", "guanxu",
    "ty__jianji", "wencan", "xiangmian", "zhuren", "changqu", "jiuxianc", "caizhuang", "ty__beini", "jichun", "tongwei",
    "liangyan", "kuizhen", "huiji",
  },
  ["damaged"] = {
    "guixin", "ty__benyu", "ex__fankui", "ex__ganglie", "ex__yiji", "ex__jianxiong", "os_ex__enyuan", "chouce", "ol_ex__jieming",
    "fangzhu", "ty_ex__chengxiang", "huituo", "ty__wangxi", "yuce", "zhichi", "ty_ex__zhiyu", "wanggui", "qianlong", "dingcuo",
    "peiqi",

    "ty__jilei", "xianchou", "liejie", "os__fupan", "yuqi", "silun", "yashi", "qingxian", "xiace", "fumou",
  },
  ["phase_start"] = {
    "ty_ex__zhiyan", "ex__biyue", "zuilun", "mozhi", "fujian", "kunfen", "ol_ex__jushou", "os_ex__bingyi", "miji", "zhengu",
    "juece", "sp__youdi", "kuanshi", "ty__jieying", "suizheng", "m_ex__jieyue",

    "shenfu", "meihun", "pijing", "zhuihuan", "os__juchen", "os__xingbu", "ty_ex__jingce", "nuanhui", "sangu",
    "js__pianchong", "linghui", "huayi", "jue",
  },
}

pingjian.pinjian_skills = pinjian_skills

Fk:loadTranslationTable{
  ["ty__pingjian"] = "评荐",
  [":ty__pingjian"] = "出牌阶段，或结束阶段，或当你受到伤害后，你可以从对应时机的技能池中随机抽取三个技能，选择并发动其中一个"..
  "（每个技能限发动一次）。",

  ["#ty__pingjian"] = "评荐：从三个出牌阶段的技能中选择一个学习",
  ["#ty__pingjian-choice"] = "评荐：选择要学习的技能",

  ["$ty__pingjian1"] = "识人读心，评荐推达。",
  ["$ty__pingjian2"] = "月旦雅评，试论天下。",
}

local function getPingjianSkills(player, event)
  return table.filter(pinjian_skills[event], function (skill_name)
    return Fk.skills[skill_name] and not player:hasSkill(skill_name, true) and
      not table.contains(player:getTableMark("ty__pingjian_used_skills"), skill_name)
  end)
end

pingjian:addEffect("active", {
  name = "ty__pingjian",
  prompt = "#ty__pingjian",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedEffectTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local skills = getPingjianSkills(player, "play")
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askToChoice(player, {
      choices = choices,
      skill_name = pingjian.name,
      prompt = "#ty__pingjian-choice",
      detailed = true,
    })
    room:addTableMark(player, "ty__pingjian_used_skills", skill_name)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = skill_name,
      toast = true,
    }

    local phase_event = room.logic:getCurrentEvent():findParent(GameEvent.Phase)
    if player:hasSkill(skill_name) or not phase_event then
      return false
    end

    room:handleAddLoseSkills(player, skill_name)
    room:addTableMark(player, "pingjian_play_skill-phase", skill_name)
    phase_event:addCleaner(function()
      room:handleAddLoseSkills(player, "-" .. skill_name)
    end)
  end,
})

pingjian:addEffect(fk.SkillEffect, {
  is_delay_effect = true,
  priority = 2,
  can_trigger = function(self, event, target, player, data)
    return target == player and table.contains(player:getTableMark("pingjian_play_skill-phase"), data.skill.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skillName = data.skill.name
    room:removeTableMark(player, "pingjian_play_skill-phase", skillName)
    room:handleAddLoseSkills(player, "-" .. skillName)
  end,
})

pingjian:addEffect(fk.Damaged, {
  anim_type = "masochism",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pingjian.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = getPingjianSkills(player, "damaged")
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askToChoice(player, {
      choices = choices,
      skill_name = pingjian.name,
      prompt = "#ty__pingjian-choice",
      detailed = true,
    })
    room:addTableMark(player, "ty__pingjian_used_skills", skill_name)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = skill_name,
      toast = true,
    }

    room:handleAddLoseSkills(player, skill_name)
    local skel = Fk.skill_skels[skill_name]
    for _, skill in ipairs(skel.effects) do
      if skill:isInstanceOf(TriggerSkill) and skill:triggerable(event, target, player, data) then
        skill:trigger(event, target, player, data)
      end
    end
    room:handleAddLoseSkills(player, "-"..skill_name)
  end,
})

pingjian:addEffect(fk.EventPhaseStart, {
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(pingjian.name) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local skills = getPingjianSkills(player, "phase_start")
    if #skills == 0 then return false end
    local choices = table.random(skills, 3)
    local skill_name = room:askToChoice(player, {
      choices = choices,
      skill_name = pingjian.name,
      prompt = "#ty__pingjian-choice",
      detailed = true,
    })
    room:addTableMark(player, "ty__pingjian_used_skills", skill_name)
    room:sendLog{
      type = "#Choice",
      from = player.id,
      arg = skill_name,
      toast = true,
    }

    room:handleAddLoseSkills(player, skill_name)
    local skel = Fk.skill_skels[skill_name]
    for _, skill in ipairs(skel.effects) do
      if skill:isInstanceOf(TriggerSkill) and skill:triggerable(event, target, player, data) then
        skill:trigger(event, target, player, data)
      end
    end
    room:handleAddLoseSkills(player, "-"..skill_name)
  end,
})

return pingjian
