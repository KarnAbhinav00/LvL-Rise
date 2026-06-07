package com.gymies.levelrise.domain.model

enum class WorkoutType {
    STRENGTH, YOGA, HIIT, RUN
}

data class Workout(
    val id: String,
    val userId: String,
    val type: WorkoutType,
    val durationMillis: Long,
    val timestamp: Long = System.currentTimeMillis(),
    val exercises: List<Exercise> = emptyList(),
    val xpEarned: Long = 0,
    val goldEarned: Long = 0
)

data class Exercise(
    val name: String,
    val sets: List<WorkoutSet>
)

data class WorkoutSet(
    val reps: Int,
    val weightKg: Float? = null
)

data class RunSession(
    val id: String,
    val userId: String,
    val distanceMeters: Double,
    val durationMillis: Long,
    val startTime: Long,
    val endTime: Long,
    val route: List<LatLng>,
    val averagePace: Double, // min/km
    val xpEarned: Long = 0
)

data class LatLng(
    val latitude: Double,
    val longitude: Double,
    val timestamp: Long
)
