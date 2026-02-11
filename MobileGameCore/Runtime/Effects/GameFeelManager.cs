using UnityEngine;
using System.Collections;

namespace MobileGameCore.Effects
{
    /// <summary>
    /// Game Feel Manager - Adds "juice" and satisfying feedback to all player actions.
    /// Handles hit freeze, slow motion, camera shake, and coordinated audio-visual responses.
    /// Makes the game feel responsive and impactful.
    ///
    /// USAGE:
    /// GameFeelManager.Instance.Impact(1.0f); // Generic impact feedback
    /// GameFeelManager.Instance.OnItemCollected(itemObject, 10); // Collection feedback
    /// GameFeelManager.Instance.HitFreeze(0.1f); // Brief time stop
    /// </summary>
    public class GameFeelManager : MonoBehaviour
    {
        public static GameFeelManager Instance { get; private set; }

        [Header("Time Effects")]
        [SerializeField] private bool enableTimeEffects = true;
        [SerializeField] private float defaultHitFreezeTime = 0.05f;
        [SerializeField] private float slowMotionScale = 0.3f;

        [Header("Collection Feedback")]
        [SerializeField] private float itemCollectFreezeTime = 0.03f;
        [SerializeField] private float itemCollectShake = 0.15f;
        [SerializeField] private float itemScalePulse = 0.2f;

        [Header("Activation Feedback")]
        [SerializeField] private float activateFreezeTime = 0.08f;
        [SerializeField] private float activateShake = 0.4f;

        [Header("Success/Fail Feedback")]
        [SerializeField] private float successFreezeTime = 0.1f;
        [SerializeField] private float successShake = 0.6f;

        [Header("Collision Feedback")]
        [SerializeField] private float collisionShakeIntensity = 0.3f;
        [SerializeField] private float collisionMinVelocity = 5f;

        private bool isTimeFrozen = false;
        private float normalTimeScale = 1f;

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

            normalTimeScale = Time.timeScale;
        }

        #region Time Effects

        /// <summary>
        /// Freeze time for a brief moment (hit freeze effect)
        /// </summary>
        public void HitFreeze(float duration = -1f)
        {
            if (!enableTimeEffects || isTimeFrozen)
                return;

            if (duration < 0)
                duration = defaultHitFreezeTime;

            StartCoroutine(HitFreezeCoroutine(duration));
        }

        /// <summary>
        /// Enter slow motion
        /// </summary>
        public void StartSlowMotion(float scale = -1f)
        {
            if (!enableTimeEffects)
                return;

            if (scale < 0)
                scale = slowMotionScale;

            Time.timeScale = scale;
            Time.fixedDeltaTime = 0.02f * scale; // Maintain physics stability
        }

        /// <summary>
        /// Exit slow motion
        /// </summary>
        public void StopSlowMotion()
        {
            Time.timeScale = normalTimeScale;
            Time.fixedDeltaTime = 0.02f;
        }

        IEnumerator HitFreezeCoroutine(float duration)
        {
            isTimeFrozen = true;

            // Freeze time
            float originalTimeScale = Time.timeScale;
            Time.timeScale = 0f;

            // Wait in real time
            yield return new WaitForSecondsRealtime(duration);

            // Restore time
            Time.timeScale = originalTimeScale;
            isTimeFrozen = false;
        }

        IEnumerator TemporarySlowMotion(float scale, float duration)
        {
            StartSlowMotion(scale);
            yield return new WaitForSecondsRealtime(duration);
            StopSlowMotion();
        }

        #endregion

        #region Item Collection Feedback

        /// <summary>
        /// Play feedback for item/collectible pickup
        /// </summary>
        public void OnItemCollected(GameObject item, int value = 1, Color? particleColor = null)
        {
            // Hit freeze
            HitFreeze(itemCollectFreezeTime);

            // Camera shake (requires EnhancedCameraController)
            ShakeCamera(itemCollectShake);

            // Scale pulse on item
            if (item != null)
            {
                StartCoroutine(ScalePulse(item.transform, itemScalePulse, 0.2f));
            }

            // Particles (requires ProceduralParticles)
            SpawnParticles(
                ProceduralGeneration.ProceduralParticles.EffectType.Sparkle,
                item != null ? item.transform.position : Vector3.zero,
                particleColor ?? Color.yellow,
                1f
            );

            // Sound (requires AudioSynthesizer)
            PlaySoundEffect("collect", item != null ? item.transform.position : Vector3.zero);
        }

