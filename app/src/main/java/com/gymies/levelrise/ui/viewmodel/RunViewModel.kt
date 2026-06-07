package com.gymies.levelrise.ui.viewmodel

import android.content.Context
import android.location.Location
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.location.LocationServices
import com.gymies.levelrise.data.location.DefaultLocationClient
import com.gymies.levelrise.data.location.LocationClient
import com.gymies.levelrise.domain.model.LatLng
import com.gymies.levelrise.domain.service.AntiCheatService
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach

data class RunState(
    val isTracking: Boolean = false,
    val distanceMeters: Double = 0.0,
    val currentSpeed: Float = 0f,
    val route: List<LatLng> = emptyList(),
    val error: String? = null
)

class RunViewModel : ViewModel() {
    private val _runState = MutableStateFlow(RunState())
    val runState: StateFlow<RunState> = _runState.asStateFlow()

    private var locationJob: Job? = null
    private var locationClient: LocationClient? = null

    fun startTracking(context: Context) {
        if (_runState.value.isTracking) return

        val fusedLocationClient = LocationServices.getFusedLocationProviderClient(context)
        locationClient = DefaultLocationClient(
            context,
            fusedLocationClient
        )

        _runState.value = _runState.value.copy(isTracking = true, error = null)

        locationJob = locationClient!!
            .getLocationUpdates(2000L)
            .catch { e -> _runState.value = _runState.value.copy(error = e.message) }
            .onEach { location ->
                updateRunData(location)
            }
            .launchIn(viewModelScope)
    }

    private fun updateRunData(location: Location) {
        val currentState = _runState.value
        val lastLatLng = currentState.route.lastOrNull()
        
        if (AntiCheatService.isMovementValid(lastLatLng, location)) {
            val newLatLng = LatLng(location.latitude, location.longitude, location.time)
            val addedDistance = lastLatLng?.let {
                calculateDistance(it.latitude, it.longitude, location.latitude, location.longitude)
            } ?: 0.0

            _runState.value = currentState.copy(
                distanceMeters = currentState.distanceMeters + addedDistance,
                currentSpeed = location.speed,
                route = currentState.route + newLatLng
            )
        } else {
            // Suspicious movement detected
            _runState.value = currentState.copy(error = "Suspicious movement detected!")
        }
    }

    fun stopTracking() {
        locationJob?.cancel()
        _runState.value = _runState.value.copy(isTracking = false)
    }

    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0].toDouble()
    }
}
