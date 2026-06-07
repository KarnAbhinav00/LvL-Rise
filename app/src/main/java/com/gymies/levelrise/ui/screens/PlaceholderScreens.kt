package com.gymies.levelrise.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController

@Composable
fun WorkoutLoggerScreen(navController: NavController) {
    PlaceholderScreen("Gym Logger")
}

@Composable
fun BattleArenaScreen(navController: NavController) {
    PlaceholderScreen("Battle Arena")
}

@Composable
fun ProfileSetupScreen(navController: NavController) {
    PlaceholderScreen("Profile Setup")
}

@Composable
fun LeaderboardScreen(navController: NavController) {
    PlaceholderScreen("Leaderboard")
}

@Composable
fun QuestsScreen(navController: NavController) {
    PlaceholderScreen("Quest Board")
}

@Composable
fun DeckBuilderScreen(navController: NavController) {
    PlaceholderScreen("Deck Builder")
}

@Composable
fun FriendsScreen(navController: NavController) {
    PlaceholderScreen("Friends")
}

@Composable
fun SettingsScreen(navController: NavController) {
    PlaceholderScreen("Settings")
}

@Composable
fun MarketplaceScreen(navController: NavController) {
    PlaceholderScreen("Marketplace")
}

@Composable
fun PlaceholderScreen(title: String) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364))
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title.uppercase(),
            color = Color.White.copy(alpha = 0.3f),
            fontSize = 32.sp,
            fontWeight = FontWeight.Black
        )
    }
}
