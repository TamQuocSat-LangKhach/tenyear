local lisao = fk.CreateSkill {
  name = "lisao",
}

Fk:loadTranslationTable{
  ["lisao"] = "离骚",
  [":lisao"] = "出牌阶段限一次，你可以令至多两名角色同时回答《离骚》选择题（有角色答对则立即停止作答，答错则剩余角色可继续作答），"..
  "答对的角色展示所有手牌，答错或未作答的角色本回合不能响应你使用的牌且受到的伤害翻倍。",

  ["#lisao"] = "离骚：令至多两名角色回答《离骚》，答错或未回答的角色不能响应你的牌且受到伤害翻倍",
  ["@@lisao_debuff-turn"] = "离骚",
  ["lisao_countdown"] = "剩余时间：",

  ["$lisao1"] = "朝饮木兰之坠露，夕餐秋菊之落英。",
  ["$lisao2"] = "惟草木之零落兮，恐美人之迟暮。",
}

Fk:addMiniGame{
  name = "lisao",
  qml_path = "packages/tenyear/qml/LiSaoBox",
  update_func = function(player, data)
    local room = player.room
    local dat = table.concat(data, ",")
    for _, p in ipairs(room:getOtherPlayers(player, false)) do
      p:doNotify("UpdateMiniGame", dat)
    end
  end,
}

lisao:addEffect("active", {
  anim_type = "offensive",
  prompt = "#lisao",
  card_num = 0,
  min_target_num = 1,
  max_target_num = 2,
  can_use = function(self, player)
    return player:usedSkillTimes(lisao.name, Player.HistoryPhase) == 0
  end,
  card_filter = Util.FalseFunc,
  target_filter = function(self, player, to_select, selected)
    return #selected < 2
  end,
  on_use = function(self, room, effect)
    local player = effect.from

    local index = math.random(1, 69)
    local targets = effect.tos

    local gameData = {
      type = "lisao",
      data = {
        {
          question = "lisao_question_" .. index,
          optionA = "lisao_option_A_" .. index,
          optionB = "lisao_option_B_" .. index,
          answer = index > 35 and 2 or 1,
        },
        self.name
      },
    }

    local req = Request:new(targets, "MiniGame")
    req.focus_text = lisao.name
    for _, p in ipairs(targets) do
      p.mini_game_data = gameData
      req:setData(p, p.mini_game_data)
    end
    req:ask()
    local winner = req.winners[1]
    for _, p in ipairs(targets) do
      p.mini_game_data = nil
    end

    if winner then
      table.removeOne(targets, winner)
      if not winner:isKongcheng() then
        winner:showCards(winner:getCardIds("h"))
      end
    end

    for _, p in ipairs(targets) do
      room:addTableMark(p, "@@lisao_debuff-turn", player.id)
    end
  end,
})

lisao:addEffect(fk.DamageInflicted, {
  anim_type = "offensive",
  is_delay_effect = true,
  can_trigger = function(self, event, target, player, data)
    return table.contains(target:getTableMark("@@lisao_debuff-turn"), player.id)
  end,
  on_use = function(self, event, target, player, data)
    local n = #table.filter(target:getTableMark("@@lisao_debuff-turn"), function (id)
      return id == player.id
    end)
    data:changeDamage((2 ^ n - 1) * data.damage)
  end,
})

lisao:addEffect(fk.CardUsing, {
  can_refresh = function(self, event, target, player, data)
    return target == player and
      table.find(player.room.alive_players, function(p)
        return table.contains(p:getTableMark("@@lisao_debuff-turn"), player.id)
      end)
  end,
  on_refresh = function(self, event, target, player, data)
    data.disresponsiveList = data.disresponsiveList or {}
    for _, p in ipairs(player.room.alive_players) do
      if table.contains(p:getTableMark("@@lisao_debuff-turn"), player.id) then
        table.insertIfNeed(data.disresponsiveList, p)
      end
    end
  end,
})