        /// <summary>
        /// Special feedback for high-value collectibles
        /// </summary>
        public void OnHighValueItemCollected(GameObject item, int value, Color? particleColor = null)
        {
            // More intense feedback for valuable items
            HitFreeze(itemCollectFreezeTime * 1.5f);
            ShakeCamera(itemCollectShake * 1.5f);

            if (item != null)
            {
                StartCoroutine(ScalePulse(item.transform, itemScalePulse * 1.5f, 0.3f));
            }

            SpawnParticles(
                ProceduralGeneration.ProceduralParticles.EffectType.Sparkle,
                item != null ? item.transform.position : Vector3.zero,
                particleColor ?? new Color(1f, 0.84f, 0f), // Gold
                1.5f
            );
        }

        #endregion

        #region Activation Feedback

        /// <summary>
        /// Play feedback for activating something (button, switch, gate, etc.)
        /// </summary>
        public void OnActivation(GameObject target, float intensity = 1f, Color? particleColor = null)
        {
            HitFreeze(activateFreezeTime * intensity);
            ShakeCamera(activateShake * intensity);

            if (target != null)
            {
                SpawnParticles(
                    ProceduralGeneration.ProceduralParticles.EffectType.RadialBurst,
                    target.transform.position,
                    particleColor ?? Color.cyan,
                    intensity
                );
            }
        }

        #endregion

        #region Success/Failure Feedback

        /// <summary>
        /// Feedback for achieving a goal (level complete, objective done, etc.)
        /// </summary>
        public void OnSuccess(Vector3 position, int amount = 1)
        {
            HitFreeze(successFreezeTime);
            ShakeCamera(successShake);

            SpawnParticles(
                ProceduralGeneration.ProceduralParticles.EffectType.RisingGlow,
                position,
                new Color(1f, 0.84f, 0f), // Gold
                2f
            );

            PlaySoundEffect("success", position);

            // Brief slow motion for big achievements
            if (amount > 100)
            {
                StartCoroutine(TemporarySlowMotion(0.5f, 0.3f));
            }
        }

        /// <summary>
        /// Feedback for failure (game over, objective failed, etc.)
        /// </summary>
        public void OnFailure()
        {
            HitFreeze(0.08f);
            ShakeCamera(0.8f);
            PlaySoundEffect("fail", Vector3.zero);
        }

        #endregion

        #region Collision Feedback

        /// <summary>
        /// Play feedback for physics collisions
        /// </summary>
        public void OnCollision(Collision collision)
        {
            float impactVelocity = collision.relativeVelocity.magnitude;

            if (impactVelocity < collisionMinVelocity)
                return;

            // Scale feedback with impact velocity
            float intensityRatio = Mathf.Clamp01(impactVelocity / 20f);
            ShakeCamera(collisionShakeIntensity * intensityRatio);

            // Could add particle sparks at contact point
            if (collision.contacts.Length > 0)
            {
                Vector3 contactPoint = collision.contacts[0].point;
                SpawnParticles(
                    ProceduralGeneration.ProceduralParticles.EffectType.Explosion,
                    contactPoint,
                    Color.white,
                    intensityRatio
                );
            }
        }

        #endregion

        #region Power-up Feedback

        /// <summary>
        /// Feedback for power-up collection
        /// </summary>
        public void OnPowerUpCollected(string powerUpType, Vector3 position)
        {
            HitFreeze(0.05f);
            ShakeCamera(0.3f);
            PlaySoundEffect("powerup", position);

            SpawnParticles(
                ProceduralGeneration.ProceduralParticles.EffectType.Aura,
                position,
                GetPowerUpColor(powerUpType),
                1.5f
            );
        }

        /// <summary>
        /// Feedback for power-up activation
        /// </summary>
        public void OnPowerUpActivated(string powerUpType)
        {
            // Different effects per power-up type
            switch (powerUpType.ToLower())
            {
                case "speed":
                case "speedboost":
                    StartCoroutine(TemporarySlowMotion(0.7f, 0.5f));
                    break;

                case "shield":
                    // Shield activation effect
                    ShakeCamera(0.2f);
                    break;

                case "magnet":
                    // Magnetic pulse
                    ShakeCamera(0.25f);
                    break;

                default:
                    // Generic activation
                    HitFreeze(0.04f);
                    break;
            }
        }

