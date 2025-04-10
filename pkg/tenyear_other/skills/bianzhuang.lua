local bianzhuang = fk.CreateSkill {
  name = "bianzhuang",
}

Fk:loadTranslationTable{
  ["bianzhuang"] = "变装",
  [":bianzhuang"] = "出牌阶段限一次，你可以从两名武将中选择一个进行变装，然后视为使用一张【杀】（无距离和次数限制），根据变装"..
  "此【杀】获得额外效果。当你使用装备牌后，重置本阶段〖变装〗发动次数。当你发动三次〖变装〗后，本局游戏你进行变装时增加一个选项。",

  ["#bianzhuang"] = "变装：你可以进行“变装”，然后视为使用一张【杀】！",
  ["#bianzhuang-choice"] = "变装：选择你“变装”获得的技能效果",
  ["#bianzhuang-slash"] = "变装：视为使用一张【杀】，附带“%arg”的技能效果！",

  ["$bianzhuang1"] = "须知少日凌云志，曾许人间第一流。",
  ["$bianzhuang2"] = "愿尽绵薄之力，盼国风盛行。",
}

local bianzhuang_choices = {
  --standard
  {"lvbu","wushuang"},
  {"nos__madai","nos__qianxi"},
  {"lingju","jieyuan"},

  --ol
  {"quyi","fuji"},
  {"caoying","lingren"},
  {"ol__lvkuanglvxiang","qigong"},
  {"ol__tianyu","saodi"},
  {"xiahouxuan","huanfu"},
  {"ol__simashi","yimie"},
  {"ol_ex__huangzhong","ol_ex__liegong"},
  {"ol_ex__pangde","ol_ex__jianchu"},
  {"zhaoji","qin__shanwu"},
  {"ol__dingfeng","ol__duanbing"},
  {"ol_ex__jiaxu","ol_ex__wansha"},
  {"ol__fanchou","ol__xingluan"},
  {"yingzheng","qin__yitong"},
  {"ol__dengzhi","xiuhao"},
  {"qinghegongzhu","zengou"},
  {"ol__wenqin","guangao"},
  {"olz__zhonghui","xieshu"},
  {"olmou__yuanshao", "shenliy"},
  {"macheng","chenglie"},
  {"ol__lukai","jiane"},
  {"yadan","qingya"},
  {"ol__niufu","zonglue"},
  {"olmou__sunjian","hulie"},
  {"zhangyan", "langdao"},

  --offline
  {"es__chendao","jianglie"},
  {"ehuan","diwan"},
  {"ofl__zhonghui","zizhong"},
  {"shengongbao","zhuzhou"},
  {"ofl__gongsunzan","qizhen"},
  {"zhaorong","yuantao"},

  --mini
  {"mini__weiyan","mini__kuanggu"},
  {"miniex__machao","mini_qipao"},

  --mobile
  {"mobile__gaolan", "dengli"},
  {"mobile__wenyang","quedi"},
  {"m_ex__xusheng","m_ex__pojun"},
  {"m_ex__sunluban","m_ex__zenhui"},
  {"mobile__wenqin","choumang"},

  --mougong
  {"mou__machao", "mou__tieji"},
  {"mou__zhurong","mou__lieren"},

  --overseas
  {"yuejiu","os__cuijin"},
  {"os__tianyu","os__zhenxi"},
  {"os__fuwan","os__moukui"},
  {"zhangwei","os__huzhong"},
  {"os__zangba","os__hengjiang"},
  {"os__wuban","os__jintao"},
  {"os__haomeng","os__gongge"},
  {"wangyue","os__yulong"},
  {"liyan","os__zhenhu"},
  {"os__wujing","os__fenghan"},
  {"zhangwei","os__huzhong"},
  {"os_ex__caoxiu","os_ex__qingxi"},
  {"os__mayunlu","os__fengpo"},
  {"os_if__jiangwei","os__zhihuan"},
  {"os_if__weiyan","os__piankuang"},

  --tenyear
  {"ty__baosanniang","ty__wuniang"},
  {"wangshuang","zhuilie"},
  {"ty__huangzu","xiaojun"},
  {"wm__zhugeliang","qingshi"},
  {"mangyachang","jiedao"},
  {"caimaozhangyun","jinglan"},
  {"zhaozhong","yangzhong"},
  {"sunlang","benshi"},
  {"yanrou","choutao"},
  {"panghui","yiyong"},
  {"ty__huaxin","wanggui"},
  {"guanhai","suoliang"},
  {"ty_ex__zhangchunhua","ty_ex__jueqing"},
  {"ty_ex__panzhangmazhong","ty_ex__anjian"},
  {"ty_ex__masu","ty_ex__zhiman"},
  {"wenyang","lvli"},
  {"ty__luotong","jinjian"},
  {"tymou__simayi","pingliao"},
  {"wenyuan","kengqiang"},
  {"godhuangzhong","lieqiong"},
  {"ty__tongyuan","chaofeng"},
  {"qiuliju","koulue"},
  {"sunchen","zuowei"},
  {"tymou__simashi","zhenrao"},
  {"caoyi", "yinjun"},
  {"quyuan", "qiusuo"},

  --jsrg
  {"js__sunjian","juelie"},
  {"js__zhujun","fendi"},
  {"js__liubei","zhenqiao"},
  {"js__lvbu","wuchang"},
  {"js__machao","zhuiming"},
  {"jiananfeng","liedu"},

  --yjtw
  {"tw__xiahouba","tw__baobian"},
}

