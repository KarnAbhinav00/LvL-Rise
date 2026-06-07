package com.gymies.levelrise.domain.service

import com.gymies.levelrise.domain.model.Monster
import com.gymies.levelrise.domain.model.Rarity

object MonsterService {
    
    val monsters = listOf(
        Monster(
            id = "m1",
            name = "Iron Golem",
            rarity = Rarity.COMMON,
            baseAttack = 15,
            baseDefense = 25,
            baseSpeed = 5,
            type = "Strength",
            imageUrl = "https://example.com/m1.png"
        ),
        Monster(
            id = "m2",
            name = "Shadow Stalker",
            rarity = Rarity.UNCOMMON,
            baseAttack = 22,
            baseDefense = 10,
            baseSpeed = 30,
            type = "Agility",
            imageUrl = "https://example.com/m2.png"
        ),
        Monster(
            id = "m3",
            name = "Flame Phoenix",
            rarity = Rarity.RARE,
            baseAttack = 35,
            baseDefense = 15,
            baseSpeed = 25,
            type = "Fire",
            imageUrl = "https://example.com/m3.png"
        ),
        Monster(
            id = "m4",
            name = "Thunder Dragon",
            rarity = Rarity.EPIC,
            baseAttack = 50,
            baseDefense = 40,
            baseSpeed = 45,
            type = "Electric",
            imageUrl = "https://example.com/m4.png"
        ),
        Monster(
            id = "m5",
            name = "Void Ancient",
            rarity = Rarity.LEGENDARY,
            baseAttack = 100,
            baseDefense = 100,
            baseSpeed = 100,
            type = "Void",
            imageUrl = "https://example.com/m5.png"
        )
    )

    fun getRandomMonster(rarityWeights: Map<Rarity, Int>): Monster {
        // Simple weighted RNG logic for Phase 1
        val pool = monsters.flatMap { monster ->
            List(rarityWeights[monster.rarity] ?: 1) { monster }
        }
        return pool.random()
    }
}
