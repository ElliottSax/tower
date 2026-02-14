using UnityEngine;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Manages audio playback for sound effects and music.
    /// Stub implementation - extend with full audio system as needed.
    /// </summary>
    public class AudioManager : MonoBehaviour
    {
        public static AudioManager Instance { get; private set; }

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// Plays a sound effect by name.
        /// </summary>
        public void PlaySFX(string sfxName)
        {
            Debug.Log($"AudioManager: PlaySFX({sfxName}) - not yet implemented");
        }

        /// <summary>
        /// Plays background music by name.
        /// </summary>
        public void PlayMusic(string musicName)
        {
            Debug.Log($"AudioManager: PlayMusic({musicName}) - not yet implemented");
        }

        /// <summary>
        /// Stops all audio.
        /// </summary>
        public void StopAll()
        {
            Debug.Log("AudioManager: StopAll - not yet implemented");
        }
    }
}