bianzhuang:addEffect("active", {
  anim_type = "offensive",
  prompt = "#bianzhuang",
  card_num = 0,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(bianzhuang.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  on_use = function(self, room, effect)
    local player = effect.from
    local n = player:usedSkillTimes(bianzhuang.name, Player.HistoryGame) > 3 and 3 or 2
    local all_choices = table.filter(bianzhuang_choices, function (c)
      return Fk.generals[c[1]] ~= nil and Fk.skill_skels[c[2]] ~= nil
    end)
    local choices = table.random(all_choices, n)
    local generals = table.map(choices, function(c) return c[1] end)
    local skills = table.map(choices, function(c) return {c[2]} end)

    local result = room:askToCustomDialog(player, {
      skill_name = bianzhuang.name,
      qml_path = "packages/tenyear/qml/ChooseGeneralSkillsBox.qml",
      extra_data = {generals, skills, 1, 1, "#bianzhuang-choice", false}
    })
    local skill_name = skills[1][1]
    if result ~= "" then
      skill_name = json.decode(result)[1]
    end
    local general_name = table.find(generals, function (g, i)
      return skills[i][1] == skill_name
    end)
    local general = Fk.generals[general_name]

    local bianzhuang_info = {player.general, player.gender, player.kingdom}
    player.general = general_name
    room:broadcastProperty(player, "general")
    player.gender = general.gender
    room:broadcastProperty(player, "gender")
    player.kingdom = general.kingdom
    room:broadcastProperty(player, "kingdom")
    local acquired = (not player:hasSkill(skill_name, true))
    if acquired then
      room:handleAddLoseSkills(player, skill_name, nil, false)
    end

    local use = room:askToUseVirtualCard(player, {
      name = "slash",
      skill_name = bianzhuang.name,
      prompt = "#bianzhuang-slash:::"..skill_name,
      cancelable = true,
      extra_data = {
        bypass_distances = true,
        bypass_times = true,
        extraUse = true,
      },
      skip = true,
    })
    player.general = bianzhuang_info[1]
    room:broadcastProperty(player, "general")
    player.gender = bianzhuang_info[2]
    room:broadcastProperty(player, "gender")
    player.kingdom = bianzhuang_info[3]
    room:broadcastProperty(player, "kingdom")
    if use then
      room:useCard(use)
    end
    if acquired then
      room:handleAddLoseSkills(player, "-"..skill_name, nil, false)
    end
  end,
})

bianzhuang:addEffect(fk.CardUseFinished, {
  can_refresh = function(self, event, target, player, data)
    return target == player and data.card.type == Card.TypeEquip and
      player:usedSkillTimes(bianzhuang.name, Player.HistoryPhase) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    player:setSkillUseHistory(bianzhuang.name, 0, Player.HistoryPhase)
  end,
})

return bianzhuang
