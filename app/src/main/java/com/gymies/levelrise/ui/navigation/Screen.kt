package com.gymies.levelrise.ui.navigation

sealed class Screen(val route: String) {
    object Auth : Screen("auth")
    object Home : Screen("home")
    object RunTracker : Screen("run_tracker")
    object WorkoutLogger : Screen("workout_logger")
    object MonsterCollection : Screen("monster_collection")
    object BattleArena : Screen("battle_arena")
    object ProfileSetup : Screen("profile_setup")
    object Leaderboard : Screen("leaderboard")
    object Quests : Screen("quests")
    object DeckBuilder : Screen("deck_builder")
    object Friends : Screen("friends")
    object Settings : Screen("settings")
    object Marketplace : Screen("marketplace")
    object HealthTracker : Screen("health_tracker")
    object Shop : Screen("shop")
    object Achievements : Screen("achievements")
}
