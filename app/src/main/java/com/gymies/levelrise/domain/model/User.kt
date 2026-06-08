package com.gymies.levelrise.domain.model

data class User(
    val id: String,
    val username: String,
    val age: Int,
    val height: Float, // in cm
    val weight: Float, // in kg
    val fitnessGoal: String,
    val level: Int = 1,
    val xp: Long = 0,
    val stats: UserStats,
    val avatarId: String,
    val gold: Long = 0,
    val gems: Int = 0,
    val isPremium: Boolean = false,
    val trustScore: Int = 100,
    val joinDate: Long = System.currentTimeMillis()
)

data class UserStats(
    val strength: Int = 10,
    val endurance: Int = 10,
    val agility: Int = 10,
    val discipline: Int = 10,
    val recovery: Int = 10
)
