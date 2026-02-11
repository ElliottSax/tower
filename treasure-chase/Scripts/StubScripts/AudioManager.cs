using UnityEngine;

/// <summary>
/// STUB AudioManager for Day 1 setup.
/// Replace with real AudioManager from Treasure Multiplier later.
/// </summary>
public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    void Awake()
    {
        // Singleton pattern
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
    /// Plays a sound effect
    /// </summary>
    public void PlaySFX(string soundName, float volume = 1f, float pitch = 1f)
    {
        Debug.Log($"[STUB] AudioManager.PlaySFX: {soundName} (volume: {volume}, pitch: {pitch})");
        // TODO: Replace with actual audio playback
    }

    /// <summary>
    /// Plays background music
    /// </summary>
    public void PlayMusic(string musicName, float fadeTime = 1f)
    {
        Debug.Log($"[STUB] AudioManager.PlayMusic: {musicName} (fade: {fadeTime}s)");
        // TODO: Replace with actual music playback
    }

    /// <summary>
    /// Plays a chord sound
    /// </summary>
    public void PlayChord(float frequency, float duration)
    {
        Debug.Log($"[STUB] AudioManager.PlayChord: {frequency}Hz for {duration}s");
        // TODO: Replace with actual chord synthesis
    }

    /// <summary>
    /// Stops current music
    /// </summary>
    public void StopMusic(float fadeTime = 1f)
    {
        Debug.Log($"[STUB] AudioManager.StopMusic (fade: {fadeTime}s)");
    }

    /// <summary>
    /// Sets master volume
    /// </summary>
    public void SetVolume(float volume)
    {
        Debug.Log($"[STUB] AudioManager.SetVolume: {volume}");
    }
}
