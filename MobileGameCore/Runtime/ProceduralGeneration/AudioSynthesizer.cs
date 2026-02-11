using UnityEngine;
using System.Collections.Generic;

namespace MobileGameCore.ProceduralGeneration
{
    /// <summary>
    /// Procedural audio synthesis - generates sound effects at runtime.
    /// Creates bleeps, bloops, and effects without any audio files.
    /// Zero asset dependencies - all sounds generated programmatically!
    ///
    /// USAGE:
    /// AudioSynthesizer.Instance.PlaySound("collect", transform.position);
    /// AudioClip customSound = AudioSynthesizer.Instance.GenerateCustomTone(440f, 0.2f);
    /// </summary>
    public class AudioSynthesizer : MonoBehaviour
    {
        public static AudioSynthesizer Instance { get; private set; }

        [Header("Settings")]
        [SerializeField] private int sampleRate = 44100;
        [SerializeField] private float masterVolume = 0.5f;

        private Dictionary<string, AudioClip> synthesizedClips = new Dictionary<string, AudioClip>();

        public enum WaveType
        {
            Sine,
            Square,
            Triangle,
            Sawtooth,
            Noise
        }

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
                return;
            }

            GenerateDefaultSounds();
        }

        void GenerateDefaultSounds()
        {
            // Generate common game sounds
            synthesizedClips["collect"] = GenerateCollectSound();
            synthesizedClips["coin"] = GenerateCoinSound();
            synthesizedClips["powerup"] = GeneratePowerUpSound();
            synthesizedClips["button"] = GenerateButtonClick();
            synthesizedClips["success"] = GenerateSuccessSound();
            synthesizedClips["fail"] = GenerateFailSound();
            synthesizedClips["checkpoint"] = GenerateCheckpointSound();
            synthesizedClips["unlock"] = GenerateUnlockSound();
            synthesizedClips["level_up"] = GenerateLevelUpSound();
            synthesizedClips["damage"] = GenerateDamageSound();

            Debug.Log($"[AudioSynthesizer] Generated {synthesizedClips.Count} sounds");
        }

        #region Sound Generators

        AudioClip GenerateCollectSound()
        {
            // High pitched "ding"
            return GenerateTone(880f, 0.1f, 0.3f, WaveType.Sine);
        }

        AudioClip GenerateCoinSound()
        {
            // Ascending two-tone
            return GenerateChord(new float[] { 440f, 554f }, 0.15f, 0.4f);
        }

        AudioClip GeneratePowerUpSound()
        {
            // Rising sweep
            return GenerateSweep(440f, 880f, 0.3f, 0.5f);
        }

        AudioClip GenerateButtonClick()
        {
            // Short click
            return GenerateTone(1000f, 0.05f, 0.3f, WaveType.Square);
        }

        AudioClip GenerateSuccessSound()
        {
            // Ascending three-tone chord
            float[] frequencies = { 440f, 554f, 659f };
            return GenerateChord(frequencies, 0.25f, 0.4f);
        }

        AudioClip GenerateFailSound()
        {
            // Descending sweep
            return GenerateSweep(440f, 220f, 0.3f, 0.4f);
        }

        AudioClip GenerateCheckpointSound()
        {
            // Two-tone beep
            return GenerateChord(new float[] { 523f, 659f }, 0.2f, 0.4f);
        }

        AudioClip GenerateUnlockSound()
        {
            // Bright ascending cascade
            float[] frequencies = { 523f, 659f, 784f, 1047f };
            return GenerateChord(frequencies, 0.3f, 0.5f);
        }

        AudioClip GenerateLevelUpSound()
        {
            // Triumphant chord
            float[] frequencies = { 523f, 659f, 784f };
            return GenerateChord(frequencies, 0.4f, 0.6f);
        }

        AudioClip GenerateDamageSound()
        {
            // Low harsh sound
            return GenerateTone(200f, 0.2f, 0.4f, WaveType.Square);
        }

        #endregion

        #region Synthesis Core

        /// <summary>
        /// Generate a single tone at a specific frequency
        /// </summary>
        public AudioClip GenerateTone(float frequency, float duration, float volume, WaveType waveType)
        {
            int sampleCount = Mathf.FloorToInt(sampleRate * duration);
            AudioClip clip = AudioClip.Create($"Tone_{frequency}Hz", sampleCount, 1, sampleRate, false);

            float[] samples = new float[sampleCount];

            for (int i = 0; i < sampleCount; i++)
            {
                float t = i / (float)sampleRate;
                float phase = 2f * Mathf.PI * frequency * t;

                // Generate waveform
                float sample = 0f;
                switch (waveType)
                {
                    case WaveType.Sine:
                        sample = Mathf.Sin(phase);
                        break;
                    case WaveType.Square:
                        sample = Mathf.Sign(Mathf.Sin(phase));
                        break;
                    case WaveType.Triangle:
                        sample = 2f * Mathf.Abs(2f * (phase / (2f * Mathf.PI) - Mathf.Floor(phase / (2f * Mathf.PI) + 0.5f))) - 1f;
                        break;
                    case WaveType.Sawtooth:
                        sample = 2f * (phase / (2f * Mathf.PI) - Mathf.Floor(phase / (2f * Mathf.PI) + 0.5f));
                        break;
                    case WaveType.Noise:
                        sample = Random.Range(-1f, 1f);
                        break;
                }

                // Apply envelope (ADSR simplified - just fade in/out)
                float envelope = 1f;
                float attackTime = 0.01f;
                float releaseTime = 0.05f;

                if (t < attackTime)
                {
                    envelope = t / attackTime;
                }
                else if (t > duration - releaseTime)
                {
                    envelope = (duration - t) / releaseTime;
                }

                samples[i] = sample * volume * envelope * masterVolume;
            }

            clip.SetData(samples, 0);
            return clip;
        }

        /// <summary>
        /// Generate a chord by combining multiple frequencies
        /// </summary>
        public AudioClip GenerateChord(float[] frequencies, float duration, float volume)
        {
            int sampleCount = Mathf.FloorToInt(sampleRate * duration);
            AudioClip clip = AudioClip.Create($"Chord", sampleCount, 1, sampleRate, false);

            float[] samples = new float[sampleCount];

            for (int i = 0; i < sampleCount; i++)
            {
                float t = i / (float)sampleRate;
                float sample = 0f;

                // Sum all frequencies
                foreach (float freq in frequencies)
                {
                    sample += Mathf.Sin(2f * Mathf.PI * freq * t);
                }

                sample /= frequencies.Length; // Normalize

                // Envelope
                float envelope = 1f;
                float attackTime = 0.01f;
                float releaseTime = 0.05f;

                if (t < attackTime)
                    envelope = t / attackTime;
                else if (t > duration - releaseTime)
                    envelope = (duration - t) / releaseTime;

                samples[i] = sample * volume * envelope * masterVolume;
            }

            clip.SetData(samples, 0);
            return clip;
        }

        /// <summary>
        /// Generate a frequency sweep (rising or falling pitch)
        /// </summary>
        public AudioClip GenerateSweep(float startFreq, float endFreq, float duration, float volume)
        {
            int sampleCount = Mathf.FloorToInt(sampleRate * duration);
            AudioClip clip = AudioClip.Create($"Sweep_{startFreq}-{endFreq}Hz", sampleCount, 1, sampleRate, false);

            float[] samples = new float[sampleCount];

            for (int i = 0; i < sampleCount; i++)
            {
                float t = i / (float)sampleRate;
                float progress = t / duration;

                // Linear frequency sweep
                float frequency = Mathf.Lerp(startFreq, endFreq, progress);
                float phase = 2f * Mathf.PI * frequency * t;

                float sample = Mathf.Sin(phase);

                // Envelope
                float envelope = 1f - (progress * 0.5f); // Fade out as it sweeps

                samples[i] = sample * volume * envelope * masterVolume;
            }

            clip.SetData(samples, 0);
            return clip;
        }

        /// <summary>
        /// Generate noise burst (explosion, impact, etc.)
        /// </summary>
        public AudioClip GenerateNoiseBurst(float duration, float volume)
        {
            return GenerateTone(440f, duration, volume, WaveType.Noise);
        }

        #endregion

        #region Public API

        /// <summary>
        /// Get a synthesized sound by name
        /// </summary>
        public AudioClip GetSound(string soundName)
        {
            if (synthesizedClips.ContainsKey(soundName))
            {
                return synthesizedClips[soundName];
            }

            Debug.LogWarning($"[AudioSynthesizer] Sound '{soundName}' not found");
            return null;
        }

        /// <summary>
        /// Play a synthesized sound at a world position
        /// </summary>
        public void PlaySound(string soundName, Vector3 position)
        {
            AudioClip clip = GetSound(soundName);
            if (clip != null)
            {
                AudioSource.PlayClipAtPoint(clip, position, masterVolume);
            }
        }

        /// <summary>
        /// Play a synthesized sound (2D)
        /// </summary>
        public void PlaySound(string soundName)
        {
            AudioClip clip = GetSound(soundName);
            if (clip != null && Camera.main != null)
            {
                AudioSource.PlayClipAtPoint(clip, Camera.main.transform.position, masterVolume);
            }
        }

        /// <summary>
        /// Generate custom tone on-the-fly
        /// </summary>
        public AudioClip GenerateCustomTone(float frequency, float duration, WaveType waveType = WaveType.Sine)
        {
            return GenerateTone(frequency, duration, 0.5f, waveType);
        }

        /// <summary>
        /// Register a custom synthesized sound
        /// </summary>
        public void RegisterSound(string soundName, AudioClip clip)
        {
            synthesizedClips[soundName] = clip;
        }

        /// <summary>
        /// Remove a registered sound
        /// </summary>
        public void UnregisterSound(string soundName)
        {
            synthesizedClips.Remove(soundName);
        }

        /// <summary>
        /// Get all registered sound names
        /// </summary>
        public string[] GetSoundNames()
        {
            string[] names = new string[synthesizedClips.Count];
            synthesizedClips.Keys.CopyTo(names, 0);
            return names;
        }

        #endregion

        #if UNITY_EDITOR
        [ContextMenu("Test All Sounds")]
        void TestAllSounds()
        {
            if (Camera.main == null)
            {
                Debug.LogWarning("No camera found for testing sounds");
                return;
            }

            foreach (var kvp in synthesizedClips)
            {
                Debug.Log($"Playing: {kvp.Key}");
                AudioSource.PlayClipAtPoint(kvp.Value, Camera.main.transform.position);
            }
        }

        [ContextMenu("Test Collect Sound")]
        void TestCollect()
        {
            PlaySound("collect");
        }

        [ContextMenu("Test PowerUp Sound")]
        void TestPowerUp()
        {
            PlaySound("powerup");
        }

        [ContextMenu("Test Success Sound")]
        void TestSuccess()
        {
            PlaySound("success");
        }
        #endif
    }
}
