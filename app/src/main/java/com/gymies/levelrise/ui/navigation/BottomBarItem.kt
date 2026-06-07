package com.gymies.levelrise.ui.navigation

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.PlayArrow
import androidx.compose.material.icons.filled.Star
import androidx.compose.ui.graphics.vector.ImageVector

sealed class BottomBarItem(
    val route: String,
    val title: String,
    val icon: ImageVector
) {
    object Home : BottomBarItem(
        route = Screen.Home.route,
        title = "Home",
        icon = Icons.Default.Home
    )
    object Run : BottomBarItem(
        route = Screen.RunTracker.route,
        title = "Run",
        icon = Icons.Default.LocationOn
    )
    object Workout : BottomBarItem(
        route = Screen.WorkoutLogger.route,
        title = "Gym",
        icon = Icons.Default.PlayArrow
    )
    object Battle : BottomBarItem(
        route = Screen.BattleArena.route,
        title = "Battle",
        icon = Icons.Default.Star
    )
    object Monsters : BottomBarItem(
        route = Screen.MonsterCollection.route,
        title = "Monsters",
        icon = Icons.AutoMirrored.Filled.List
    )
}
