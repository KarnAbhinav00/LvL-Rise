package com.gymies.levelrise.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.gymies.levelrise.data.repository.UserRepository
import com.gymies.levelrise.domain.model.User
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class HomeViewModel : ViewModel() {
    private val repository = UserRepository()

    private val _user = MutableStateFlow<User?>(null)
    val user: StateFlow<User?> = _user.asStateFlow()

    init {
        viewModelScope.launch {
            repository.fetchCurrentUser()
        }
        viewModelScope.launch {
            repository.currentUser.collect { user ->
                _user.value = user
            }
        }
    }
}
