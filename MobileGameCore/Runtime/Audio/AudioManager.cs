using UnityEngine;
using System.Collections.Generic;

namespace MobileGameCore
{
    /// <summary>
    /// Singleton audio manager for music and SFX.
    /// Handles volume settings, audio pooling, and cross-scene persistence.
    /// OPTIMIZED: Reduced SFX pool size for mobile performance (3 sources)
    ///
    /// USAGE:
    /// - Music: AudioManager.Instance.PlayMusic(musicClip);
    /// - SFX: AudioManager.Instance.PlaySFX(soundClip);
    /// - Named SFX: AudioManager.Instance.PlaySFX("button_click");
    /// - Volume: AudioManager.Instance.SetMusicVolume(0.7f);
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance { get; private set; }

        [Header("Audio Sources")]
        [SerializeField] private AudioSource musicSource;
        [SerializeField] private AudioSource ambientSource;

        [Header("SFX Pool")]
        [Tooltip("Number of simultaneous SFX sounds. 3 is optimal for mobile.")]
        [SerializeField] private int sfxSourceCount = 3; // Optimized for mobile
        private List<AudioSource> sfxSources = new List<AudioSource>();
        private int currentSFXIndex = 0;

        [Header("Music Clips (Optional - can be set at runtime)")]
        [SerializeField] private AudioClip menuMusic;
        [SerializeField] private AudioClip gameplayMusic;
        [SerializeField] private AudioClip victoryMusic;

        [Header("Common SFX Clips (Optional - can be set at runtime)")]
        [SerializeField] private AudioClip buttonClick;
        [SerializeField] private AudioClip itemCollect;
        [SerializeField] private AudioClip purchaseSuccess;
        [SerializeField] private AudioClip purchaseFail;
        [SerializeField] private AudioClip levelComplete;
        [SerializeField] private AudioClip levelFail;

        [Header("Volume Settings")]
        [Range(0f, 1f)] [SerializeField] private float masterVolume = 1f;
        [Range(0f, 1f)] [SerializeField] private float musicVolume = 0.7f;
        [Range(0f, 1f)] [SerializeField] private float sfxVolume = 1f;

        private Dictionary<string, AudioClip> soundLibrary = new Dictionary<string, AudioClip>();
        private bool isInitialized = false;

