package com.gymies.levelrise.domain.service

import android.location.Location
import com.gymies.levelrise.domain.model.LatLng
import kotlin.math.*

object AntiCheatService {
    private const val MAX_SPEED_MPS = 12.0 // ~43 km/h (Usain Bolt speed cap)
    private const val MAX_TELEPORT_DISTANCE_METERS = 200.0
    private const val MIN_TIME_FOR_TELEPORT_SEC = 5.0

    /**
     * Validates if the movement between two locations is physically possible for a human.
     * Returns true if valid, false if suspicious.
     */
    fun isMovementValid(lastLocation: LatLng?, newLocation: Location): Boolean {
        if (lastLocation == null) return true

        val distance = calculateDistance(
            lastLocation.latitude, lastLocation.longitude,
            newLocation.latitude, newLocation.longitude
        )
        
        val timeDeltaSec = (newLocation.time - lastLocation.timestamp) / 1000.0
        
        if (timeDeltaSec <= 0) return false

        val speed = distance / timeDeltaSec

        // 1. Speed cap check
        if (speed > MAX_SPEED_MPS) return false

        // 2. Teleport detection
        if (distance > MAX_TELEPORT_DISTANCE_METERS && timeDeltaSec < MIN_TIME_FOR_TELEPORT_SEC) {
            return false
        }

        return true
    }

    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val r = 6371e3 // Earth radius in meters
        val phi1 = lat1 * PI / 180
        val phi2 = lat2 * PI / 180
        val deltaPhi = (lat2 - lat1) * PI / 180
        val deltaLambda = (lon2 - lon1) * PI / 180

        val a = sin(deltaPhi / 2).pow(2) +
                cos(phi1) * cos(phi2) * sin(deltaLambda / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))

        return r * c
    }
}
