package com.gymies.levelrise.domain.service

import kotlin.math.pow

object ExperienceService {
    private const val BASE_XP = 100.0
    private const val EXPONENT = 1.5

    /**
     * Calculates the total XP required to reach a specific level.
     */
    fun getXPForLevel(level: Int): Long {
        if (level <= 1) return 0
        return (BASE_XP * (level - 1).toDouble().pow(EXPONENT)).toLong()
    }

    /**
     * Calculates the current level based on total XP.
     */
    fun getLevelForXP(xp: Long): Int {
        var level = 1
        while (getXPForLevel(level + 1) <= xp) {
            level++
        }
        return level
    }

    /**
     * Calculates the progress towards the next level as a percentage (0.0 to 1.0).
     */
    fun getLevelProgress(xp: Long): Float {
        val currentLevel = getLevelForXP(xp)
        val xpForCurrent = getXPForLevel(currentLevel)
        val xpForNext = getXPForLevel(currentLevel + 1)
        
        val xpInCurrentLevel = xp - xpForCurrent
        val xpRequiredForLevel = xpForNext - xpForCurrent
        
        return if (xpRequiredForLevel > 0) {
            (xpInCurrentLevel.toFloat() / xpRequiredForLevel.toFloat()).coerceIn(0f, 1f)
        } else {
            0f
        }
    }
}