        void Awake()
        {
            // Singleton pattern
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
                InitializeAudio();
            }
            else
            {
                Destroy(gameObject);
            }
        }

        void InitializeAudio()
        {
            // Create SFX source pool
            for (int i = 0; i < sfxSourceCount; i++)
            {
                GameObject sfxObject = new GameObject($"SFX_Source_{i}");
                sfxObject.transform.SetParent(transform);
                AudioSource source = sfxObject.AddComponent<AudioSource>();
                source.playOnAwake = false;
                source.spatialBlend = 0f; // 2D audio
                sfxSources.Add(source);
            }

            // Build sound library for easy access (with null checks)
            if (buttonClick != null) soundLibrary["button_click"] = buttonClick;
            if (itemCollect != null) soundLibrary["item_collect"] = itemCollect;
            if (purchaseSuccess != null) soundLibrary["purchase_success"] = purchaseSuccess;
            if (purchaseFail != null) soundLibrary["purchase_fail"] = purchaseFail;
            if (levelComplete != null) soundLibrary["level_complete"] = levelComplete;
            if (levelFail != null) soundLibrary["level_fail"] = levelFail;

            // Load saved settings
            LoadSettings();

            // Configure music source
            if (musicSource != null)
            {
                musicSource.loop = true;
                musicSource.volume = musicVolume * masterVolume;
                musicSource.playOnAwake = false;
            }
            else
            {
                Debug.LogWarning("[AudioManager] Music source not assigned!");
            }

            // Configure ambient source
            if (ambientSource != null)
            {
                ambientSource.loop = true;
                ambientSource.volume = sfxVolume * masterVolume * 0.5f;
                ambientSource.playOnAwake = false;
            }

            isInitialized = true;
            Debug.Log($"[AudioManager] Initialized with {sfxSources.Count} SFX sources");
        }

        #region Music Control

        public void PlayMenuMusic()
        {
            PlayMusic(menuMusic);
        }

        public void PlayGameplayMusic()
        {
            PlayMusic(gameplayMusic);
        }

        public void PlayVictoryMusic()
        {
            PlayMusic(victoryMusic, loop: false);
        }

        public void PlayMusic(AudioClip clip, bool loop = true)
        {
            if (!isInitialized)
            {
                Debug.LogWarning("[AudioManager] Not initialized yet");
                return;
            }

            if (musicSource == null)
            {
                Debug.LogWarning("[AudioManager] Music source is null");
                return;
            }

            if (clip == null)
            {
                Debug.LogWarning("[AudioManager] Music clip is null");
                return;
            }

            // Don't restart if already playing
            if (musicSource.clip == clip && musicSource.isPlaying) return;

            musicSource.clip = clip;
            musicSource.loop = loop;
            musicSource.volume = musicVolume * masterVolume;
            musicSource.Play();
        }

        public void StopMusic()
        {
            if (musicSource != null && musicSource.isPlaying)
            {
                musicSource.Stop();
            }
        }

        public void PauseMusic()
        {
            if (musicSource != null && musicSource.isPlaying)
            {
                musicSource.Pause();
            }
        }

        public void ResumeMusic()
        {
            if (musicSource != null)
            {
                musicSource.UnPause();
            }
        }

        #endregion

        #region SFX Control

        /// <summary>
        /// Play sound effect by name (uses sound library)
        /// </summary>
        public void PlaySFX(string soundName, float volumeScale = 1f)
        {
            if (!isInitialized)
            {
                Debug.LogWarning("[AudioManager] Not initialized yet");
                return;
            }

            if (string.IsNullOrEmpty(soundName))
            {
                Debug.LogWarning("[AudioManager] Sound name is null or empty");
                return;
            }

            if (soundLibrary.TryGetValue(soundName, out AudioClip clip))
            {
                PlaySFX(clip, volumeScale);
            }
            else
            {
                Debug.LogWarning($"[AudioManager] Sound '{soundName}' not found in library!");
            }
        }

        /// <summary>
        /// Play sound effect by AudioClip reference
        /// </summary>
        public void PlaySFX(AudioClip clip, float volumeScale = 1f)
        {
            if (!isInitialized || clip == null || sfxSources.Count == 0) return;

            // Validate volume scale
            if (volumeScale < 0f)
            {
                Debug.LogWarning($"[AudioManager] Negative volume scale: {volumeScale}, clamping to 0");
                volumeScale = 0f;
            }

            // Get next available source (round-robin)
            AudioSource source = sfxSources[currentSFXIndex];
            currentSFXIndex = (currentSFXIndex + 1) % sfxSources.Count;

            // Play sound
            float finalVolume = sfxVolume * masterVolume * volumeScale;
            source.PlayOneShot(clip, finalVolume);
        }

        /// <summary>
        /// Play sound effect at world position (3D spatial audio)
        /// </summary>
        public void PlaySFXAtPosition(AudioClip clip, Vector3 position, float volumeScale = 1f)
        {
            if (!isInitialized || clip == null) return;

            float finalVolume = sfxVolume * masterVolume * volumeScale;
            AudioSource.PlayClipAtPoint(clip, position, finalVolume);
        }

        /// <summary>
        /// Register a sound in the library for easy access by name
        /// </summary>
        public void RegisterSound(string soundName, AudioClip clip)
        {
            if (string.IsNullOrEmpty(soundName) || clip == null)
            {
                Debug.LogWarning("[AudioManager] Invalid sound registration");
                return;
            }

            soundLibrary[soundName] = clip;
        }

        /// <summary>
        /// Unregister a sound from the library
        /// </summary>
        public void UnregisterSound(string soundName)
        {
            soundLibrary.Remove(soundName);
        }

        // Convenience methods for common sounds
        public void PlayButtonClick() => PlaySFX("button_click", 0.5f);
        public void PlayItemCollect() => PlaySFX("item_collect");
        public void PlayPurchaseSuccess() => PlaySFX("purchase_success");
        public void PlayPurchaseFail() => PlaySFX("purchase_fail");
        public void PlayLevelComplete() => PlaySFX("level_complete");
        public void PlayLevelFail() => PlaySFX("level_fail");

        #endregion

        #region Ambient Audio

        public void PlayAmbient(AudioClip clip, float volumeScale = 1f)
        {
            if (ambientSource == null || clip == null) return;

            ambientSource.clip = clip;
            ambientSource.volume = sfxVolume * masterVolume * volumeScale * 0.5f;
            ambientSource.loop = true;
            ambientSource.Play();
        }

        public void StopAmbient()
        {
            if (ambientSource != null && ambientSource.isPlaying)
            {
                ambientSource.Stop();
            }
        }

        #endregion

        #region Volume Control

        public void SetMasterVolume(float volume)
        {
            masterVolume = Mathf.Clamp01(volume);
            ApplyVolumeSettings();
            SaveSettings();
        }

        public void SetMusicVolume(float volume)
        {
            musicVolume = Mathf.Clamp01(volume);
            ApplyVolumeSettings();
            SaveSettings();
        }

        public void SetSFXVolume(float volume)
        {
            sfxVolume = Mathf.Clamp01(volume);
            ApplyVolumeSettings();
            SaveSettings();
        }

        public float GetMasterVolume() => masterVolume;
        public float GetMusicVolume() => musicVolume;
        public float GetSFXVolume() => sfxVolume;

        void ApplyVolumeSettings()
        {
            if (musicSource != null)
            {
                musicSource.volume = musicVolume * masterVolume;
            }

            if (ambientSource != null)
            {
                ambientSource.volume = sfxVolume * masterVolume * 0.5f;
            }
        }

        void LoadSettings()
        {
            masterVolume = PlayerPrefs.GetFloat("Audio_MasterVolume", 1f);
            musicVolume = PlayerPrefs.GetFloat("Audio_MusicVolume", 0.7f);
            sfxVolume = PlayerPrefs.GetFloat("Audio_SFXVolume", 1f);

            ApplyVolumeSettings();
        }

        public void SaveSettings()
        {
            PlayerPrefs.SetFloat("Audio_MasterVolume", masterVolume);
            PlayerPrefs.SetFloat("Audio_MusicVolume", musicVolume);
            PlayerPrefs.SetFloat("Audio_SFXVolume", sfxVolume);
            PlayerPrefs.Save();
        }

        #endregion

        #region Utility

        /// <summary>
        /// Mute all audio (useful for ads, phone calls, etc.)
        /// </summary>
        public void MuteAll()
        {
            AudioListener.volume = 0f;
        }

        /// <summary>
        /// Unmute all audio
        /// </summary>
        public void UnmuteAll()
        {
            AudioListener.volume = 1f;
        }

        /// <summary>
        /// Check if music is currently playing
        /// </summary>
        public bool IsMusicPlaying()
        {
            return musicSource != null && musicSource.isPlaying;
        }

        /// <summary>
        /// Get sound library (for debugging)
        /// </summary>
        public Dictionary<string, AudioClip> GetSoundLibrary()
        {
            return soundLibrary;
        }

        #endregion

        void OnApplicationPause(bool pauseStatus)
        {
            // Pause music when app goes to background
            if (pauseStatus)
            {
                PauseMusic();
            }
            else
            {
                // Don't auto-resume - let game logic decide
                // This prevents music starting when user views notification
            }
        }
    }
}
