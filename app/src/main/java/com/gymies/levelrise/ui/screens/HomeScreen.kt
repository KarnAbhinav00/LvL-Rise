package com.gymies.levelrise.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.gymies.levelrise.domain.model.User
import com.gymies.levelrise.domain.service.ExperienceService
import com.gymies.levelrise.domain.service.Quest
import com.gymies.levelrise.domain.service.QuestService
import com.gymies.levelrise.ui.viewmodel.HomeViewModel

@Composable
fun HomeScreen(navController: NavController, viewModel: HomeViewModel = viewModel()) {
    val user by viewModel.user.collectAsState()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364))
                )
            )
    ) {
        user?.let { userData ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = userData.username,
                    style = MaterialTheme.typography.headlineMedium,
                    fontWeight = FontWeight.Black,
                    color = Color.White
                )
                
                Spacer(modifier = Modifier.height(16.dp))
                
                LevelSection(userData)
                
                Spacer(modifier = Modifier.height(24.dp))
                
                StatsSection(userData)
                
                Spacer(modifier = Modifier.height(24.dp))
                
                CurrencySection(userData)

                Spacer(modifier = Modifier.height(24.dp))

                QuestSection(userData)
                
                Spacer(modifier = Modifier.height(32.dp))
            }
        } ?: Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(color = Color.Cyan)
        }
    }
}

@Composable
fun GlassyCard(
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit
) {
    Surface(
        modifier = modifier,
        color = Color.White.copy(alpha = 0.05f),
        shape = RectangleShape,
        border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.2f))
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            content = content
        )
    }
}

@Composable
fun LevelSection(user: User) {
    val progress = ExperienceService.getLevelProgress(user.xp)
    
    GlassyCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "LEVEL ${user.level}",
                fontWeight = FontWeight.Black,
                fontSize = 24.sp,
                color = Color.Cyan
            )
            Text(text = "${user.xp} XP", color = Color.White.copy(alpha = 0.7f))
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        LinearProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxWidth().height(8.dp),
            color = Color.Cyan,
            trackColor = Color.White.copy(alpha = 0.1f),
            strokeCap = androidx.compose.ui.graphics.StrokeCap.Butt
        )
        
        Text(
            text = "NEXT LEVEL AT ${ExperienceService.getXPForLevel(user.level + 1)} XP",
            style = MaterialTheme.typography.labelSmall,
            color = Color.White.copy(alpha = 0.5f),
            modifier = Modifier.align(Alignment.End).padding(top = 4.dp)
        )
    }
}

@Composable
fun StatsSection(user: User) {
    GlassyCard(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "CHARACTER STATS",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            letterSpacing = 2.sp
        )
        Spacer(modifier = Modifier.height(16.dp))
        
        StatRow("STR", user.stats.strength, Color(0xFFFF5252))
        StatRow("END", user.stats.endurance, Color(0xFF448AFF))
        StatRow("AGI", user.stats.agility, Color(0xFF69F0AE))
        StatRow("DISC", user.stats.discipline, Color(0xFFFFD740))
        StatRow("REC", user.stats.recovery, Color(0xFFE040FB))
    }
}

@Composable
fun StatRow(label: String, value: Int, color: Color) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label, color = Color.White.copy(alpha = 0.8f), fontWeight = FontWeight.Bold)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .height(4.dp)
                    .width(100.dp)
                    .background(Color.White.copy(alpha = 0.1f))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxHeight()
                        .fillMaxWidth(fraction = (value / 100f).coerceIn(0f, 1f))
                        .background(color)
                )
            }
            Spacer(modifier = Modifier.width(8.dp))
            Text(text = value.toString(), fontWeight = FontWeight.Black, color = color)
        }
    }
}

@Composable
fun CurrencySection(user: User) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.Center
    ) {
        Surface(
            color = Color(0xFFFFD700).copy(alpha = 0.15f),
            shape = RectangleShape,
            border = BorderStroke(1.dp, Color(0xFFFFD700).copy(alpha = 0.3f))
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 24.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "GOLD: ${user.gold}",
                    fontWeight = FontWeight.Black,
                    color = Color(0xFFFFD700),
                    letterSpacing = 1.sp
                )
            }
        }
    }
}

@Composable
fun QuestSection(user: User) {
    val quests = remember { QuestService.generateDailyQuests(user) }

    Column(modifier = Modifier.fillMaxWidth()) {
        Text(
            text = "ACTIVE QUESTS",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Black,
            color = Color.White,
            letterSpacing = 2.sp,
            modifier = Modifier.padding(bottom = 12.dp)
        )

        quests.forEach { quest ->
            QuestItem(quest)
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

@Composable
fun QuestItem(quest: Quest) {
    GlassyCard(modifier = Modifier.fillMaxWidth()) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(text = quest.title, fontWeight = FontWeight.Bold, color = Color.White)
                Text(
                    text = quest.description,
                    style = MaterialTheme.typography.bodySmall,
                    color = Color.White.copy(alpha = 0.6f)
                )
            }
            
            Column(horizontalAlignment = Alignment.End) {
                Text(text = "+${quest.rewardXP} XP", color = Color(0xFF69F0AE), fontWeight = FontWeight.Bold, fontSize = 11.sp)
                Text(text = "+${quest.rewardGold} GOLD", color = Color(0xFFFFD740), fontWeight = FontWeight.Bold, fontSize = 11.sp)
            }
        }
        
        Spacer(modifier = Modifier.height(12.dp))
        
        LinearProgressIndicator(
            progress = { quest.currentValue / quest.targetValue },
            modifier = Modifier.fillMaxWidth().height(4.dp),
            color = Color.White,
            trackColor = Color.White.copy(alpha = 0.1f),
            strokeCap = androidx.compose.ui.graphics.StrokeCap.Butt
        )
    }
}
