local shixian = fk.CreateSkill {
  name = "shixian",
}

Fk:loadTranslationTable{
  ["shixian"] = "诗仙",
  [":shixian"] = "你使用一张牌时，若此牌与你本回合使用的上一张牌押韵，你可以摸一张牌并令此牌额外执行一次效果。",

  ["#shixian-invoke"] = "诗仙：%arg押韵！你可以摸一张牌并令此牌额外执行一次效果！",

  ["$shixian1"] = "武侯立岷蜀，壮志吞咸京。",
  ["$shixian2"] = "鱼水三顾合，风云四海生。",
}

local shixian_pairs = {
  --a ia ua：杀，万箭齐发，藤甲，木牛流马，兵临城下，桐油百韧甲，烂银甲，商鞅变法，奇门八卦
  a = {
    "slash",
    "archery_attack",
    "vine",
    "wooden_ox",
    "enemy_at_the_gates",
    "ex_vine",
    "glittery_armor",
    "shangyang_reform",
    "py_diagram",
  },

  --o e uo：衠钢槊，三略，霹雳车，大攻车，连弩战车，望梅止渴
  e = {
    "steel_lance",
    "py_threebook",
    "catapult",
    "siege_engine",
    "offensive_siege_engine",
    "defensive_siege_engine",
    "wd_crossbow_tank",
    "wd_stop_thirst"
  },

  --ie ve：趁火打劫
  ie = {
    "looting"
  },

  --ai uai：黑光铠，瞒天过海，玲珑狮蛮带
  ai = {
    "dark_armor",
    "underhanding",
    "py_belt",
  },

  --ei ui：调剂盐梅，以半击倍，浮雷，照月狮子盔，养精蓄锐
  ei = {
    "redistribute",
    "defeating_the_double",
    "floating_thunder",
    "ex_silver_lion",
    "wd_save_energy",
  },

  --ao iao：桃，青龙偃月刀，丈八蛇矛，过河拆桥，古锭刀，笑里藏刀，七宝刀，金蝉脱壳，增兵减灶，以逸待劳，三尖两刃刀，鬼龙斩月刀，红棉百花袍，
  --国风玉袍，烈淬刀，七星刀
  ao = {
    "peach",
    "blade",
    "spear",
    "dismantlement",
    "guding_blade",
    "daggar_in_smile",
    "seven_stars_sword",
    "crafty_escape",
    "reinforcement",
    "await_exhausted",
    "triblade",
    "py_blade",
    "py_robe",
    "py_cloak",
    "quenched_blade",
    "wd_seven_stars_sword",
  },

  --ou iu：无中生有，决斗，骅骝，酒，走
  ou = {
    "ex_nihilo",
    "duel",
    "huailiu",
    "analeptic",
    "wd_run",
  },

  --an ian uan van：闪，闪电，青釭剑，雌雄双股剑，寒冰剑，爪黄飞电，大宛，兵粮寸断，朱雀羽扇，铁索连环，乌铁锁链，五行鹤翎扇，逐近弃远，
  --砖，吴六剑，真龙长剑，束发紫金冠，虚妄之冕，思召剑，水波剑，玄剑
  an = {
    "jink",
    "lightning",
    "qinggang_sword",
    "double_swords",
    "ice_sword",
    "zhuahuangfeidian",
    "dayuan",
    "supply_shortage",
    "fan",
    "iron_chain",
    "black_chain",
    "five_elements_fan",
    "chasing_near",
    "n_brick",
    "six_swords",
    "qin_dragon_sword",
    "py_hat",
    "py_coronet",
    "sizhao_sword",
    "water_sword",
    "xuanjian_sword",
  },

  --en in un vn：借刀杀人，南蛮入侵，八卦阵，仁王盾，水淹七军，先天八卦阵，仁王金刚盾，天雷刃，太极拂尘，金
  en = {
    "collateral",
    "savage_assault",
    "eight_diagram",
    "nioh_shield",
    "drowning",
    "horsetail_whisk",
    "ex_eight_diagram",
    "ex_nioh_shield",
    "thunder_blade",
    "wd_drowning",
    "wd_gold",
  },

  --ang iang uang：顺手牵羊，李代桃僵，银月枪，红缎枪，粮
  ang = {
    "snatch",
    "substituting",
    "moon_spear",
    "red_spear",
    "wd_rice",
  },

  --eng ing ong ung：五谷丰登，麒麟弓，绝影，紫骍，火攻，护心镜，奇正相生，弃甲曳兵，草木皆兵，远交近攻，赤血青锋，照骨镜，欲擒故纵
  eng = {
    "amazing_grace",
    "kylin_bow",
    "jueying",
    "zixing",
    "fire_attack",
    "breastplate",
    "raid_and_frontal_attack",
    "abandoning_armor",
    "paranoid",
    "befriend_attacking",
    "blood_sword",
    "py_mirror",
    "wd_breastplate",
    "wd_let_off_enemy",
  },

  --i er v：桃园结义，无懈可击，方天画戟，白银狮子，出其不意，洞烛先机，美人计，传国玉玺，违害就利，声东击西，斗转星移，知己知彼，
  --无双方天戟，镔铁双戟，混毒弯匕，日月戟
  i = {
    "god_salvation",
    "nullification",
    "halberd",
    "silver_lion",
    "unexpectation",
    "foresight",
    "honey_trap",
    "qin_seal",
    "avoiding_disadvantages",
    "diversion",
    "time_flying",
    "known_both",
    "py_halberd",
    "py_double_halberd",
    "poisonous_dagger",
    "wd_sun_moon_halberd",
  },

  --u：乐不思蜀，诸葛连弩，贯石斧，赤兔，的卢，天机图，太公阴符，毒，偷梁换柱，推心置腹，文和乱武，连弩，悦刻五，太平要术，
  --四乘粮舆，铁蒺玄舆，飞轮战舆，金梳，琼梳，犀梳，秦弩，元戎精械弩，灵宝仙葫，冲应神符，白鹄，诱敌深入
  u = {
    "indulgence",
    "crossbow",
    "axe",
    "chitu",
    "dilu",
    "wonder_map",
    "taigong_tactics",
    "poison",
    "replace_with_a_fake",
    "sincere_treat",
    "wenhe_chaos",
    "xbow",
    "n_relx_v",
    "peace_spell",
    "grain_cart",
    "caltrop_cart",
    "wheel_cart",
    "golden_comb",
    "jade_comb",
    "rhino_comb",
    "qin_crossbow",
    "ex_crossbow",
    "celestial_calabash",
    "talisman",
    "wd_baihu",
    "wd_lure_in_deep",
  },
}

shixian:addEffect(fk.CardUsing, {
  anim_type = "drawcard",
  can_trigger = function (self, event, target, player, data)
    if target == player and player:hasSkill(shixian.name) then
      local name = ""
      player.room.logic:getEventsByRule(GameEvent.UseCard, 1, function (e)
        if e.id < player.room.logic:getCurrentEvent().id then
          if e.data.from == player then
            name = e.data.card.trueName
            return true
          end
        end
      end, 0, Player.HistoryTurn)
      if name then
        for _, v in pairs(shixian_pairs) do
          if table.contains(v, name) then
            return table.contains(v, data.card.trueName)
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askToSkillInvoke(player, {
      skill_name = shixian.name,
      prompt = "#shixian-invoke:::"..data.card:toLogString()
    })
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1, shixian.name)
    data.additionalEffect = (data.additionalEffect or 0) + 1
  end,
})

return shixian
