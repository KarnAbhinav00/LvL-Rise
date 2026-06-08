package com.gymies.levelrise.ui.viewmodel

import android.content.Context
import android.util.Base64
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.PasswordCredential
import androidx.credentials.exceptions.GetCredentialException
import androidx.credentials.exceptions.NoCredentialException
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.gymies.levelrise.data.repository.UserRepository
import java.security.SecureRandom
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull

sealed class AuthState {
    object Idle : AuthState()
    object Loading : AuthState()
    object Success : AuthState()
    data class Error(val message: String) : AuthState()
}

class AuthViewModel : ViewModel() {
    private val repository = UserRepository()

    private val _authState = MutableStateFlow<AuthState>(AuthState.Idle)
    val authState: StateFlow<AuthState> = _authState.asStateFlow()

    private val googleClientId = "20636483482-3fis6bf0q1ri051o2vd5j3pb2eaf1mhl.apps.googleusercontent.com"

    private fun generateNonce(): String {
        val bytes = ByteArray(32)
        SecureRandom().nextBytes(bytes)
        return Base64.encodeToString(bytes, Base64.NO_WRAP or Base64.URL_SAFE)
    }

    fun signInWithGoogle(context: Context) {
        viewModelScope.launch {
            _authState.value = AuthState.Loading
            try {
                val credentialManager = CredentialManager.create(context)
                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(googleClientId)
                    .setAutoSelectEnabled(false)
                    .setNonce(generateNonce())
                    .build()
                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()
                val result = credentialManager.getCredential(context, request)
                handleSignIn(result)
            } catch (e: NoCredentialException) {
                _authState.value = AuthState.Error("No matching Google account found. Check your SHA-1 in Firebase Console.")
            } catch (e: GetCredentialException) {
                _authState.value = AuthState.Error("Google Sign-In failed: ${e.message}")
            } catch (e: Exception) {
                _authState.value = AuthState.Error("An unexpected error occurred: ${e.message}")
            }
        }
    }

    private suspend fun handleSignIn(result: GetCredentialResponse) {
        val credential = result.credential
        when (credential) {
            is GoogleIdTokenCredential -> {
                performFirebaseSignIn(credential.idToken)
            }
            is CustomCredential -> {
                if (credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                    try {
                        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                        performFirebaseSignIn(googleIdTokenCredential.idToken)
                    } catch (e: Exception) {
                        _authState.value = AuthState.Error("Error parsing Google ID Token: ${e.message}")
                    }
                } else {
                    _authState.value = AuthState.Error("Unexpected custom credential type: ${credential.type}")
                }
            }
            is PasswordCredential -> {
                _authState.value = AuthState.Error("Password sign-in is not supported here. Please choose your Google account.")
            }
            else -> {
                _authState.value = AuthState.Error("Unexpected credential type: ${credential.type}")
            }
        }
    }

    private suspend fun performFirebaseSignIn(idToken: String) {
        val result = withTimeoutOrNull(30000L) { // Increased to 30s
            repository.signInWithGoogle(idToken)
        }
        
        if (result == null) {
            _authState.value = AuthState.Error("Sign-in timed out (30s). This usually means the app can't talk to Firestore. Check your Database Rules.")
            return
        }

        if (result.isSuccess) {
            _authState.value = AuthState.Success
        } else {
            val error = result.exceptionOrNull()
            val techMessage = error?.message ?: "Unknown Error"
            
            val friendlyMessage = when {
                techMessage.contains("PERMISSION_DENIED") -> "Firestore Permission Denied. Check your Database Rules in Firebase Console."
                techMessage.contains("Cloud Firestore API has not been used") -> "Firestore API is still disabled in Google Cloud Console."
                else -> "Sign-in failed: $techMessage"
            }
            _authState.value = AuthState.Error(friendlyMessage)
        }
    }

    fun resetState() {
        _authState.value = AuthState.Idle
    }

    fun signOut() {
        repository.signOut()
        _authState.value = AuthState.Idle
    }
}
