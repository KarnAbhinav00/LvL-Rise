package com.gymies.levelrise.domain.service

import com.gymies.levelrise.domain.model.User

data class Quest(
    val id: String,
    val title: String,
    val description: String,
    val targetValue: Float,
    val currentValue: Float = 0f,
    val type: QuestType,
    val rewardXP: Long,
    val rewardGold: Long,
    val isCompleted: Boolean = false
)

enum class QuestType {
    RUN_DISTANCE, WORKOUT_COUNT, STREAK
}

object QuestService {
    
    fun generateDailyQuests(user: User): List<Quest> {
        val levelFactor = (user.level / 5) + 1
        
        return listOf(
            Quest(
                id = "q1",
                title = "Morning Jog",
                description = "Run ${2 * levelFactor} km today",
                targetValue = (2000 * levelFactor).toFloat(),
                type = QuestType.RUN_DISTANCE,
                rewardXP = 100L * levelFactor,
                rewardGold = 50L * levelFactor
            ),
            Quest(
                id = "q2",
                title = "Iron Will",
                description = "Complete ${1 * levelFactor} strength workout",
                targetValue = levelFactor.toFloat(),
                type = QuestType.WORKOUT_COUNT,
                rewardXP = 150L * levelFactor,
                rewardGold = 75L * levelFactor
            ),
            Quest(
                id = "q3",
                title = "Consistency is King",
                description = "Don't break your streak!",
                targetValue = 1f,
                type = QuestType.STREAK,
                rewardXP = 50L,
                rewardGold = 25L
            )
        )
    }
}
