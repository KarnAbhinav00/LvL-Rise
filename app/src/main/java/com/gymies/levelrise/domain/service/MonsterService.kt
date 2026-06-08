package com.gymies.levelrise.domain.service

import com.gymies.levelrise.domain.model.Monster
import com.gymies.levelrise.domain.model.Rarity

object MonsterService {
    val monsters = listOf(
        // FIRE type (10)
        Monster("f1", "Flame Sprite", Rarity.COMMON, 12, 6, 14, "Fire", ""),
        Monster("f2", "Ember Hound", Rarity.COMMON, 15, 10, 12, "Fire", ""),
        Monster("f3", "Blaze Cat", Rarity.COMMON, 14, 8, 16, "Fire", ""),
        Monster("f4", "Cinder Fox", Rarity.UNCOMMON, 18, 12, 17, "Fire", ""),
        Monster("f5", "Fire Hawk", Rarity.UNCOMMON, 20, 10, 22, "Fire", ""),
        Monster("f6", "Magma Bear", Rarity.UNCOMMON, 22, 20, 8, "Fire", ""),
        Monster("f7", "Inferno Wolf", Rarity.RARE, 28, 16, 24, "Fire", ""),
        Monster("f8", "Flame Phoenix", Rarity.RARE, 35, 15, 25, "Fire", ""),
        Monster("f9", "Volcano Titan", Rarity.EPIC, 45, 35, 15, "Fire", ""),
        Monster("f10", "Sun God", Rarity.LEGENDARY, 60, 40, 35, "Fire", ""),

        // WATER type (10)
        Monster("w1", "Aqua Drop", Rarity.COMMON, 10, 8, 12, "Water", ""),
        Monster("w2", "Ripple Fish", Rarity.COMMON, 11, 10, 14, "Water", ""),
        Monster("w3", "Coral Crab", Rarity.COMMON, 13, 18, 8, "Water", ""),
        Monster("w4", "Frost Seal", Rarity.UNCOMMON, 16, 14, 15, "Water", ""),
        Monster("w5", "Wave Rider", Rarity.UNCOMMON, 19, 12, 20, "Water", ""),
        Monster("w6", "Ice Drake", Rarity.UNCOMMON, 21, 22, 14, "Water", ""),
        Monster("w7", "Tidal Serpent", Rarity.RARE, 27, 18, 22, "Water", ""),
        Monster("w8", "Abyss Shark", Rarity.RARE, 32, 16, 28, "Water", ""),
        Monster("w9", "Glacier Giant", Rarity.EPIC, 40, 42, 10, "Water", ""),
        Monster("w10", "Ocean King", Rarity.LEGENDARY, 55, 50, 25, "Water", ""),

        // WIND type (10)
        Monster("wi1", "Breeze Fairy", Rarity.COMMON, 10, 5, 18, "Wind", ""),
        Monster("wi2", "Gust Imp", Rarity.COMMON, 13, 7, 17, "Wind", ""),
        Monster("wi3", "Zephyr Bird", Rarity.COMMON, 14, 8, 19, "Wind", ""),
        Monster("wi4", "Storm Crow", Rarity.UNCOMMON, 17, 10, 22, "Wind", ""),
        Monster("wi5", "Wind Stalker", Rarity.UNCOMMON, 20, 12, 24, "Wind", ""),
        Monster("wi6", "Cyclone Beast", Rarity.UNCOMMON, 23, 14, 26, "Wind", ""),
        Monster("wi7", "Hurricane Dragon", Rarity.RARE, 30, 15, 32, "Wind", ""),
        Monster("wi8", "Sky Sentinel", Rarity.RARE, 28, 22, 30, "Wind", ""),
        Monster("wi9", "Tempest God", Rarity.EPIC, 42, 25, 40, "Wind", ""),
        Monster("wi10", "Aether Wing", Rarity.LEGENDARY, 58, 30, 55, "Wind", ""),

        // ELECTRIC type (10)
        Monster("e1", "Spark Mouse", Rarity.COMMON, 13, 6, 16, "Electric", ""),
        Monster("e2", "Volt Rabbit", Rarity.COMMON, 14, 9, 15, "Electric", ""),
        Monster("e3", "Zap Eel", Rarity.COMMON, 16, 10, 13, "Electric", ""),
        Monster("e4", "Thunder Fox", Rarity.UNCOMMON, 20, 12, 20, "Electric", ""),
        Monster("e5", "Shock Wolf", Rarity.UNCOMMON, 22, 14, 22, "Electric", ""),
        Monster("e6", "Bolt Stag", Rarity.UNCOMMON, 24, 18, 18, "Electric", ""),
        Monster("e7", "Plasma Lynx", Rarity.RARE, 30, 16, 28, "Electric", ""),
        Monster("e8", "Thunder Dragon", Rarity.RARE, 35, 20, 30, "Electric", ""),
        Monster("e9", "Lightning Lord", Rarity.EPIC, 48, 28, 38, "Electric", ""),
        Monster("e10", "Storm Emperor", Rarity.LEGENDARY, 65, 35, 45, "Electric", ""),

        // NATURE type (10)
        Monster("n1", "Leaf Pup", Rarity.COMMON, 11, 10, 12, "Nature", ""),
        Monster("n2", "Moss Turtle", Rarity.COMMON, 9, 20, 6, "Nature", ""),
        Monster("n3", "Vine Snake", Rarity.COMMON, 13, 12, 14, "Nature", ""),
        Monster("n4", "Flower Fawn", Rarity.UNCOMMON, 16, 14, 16, "Nature", ""),
        Monster("n5", "Bark Golem", Rarity.UNCOMMON, 18, 26, 8, "Nature", ""),
        Monster("n6", "Thorn Beast", Rarity.UNCOMMON, 22, 18, 14, "Nature", ""),
        Monster("n7", "Forest Wyvern", Rarity.RARE, 28, 20, 24, "Nature", ""),
        Monster("n8", "Ancient Treant", Rarity.RARE, 25, 40, 10, "Nature", ""),
        Monster("n9", "Wilderness King", Rarity.EPIC, 40, 35, 20, "Nature", ""),
        Monster("n10", "World Tree Spirit", Rarity.LEGENDARY, 50, 60, 30, "Nature", "")
    )

    fun getRandomMonster(rarityWeights: Map<Rarity, Int> = defaultWeights): Monster {
        val pool = monsters.flatMap { monster ->
            List(rarityWeights[monster.rarity] ?: 1) { monster }
        }
        return pool.random()
    }

    private val defaultWeights = mapOf(
        Rarity.COMMON to 50,
        Rarity.UNCOMMON to 30,
        Rarity.RARE to 15,
        Rarity.EPIC to 4,
        Rarity.LEGENDARY to 1
    )
}
