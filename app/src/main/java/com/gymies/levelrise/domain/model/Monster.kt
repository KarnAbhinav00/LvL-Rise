package com.gymies.levelrise.domain.model

enum class Rarity {
    COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
}

data class Monster(
    val id: String,
    val name: String,
    val rarity: Rarity,
    val baseAttack: Int,
    val baseDefense: Int,
    val baseSpeed: Int,
    val type: String,
    val imageUrl: String
)

data class Card(
    val id: String,
    val monster: Monster,
    val level: Int = 1,
    val customName: String? = null
)
