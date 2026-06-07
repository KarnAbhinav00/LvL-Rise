package com.gymies.levelrise.ui.viewmodel

import androidx.lifecycle.ViewModel
import com.gymies.levelrise.domain.model.User
import com.gymies.levelrise.domain.model.UserStats
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class HomeViewModel : ViewModel() {
    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user.asStateFlow()

    init {
        // Mock data for Phase 1 MVP
        _user.value = User(
            id = "user123",
            username = "GymHero_99",
            age = 25,
            height = 180f,
            weight = 75f,
            fitnessGoal = "Muscle Gain",
            level = 5,
            xp = 1250,
            stats = UserStats(
                strength = 15,
                endurance = 12,
                agility = 10,
                discipline = 20,
                recovery = 8
            ),
            avatarId = "avatar_01",
            gold = 500
        )
    }
}