        Color GetPowerUpColor(string powerUpType)
        {
            switch (powerUpType.ToLower())
            {
                case "speed": return new Color(0.2f, 0.8f, 1f); // Cyan
                case "shield": return new Color(0.2f, 1f, 0.5f); // Green
                case "magnet": return new Color(1f, 0.5f, 0.2f); // Orange
                case "damage": return new Color(1f, 0.2f, 0.2f); // Red
                default: return Color.yellow;
            }
        }

        #endregion

        #region Checkpoint Feedback

        /// <summary>
        /// Feedback for checkpoint reached
        /// </summary>
        public void OnCheckpointReached(GameObject checkpoint)
        {
            HitFreeze(0.04f);
            ShakeCamera(0.2f);
            PlaySoundEffect("checkpoint", checkpoint != null ? checkpoint.transform.position : Vector3.zero);

            // Green confirmation particles
            if (checkpoint != null)
            {
                SpawnParticles(
                    ProceduralGeneration.ProceduralParticles.EffectType.Aura,
                    checkpoint.transform.position,
                    new Color(0.2f, 1f, 0.5f),
                    1.5f
                );
            }
        }

        #endregion

        #region Visual Effect Helpers

        IEnumerator ScalePulse(Transform target, float intensity, float duration)
        {
            if (target == null) yield break;

            Vector3 originalScale = target.localScale;
            Vector3 targetScale = originalScale * (1f + intensity);

            float elapsed = 0f;
            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / duration;

                // Ping-pong effect
                float scale = Mathf.Sin(t * Mathf.PI);
                target.localScale = Vector3.Lerp(originalScale, targetScale, scale);

                yield return null;
            }

            target.localScale = originalScale;
        }

        #endregion

        #region Integration Helpers

        /// <summary>
        /// Shake camera if EnhancedCameraController exists
        /// </summary>
        void ShakeCamera(float intensity)
        {
            // Using reflection to avoid hard dependency
            var cameraType = System.Type.GetType("MobileGameCore.Camera.EnhancedCameraController");
            if (cameraType != null)
            {
                var instanceProp = cameraType.GetProperty("Instance");
                if (instanceProp != null)
                {
                    var instance = instanceProp.GetValue(null);
                    if (instance != null)
                    {
                        var addShakeMethod = cameraType.GetMethod("AddShake");
                        addShakeMethod?.Invoke(instance, new object[] { intensity });
                    }
                }
            }
        }

        /// <summary>
        /// Spawn particles if ProceduralParticles exists
        /// </summary>
        void SpawnParticles(ProceduralGeneration.ProceduralParticles.EffectType type, Vector3 position, Color color, float scale)
        {
            try
            {
                ProceduralGeneration.ProceduralParticles.CreateEffect(type, position, color, scale);
            }
            catch
            {
                // ProceduralParticles not available, skip
            }
        }

        /// <summary>
        /// Play sound effect if AudioSynthesizer exists
        /// </summary>
        void PlaySoundEffect(string soundName, Vector3 position)
        {
            var synthType = System.Type.GetType("MobileGameCore.ProceduralGeneration.AudioSynthesizer");
            if (synthType != null)
            {
                var instanceProp = synthType.GetProperty("Instance");
                if (instanceProp != null)
                {
                    var instance = instanceProp.GetValue(null);
                    if (instance != null)
                    {
                        var playSoundMethod = synthType.GetMethod("PlaySound", new[] { typeof(string), typeof(Vector3) });
                        playSoundMethod?.Invoke(instance, new object[] { soundName, position });
                    }
                }
            }
        }

        #endregion

        #region Public Utilities

        /// <summary>
        /// Generic impact feedback (intensity 0-1+)
        /// </summary>
        public void Impact(float intensity)
        {
            HitFreeze(0.05f * intensity);
            ShakeCamera(0.3f * intensity);
        }

        /// <summary>
        /// Success feedback for UI, achievements, etc.
        /// </summary>
        public void SuccessFeedback()
        {
            HitFreeze(0.03f);
            ShakeCamera(0.15f);
            PlaySoundEffect("button", Vector3.zero);
        }

        /// <summary>
        /// Failure feedback for UI
        /// </summary>
        public void FailureFeedback()
        {
            HitFreeze(0.08f);
            ShakeCamera(0.6f);
        }

        /// <summary>
        /// Button click feedback
        /// </summary>
        public void ButtonClick()
        {
            HitFreeze(0.02f);
            PlaySoundEffect("button", Vector3.zero);
        }

        #endregion
    }
}
