package com.gymies.levelrise.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.gymies.levelrise.ui.screens.*

@Composable
fun SetupNavGraph(navController: NavHostController) {
    NavHost(
        navController = navController,
        startDestination = Screen.Auth.route
    ) {
        composable(route = Screen.Auth.route) {
            AuthScreen(navController)
        }
        composable(route = Screen.Home.route) {
            HomeScreen(navController)
        }
        composable(route = Screen.RunTracker.route) {
            RunTrackerScreen(navController)
        }
        composable(route = Screen.WorkoutLogger.route) {
            WorkoutLoggerScreen(navController)
        }
        composable(route = Screen.MonsterCollection.route) {
            MonsterCollectionScreen(navController)
        }
        composable(route = Screen.BattleArena.route) {
            BattleArenaScreen(navController)
        }
        composable(route = Screen.ProfileSetup.route) {
            ProfileSetupScreen(navController)
        }
        composable(route = Screen.Leaderboard.route) {
            LeaderboardScreen(navController)
        }
        composable(route = Screen.Quests.route) {
            QuestsScreen(navController)
        }
        composable(route = Screen.DeckBuilder.route) {
            DeckBuilderScreen(navController)
        }
        composable(route = Screen.Friends.route) {
            FriendsScreen(navController)
        }
        composable(route = Screen.Settings.route) {
            SettingsScreen(navController)
        }
        composable(route = Screen.Marketplace.route) {
            MarketplaceScreen(navController)
        }
    }
}