Fk:loadTranslationTable{
  ["lisao_question_1"] = "________，哀民生之多艰。",
  ["lisao_option_A_1"] = "选项一：长太息以掩涕兮",
  ["lisao_option_B_1"] = "选项二：既替余以蕙纕兮",

  ["lisao_question_2"] = "________，固前圣之所厚。",
  ["lisao_option_A_2"] = "选项一：伏清白以死直兮",
  ["lisao_option_B_2"] = "选项二：悔相道之不察兮",

  ["lisao_question_3"] = "________，虽九死其犹未悔。",
  ["lisao_option_A_3"] = "选项一：亦余心之所善兮",
  ["lisao_option_B_3"] = "选项二：屈心而抑志兮",

  ["lisao_question_4"] = "________，谣诼谓余以善淫。",
  ["lisao_option_A_4"] = "选项一：众女嫉余之蛾眉兮",
  ["lisao_option_B_4"] = "选项二：惟夫党人之偷乐兮",

  ["lisao_question_5"] = "________，芳菲菲其弥章。",
  ["lisao_option_A_5"] = "选项一：佩缤纷其繁饰兮",
  ["lisao_option_B_5"] = "选项二：制芰荷以为衣兮",

  ["lisao_question_6"] = "________，吾将上下而求索。",
  ["lisao_option_A_6"] = "选项一：路漫漫其修远兮",
  ["lisao_option_B_6"] = "选项二：举贤才而授能兮",

  ["lisao_question_7"] = "________，余不忍为此态也。",
  ["lisao_option_A_7"] = "选项一：宁溘死以流亡兮",
  ["lisao_option_B_7"] = "选项二：长太息以掩涕兮",

  ["lisao_question_8"] = "________，及行迷之未远。",
  ["lisao_option_A_8"] = "选项一：回朕车以复路兮",
  ["lisao_option_B_8"] = "选项二：悔相道之不察兮",

  ["lisao_question_9"] = "________，相观民之计极。",
  ["lisao_option_A_9"] = "选项一：瞻前而顾后兮",
  ["lisao_option_B_9"] = "选项二：众不可户说兮",

  ["lisao_question_10"] = "长太息以掩涕兮，________。",
  ["lisao_option_A_10"] = "选项一：哀民生之多艰",
  ["lisao_option_B_10"] = "选项二：及行迷之未远",

  ["lisao_question_11"] = "余虽好修姱以鞿羁兮，________。",
  ["lisao_option_A_11"] = "选项一：謇朝谇而夕替",
  ["lisao_option_B_11"] = "选项二：集芙蓉以为裳",

  ["lisao_question_12"] = "既替余以蕙纕兮，________。",
  ["lisao_option_A_12"] = "选项一：又申之以揽茝",
  ["lisao_option_B_12"] = "选项二：延伫乎吾将反",

  ["lisao_question_13"] = "亦余心之所善兮，________。",
  ["lisao_option_A_13"] = "选项一：虽九死其犹未悔",
  ["lisao_option_B_13"] = "选项二：余独好修以为常",

  ["lisao_question_14"] = "怨灵修之浩荡兮，________。",
  ["lisao_option_A_14"] = "选项一：终不察夫民心",
  ["lisao_option_B_14"] = "选项二：自前世而固然",

  ["lisao_question_15"] = "众女嫉余之蛾眉兮，________。",
  ["lisao_option_A_15"] = "选项一：谣诼谓余以善淫",
  ["lisao_option_B_15"] = "选项二：竞周容以为度",

  ["lisao_question_16"] = "固时俗之工巧兮，________。",
  ["lisao_option_A_16"] = "选项一：偭规矩而改错",
  ["lisao_option_B_16"] = "选项二：又申之以揽茝",

  ["lisao_question_17"] = "背绳墨以追曲兮，________。",
  ["lisao_option_A_17"] = "选项一：竞周容以为度",
  ["lisao_option_B_17"] = "选项二：将往观乎四荒",

  ["lisao_question_18"] = "忳郁邑余侘傺兮，________。",
  ["lisao_option_A_18"] = "选项一：吾独穷困乎此时也",
  ["lisao_option_B_18"] = "选项二：谣诼谓余以善淫",

  ["lisao_question_19"] = "宁溘死以流亡兮，________。",
  ["lisao_option_A_19"] = "选项一：余不忍为此态也",
  ["lisao_option_B_19"] = "选项二：謇朝谇而夕替",

  ["lisao_question_20"] = "鸷鸟之不群兮，________。",
  ["lisao_option_A_20"] = "选项一：自前世而固然",
  ["lisao_option_B_20"] = "选项二：余不忍为此态也",

  ["lisao_question_21"] = "何方圜之能周兮，________。",
  ["lisao_option_A_21"] = "选项一：夫孰异道而相安？",
  ["lisao_option_B_21"] = "选项二：固前圣之所厚",

  ["lisao_question_22"] = "屈心而抑志兮，________。",
  ["lisao_option_A_22"] = "选项一：忍尤而攘诟",
  ["lisao_option_B_22"] = "选项二：吾独穷困乎此时也",

  ["lisao_question_23"] = "伏清白以死直兮，________。",
  ["lisao_option_A_23"] = "选项一：固前圣之所厚",
  ["lisao_option_B_23"] = "选项二：夫孰异道而相安？",

  ["lisao_question_24"] = "悔相道之不察兮，________。",
  ["lisao_option_A_24"] = "选项一：延伫乎吾将反",
  ["lisao_option_B_24"] = "选项二：忍尤而攘诟",

  ["lisao_question_25"] = "回朕车以复路兮，________。",
  ["lisao_option_A_25"] = "选项一：及行迷之未远",
  ["lisao_option_B_25"] = "选项二：自前世而固然",

  ["lisao_question_26"] = "步余马于兰皋兮，________。",
  ["lisao_option_A_26"] = "选项一：驰椒丘且焉止息",
  ["lisao_option_B_26"] = "选项二：苟余情其信芳",

  ["lisao_question_27"] = "进不入以离尤兮，________。",
  ["lisao_option_A_27"] = "选项一：退将复修吾初服",
  ["lisao_option_B_27"] = "选项二：唯昭质其犹未亏",

  ["lisao_question_28"] = "制芰荷以为衣兮，________。",
  ["lisao_option_A_28"] = "选项一：集芙蓉以为裳",
  ["lisao_option_B_28"] = "选项二：驰椒丘且焉止息",

  ["lisao_question_29"] = "不吾知其亦已兮，________。",
  ["lisao_option_A_29"] = "选项一：苟余情其信芳",
  ["lisao_option_B_29"] = "选项二：退将复修吾初服",

  ["lisao_question_30"] = "高余冠之岌岌兮，________。",
  ["lisao_option_A_30"] = "选项一：长余佩之陆离",
  ["lisao_option_B_30"] = "选项二：芳菲菲其弥章",

  ["lisao_question_31"] = "芳与泽其杂糅兮，________。",
  ["lisao_option_A_31"] = "选项一：唯昭质其犹未亏",
  ["lisao_option_B_31"] = "选项二：哀民生之多艰",

  ["lisao_question_32"] = "忽反顾以游目兮，________。",
  ["lisao_option_A_32"] = "选项一：将往观乎四荒",
  ["lisao_option_B_32"] = "选项二：偭规矩而改错",

  ["lisao_question_33"] = "佩缤纷其繁饰兮，________。",
  ["lisao_option_A_33"] = "选项一：芳菲菲其弥章",
  ["lisao_option_B_33"] = "选项二：虽九死其犹未悔",

  ["lisao_question_34"] = "民生各有所乐兮，________。",
  ["lisao_option_A_34"] = "选项一：余独好修以为常",
  ["lisao_option_B_34"] = "选项二：岂余心之可惩",

  ["lisao_question_35"] = "虽体解吾犹未变兮，________。",
  ["lisao_option_A_35"] = "选项一：岂余心之可惩",
  ["lisao_option_B_35"] = "选项二：长余佩之陆离",

  ["lisao_question_36"] = "长太息以掩涕兮，________。",
  ["lisao_option_A_36"] = "选项一：及行迷之未远",
  ["lisao_option_B_36"] = "选项二：哀民生之多艰",

  ["lisao_question_37"] = "余虽好修姱以鞿羁兮，________。",
  ["lisao_option_A_37"] = "选项一：集芙蓉以为裳",
  ["lisao_option_B_37"] = "选项二：謇朝谇而夕替",

  ["lisao_question_38"] = "既替余以蕙纕兮，________。",
  ["lisao_option_A_38"] = "选项一：延伫乎吾将反",
  ["lisao_option_B_38"] = "选项二：又申之以揽茝",

  ["lisao_question_39"] = "亦余心之所善兮，________。",
  ["lisao_option_A_39"] = "选项一：余独好修以为常",
  ["lisao_option_B_39"] = "选项二：虽九死其犹未悔",

  ["lisao_question_40"] = "________，相观民之计极。",
  ["lisao_option_A_40"] = "选项一：众不可户说兮",
  ["lisao_option_B_40"] = "选项二：瞻前而顾后兮",

  ["lisao_question_41"] = "怨灵修之浩荡兮，________。",
  ["lisao_option_A_41"] = "选项一：自前世而固然",
  ["lisao_option_B_41"] = "选项二：终不察夫民心",

  ["lisao_question_42"] = "众女嫉余之蛾眉兮，________。",
  ["lisao_option_A_42"] = "选项一：竞周容以为度",
  ["lisao_option_B_42"] = "选项二：谣诼谓余以善淫",

  ["lisao_question_43"] = "固时俗之工巧兮，________。",
  ["lisao_option_A_43"] = "选项一：又申之以揽茝",
  ["lisao_option_B_43"] = "选项二：偭规矩而改错",

  ["lisao_question_44"] = "背绳墨以追曲兮，________。",
  ["lisao_option_A_44"] = "选项一：将往观乎四荒",
  ["lisao_option_B_44"] = "选项二：竞周容以为度",

  ["lisao_question_45"] = "忳郁邑余侘傺兮，________。",
  ["lisao_option_A_45"] = "选项一：谣诼谓余以善淫",
  ["lisao_option_B_45"] = "选项二：吾独穷困乎此时也",

  ["lisao_question_46"] = "宁溘死以流亡兮，________。",
  ["lisao_option_A_46"] = "选项一：謇朝谇而夕替",
  ["lisao_option_B_46"] = "选项二：余不忍为此态也",

  ["lisao_question_47"] = "鸷鸟之不群兮，________。",
  ["lisao_option_A_47"] = "选项一：余不忍为此态也",
  ["lisao_option_B_47"] = "选项二：自前世而固然",

  ["lisao_question_48"] = "何方圜之能周兮，________。",
  ["lisao_option_A_48"] = "选项一：固前圣之所厚",
  ["lisao_option_B_48"] = "选项二：夫孰异道而相安？",

  ["lisao_question_49"] = "屈心而抑志兮，________。",
  ["lisao_option_A_49"] = "选项一：吾独穷困乎此时也",
  ["lisao_option_B_49"] = "选项二：忍尤而攘诟",

  ["lisao_question_50"] = "伏清白以死直兮，________。",
  ["lisao_option_A_50"] = "选项一：夫孰异道而相安？",
  ["lisao_option_B_50"] = "选项二：固前圣之所厚",

  ["lisao_question_51"] = "悔相道之不察兮，________。",
  ["lisao_option_A_51"] = "选项一：忍尤而攘诟",
  ["lisao_option_B_51"] = "选项二：延伫乎吾将反",

  ["lisao_question_52"] = "回朕车以复路兮，________。",
  ["lisao_option_A_52"] = "选项一：自前世而固然",
  ["lisao_option_B_52"] = "选项二：及行迷之未远",

  ["lisao_question_53"] = "步余马于兰皋兮，________。",
  ["lisao_option_A_53"] = "选项一：苟余情其信芳",
  ["lisao_option_B_53"] = "选项二：驰椒丘且焉止息",

  ["lisao_question_54"] = "进不入以离尤兮，________。",
  ["lisao_option_A_54"] = "选项一：唯昭质其犹未亏",
  ["lisao_option_B_54"] = "选项二：退将复修吾初服",

  ["lisao_question_55"] = "制芰荷以为衣兮，________。",
  ["lisao_option_A_55"] = "选项一：驰椒丘且焉止息",
  ["lisao_option_B_55"] = "选项二：集芙蓉以为裳",

  ["lisao_question_56"] = "不吾知其亦已兮，________。",
  ["lisao_option_A_56"] = "选项一：退将复修吾初服",
  ["lisao_option_B_56"] = "选项二：苟余情其信芳",

  ["lisao_question_57"] = "高余冠之岌岌兮，________。",
  ["lisao_option_A_57"] = "选项一：芳菲菲其弥章",
  ["lisao_option_B_57"] = "选项二：长余佩之陆离",

  ["lisao_question_58"] = "芳与泽其杂糅兮，________。",
  ["lisao_option_A_58"] = "选项一：哀民生之多艰",
  ["lisao_option_B_58"] = "选项二：唯昭质其犹未亏",

  ["lisao_question_59"] = "忽反顾以游目兮，________。",
  ["lisao_option_A_59"] = "选项一：偭规矩而改错",
  ["lisao_option_B_59"] = "选项二：将往观乎四荒",

  ["lisao_question_60"] = "佩缤纷其繁饰兮，________。",
  ["lisao_option_A_60"] = "选项一：虽九死其犹未悔",
  ["lisao_option_B_60"] = "选项二：芳菲菲其弥章",

  ["lisao_question_61"] = "民生各有所乐兮，________。",
  ["lisao_option_A_61"] = "选项一：岂余心之可惩",
  ["lisao_option_B_61"] = "选项二：余独好修以为常",

  ["lisao_question_62"] = "虽体解吾犹未变兮，________。",
  ["lisao_option_A_62"] = "选项一：长余佩之陆离",
  ["lisao_option_B_62"] = "选项二：岂余心之可惩",

  ["lisao_question_63"] = "________，哀民生之多艰。",
  ["lisao_option_A_63"] = "选项一：既替余以蕙纕兮",
  ["lisao_option_B_63"] = "选项二：长太息以掩涕兮",

  ["lisao_question_64"] = "________，固前圣之所厚。",
  ["lisao_option_A_64"] = "选项一：悔相道之不察兮",
  ["lisao_option_B_64"] = "选项二：伏清白以死直兮",

  ["lisao_question_65"] = "________，虽九死其犹未悔。",
  ["lisao_option_A_65"] = "选项一：屈心而抑志兮",
  ["lisao_option_B_65"] = "选项二：亦余心之所善兮",

  ["lisao_question_66"] = "________，谣诼谓余以善淫。",
  ["lisao_option_A_66"] = "选项一：惟夫党人之偷乐兮",
  ["lisao_option_B_66"] = "选项二：众女嫉余之蛾眉兮",

  ["lisao_question_67"] = "________，芳菲菲其弥章。",
  ["lisao_option_A_67"] = "选项一：制芰荷以为衣兮",
  ["lisao_option_B_67"] = "选项二：佩缤纷其繁饰兮",

  ["lisao_question_68"] = "________，余不忍为此态也。",
  ["lisao_option_A_68"] = "选项一：长太息以掩涕兮",
  ["lisao_option_B_68"] = "选项二：宁溘死以流亡兮",

  ["lisao_question_69"] = "________，及行迷之未远。",
  ["lisao_option_A_69"] = "选项一：悔相道之不察兮",
  ["lisao_option_B_69"] = "选项二：回朕车以复路兮",
}
return lisao
