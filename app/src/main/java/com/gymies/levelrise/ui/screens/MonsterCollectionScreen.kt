package com.gymies.levelrise.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.gymies.levelrise.domain.model.Monster
import com.gymies.levelrise.domain.model.Rarity
import com.gymies.levelrise.domain.service.MonsterService

@Composable
fun MonsterCollectionScreen(navController: NavController) {
    val monsters = MonsterService.monsters

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364))
                )
            )
    ) {
        Column(modifier = Modifier.fillMaxSize().padding(16.dp)) {
            Text(
                text = "MONSTER COLLECTION",
                style = MaterialTheme.typography.headlineSmall,
                fontWeight = FontWeight.Black,
                color = Color.White,
                letterSpacing = 2.sp,
                modifier = Modifier.padding(bottom = 24.dp)
            )

            LazyVerticalGrid(
                columns = GridCells.Fixed(2),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(monsters) { monster ->
                    MonsterCard(monster)
                }
            }
        }
    }
}

@Composable
fun MonsterCard(monster: Monster) {
    val rarityColor = when (monster.rarity) {
        Rarity.COMMON -> Color(0xFFAAAAAA)
        Rarity.UNCOMMON -> Color(0xFF00E676)
        Rarity.RARE -> Color(0xFF2979FF)
        Rarity.EPIC -> Color(0xFFD500F9)
        Rarity.LEGENDARY -> Color(0xFFFFD600)
    }

    Surface(
        modifier = Modifier.fillMaxWidth().height(220.dp),
        color = Color.White.copy(alpha = 0.05f),
        shape = RectangleShape,
        border = BorderStroke(0.5.dp, Color.White.copy(alpha = 0.2f))
    ) {
        Column(
            modifier = Modifier.padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Box(
                modifier = Modifier.size(90.dp).padding(8.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(text = "👾", fontSize = 48.sp)
            }
            
            Text(
                text = monster.name.uppercase(),
                fontWeight = FontWeight.Black,
                maxLines = 1,
                color = Color.White,
                fontSize = 14.sp
            )
            
            Text(
                text = monster.rarity.name,
                color = rarityColor,
                fontSize = 10.sp,
                fontWeight = FontWeight.Black,
                letterSpacing = 1.sp
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                MonsterStatSmall("ATK", monster.baseAttack)
                MonsterStatSmall("DEF", monster.baseDefense)
                MonsterStatSmall("SPD", monster.baseSpeed)
            }
        }
    }
}

@Composable
fun MonsterStatSmall(label: String, value: Int) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = label, fontSize = 9.sp, color = Color.White.copy(alpha = 0.5f), fontWeight = FontWeight.Bold)
        Text(text = value.toString(), fontSize = 13.sp, fontWeight = FontWeight.Black, color = Color.White)
    }
}
