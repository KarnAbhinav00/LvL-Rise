package com.gymies.levelrise.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.RectangleShape
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavController
import com.gymies.levelrise.ui.viewmodel.RunViewModel
import java.util.Locale

@Composable
fun RunTrackerScreen(navController: NavController, viewModel: RunViewModel = viewModel()) {
    val runState by viewModel.runState.collectAsState()
    val context = LocalContext.current

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364))
                )
            )
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "GPS RUN TRACKER",
                style = MaterialTheme.typography.titleMedium,
                color = Color.Cyan,
                fontWeight = FontWeight.Black,
                letterSpacing = 2.sp
            )

            Spacer(modifier = Modifier.height(48.dp))

            Text(
                text = String.format(Locale.getDefault(), "%.2f", runState.distanceMeters / 1000.0),
                fontSize = 100.sp,
                fontWeight = FontWeight.Black,
                color = Color.White
            )
            Text(
                text = "KILOMETERS", 
                fontSize = 16.sp, 
                letterSpacing = 4.sp,
                color = Color.White.copy(alpha = 0.6f),
                fontWeight = FontWeight.Bold
            )

            Spacer(modifier = Modifier.height(48.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceEvenly
            ) {
                RunStatItem(
                    label = "PACE",
                    value = if (runState.currentSpeed > 0) String.format(Locale.getDefault(), "%.1f", 16.6667 / runState.currentSpeed) else "0.0",
                    unit = "min/km"
                )
                RunStatItem(
                    label = "SPEED",
                    value = String.format(Locale.getDefault(), "%.1f", runState.currentSpeed * 3.6),
                    unit = "km/h"
                )
            }

            Spacer(modifier = Modifier.height(80.dp))

            if (!runState.isTracking) {
                Button(
                    onClick = { viewModel.startTracking(context) },
                    modifier = Modifier.size(120.dp),
                    shape = RectangleShape,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF00E676)),
                    elevation = ButtonDefaults.buttonElevation(defaultElevation = 8.dp)
                ) {
                    Text("START", fontWeight = FontWeight.Black, color = Color.Black)
                }
            } else {
                Button(
                    onClick = { viewModel.stopTracking() },
                    modifier = Modifier.size(120.dp),
                    shape = RectangleShape,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFFF1744)),
                    elevation = ButtonDefaults.buttonElevation(defaultElevation = 8.dp)
                ) {
                    Text("STOP", fontWeight = FontWeight.Black, color = Color.White)
                }
            }

            runState.error?.let {
                Text(
                    text = it,
                    color = Color.Red,
                    modifier = Modifier.padding(top = 24.dp),
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
fun RunStatItem(label: String, value: String, unit: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(text = label, color = Color.White.copy(alpha = 0.5f), fontWeight = FontWeight.Bold, fontSize = 12.sp)
        Text(text = value, fontSize = 32.sp, fontWeight = FontWeight.Black, color = Color.White)
        Text(text = unit, color = Color.White.copy(alpha = 0.5f), fontSize = 10.sp)
    }
}
