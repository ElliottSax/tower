using UnityEngine;

namespace TreasureChase.Obstacles
{
    /// <summary>
    /// Base class for all obstacles in the endless runner.
    /// Handles collision detection and game over logic.
    /// </summary>
    [RequireComponent(typeof(Collider))]
    public class Obstacle : MonoBehaviour
    {
        [Header("Obstacle Settings")]
        [Tooltip("Damage dealt to player on collision")]
        public int damageAmount = 1;

        [Tooltip("Should obstacle be destroyed on hit?")]
        public bool destroyOnHit = true;

        [Tooltip("Points awarded for destroying this obstacle (with power-up)")]
        public int destroyPoints = 25;

        [Header("Visual Settings")]
        [Tooltip("Material to use when obstacle is about to be hit")]
        public Material warningMaterial;

        [Tooltip("Distance at which to show warning")]
        public float warningDistance = 10f;

        [Header("Audio")]
        [Tooltip("Sound to play on collision")]
        public string impactSoundName = "hit";

        [Header("Effects")]
        [Tooltip("Particle effect on collision")]
        public GameObject impactEffectPrefab;

        // Private fields
        private Renderer objectRenderer;
        private Material originalMaterial;
        private Transform player;
        private bool hasHit = false;

        #region Unity Lifecycle

        protected virtual void Start()
        {
            // Get renderer for material swapping
            objectRenderer = GetComponent<Renderer>();
            if (objectRenderer != null)
            {
                originalMaterial = objectRenderer.material;
            }

            // Find player
            var vehicleController = FindObjectOfType<VehicleController>();
            if (vehicleController != null)
            {
                player = vehicleController.transform;
            }

            // Ensure collider is trigger
            Collider col = GetComponent<Collider>();
            col.isTrigger = true;
        }

        protected virtual void Update()
        {
            // Show warning when player is close
            if (player != null && objectRenderer != null && warningMaterial != null)
            {
                float distance = transform.position.z - player.position.z;

                if (distance > 0 && distance < warningDistance)
                {
                    objectRenderer.material = warningMaterial;
                }
                else
                {
                    objectRenderer.material = originalMaterial;
                }
            }

            // Auto-destroy if far behind player
            if (player != null && transform.position.z < player.position.z - 20f)
            {
                Destroy(gameObject);
            }
        }

        #endregion

        #region Collision

        protected virtual void OnTriggerEnter(Collider other)
        {
            if (hasHit) return; // Prevent multiple hits

            if (other.CompareTag("Player"))
            {
                HandlePlayerCollision(other.gameObject);
            }
        }

        /// <summary>
        /// Handles collision with player
        /// </summary>
        protected virtual void HandlePlayerCollision(GameObject playerObject)
        {
            hasHit = true;

            var vehicleController = playerObject.GetComponent<VehicleController>();
            if (vehicleController == null) return;

            // Check if player has invincibility or shield
            if (vehicleController.HasInvincibility)
            {
                // Player is invincible, pass through
                HandleInvincibleHit(vehicleController);
                return;
            }

            if (vehicleController.HasShield)
            {
                // Shield absorbs hit
                HandleShieldHit(vehicleController);
                return;
            }

            // Normal collision - damage player
            HandleNormalHit(vehicleController);
        }

        /// <summary>
        /// Handles hit when player has invincibility
        /// </summary>
        protected virtual void HandleInvincibleHit(VehicleController vehicle)
        {
            Debug.Log("💫 Invincibility! Passed through obstacle");

            // Show effect
            SpawnImpactEffect();

            // Destroy obstacle
            if (destroyOnHit)
            {
                Destroy(gameObject, 0.1f);
            }
        }

        /// <summary>
        /// Handles hit when player has shield
        /// </summary>
        protected virtual void HandleShieldHit(VehicleController vehicle)
        {
            Debug.Log("🛡️ Shield absorbed hit!");

            // Consume shield
            vehicle.ConsumeShield();

            // Visual feedback (lighter than normal hit)
            if (CameraController.Instance != null)
            {
                CameraController.Instance.ShakeLight();
            }

            // Audio
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("shield_block");
            }

            // Effect
            SpawnImpactEffect();

            // Destroy obstacle
            if (destroyOnHit)
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// Handles normal collision (no power-ups)
        /// </summary>
        protected virtual void HandleNormalHit(VehicleController vehicle)
        {
            Debug.Log($"💥 Obstacle Hit! Damage: {damageAmount}");

            // Deal damage
            vehicle.TakeDamage(damageAmount);

            // Visual feedback
            ShowImpactFeedback();

            // Destroy obstacle
            if (destroyOnHit)
            {
                Destroy(gameObject);
            }
        }

        #endregion

        #region Visual/Audio Feedback

        /// <summary>
        /// Shows visual and audio feedback for impact
        /// </summary>
        protected virtual void ShowImpactFeedback()
        {
            // Camera shake (heavy)
            if (CameraController.Instance != null)
            {
                CameraController.Instance.ShakeHeavy();
            }

            // Hit freeze
            if (GameFeelManager.Instance != null)
            {
                GameFeelManager.Instance.HitFreeze(0.15f);
            }

            // Red flash
            if (CameraController.Instance != null)
            {
                CameraController.Instance.FlashColor(Color.red, 0.2f);
            }

            // Audio
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX(impactSoundName, volume: 1f, pitch: 0.7f);
            }

            // Particle effect
            SpawnImpactEffect();
        }

        /// <summary>
        /// Spawns particle effect at impact point
        /// </summary>
        protected virtual void SpawnImpactEffect()
        {
            if (impactEffectPrefab != null)
            {
                Instantiate(impactEffectPrefab, transform.position, Quaternion.identity);
            }
            else if (ParticleEffectManager.Instance != null)
            {
                ParticleEffectManager.Instance.PlayEffect("impact", transform.position);
            }
        }

        #endregion

        #region Debug

        #if UNITY_EDITOR
        void OnDrawGizmos()
        {
            // Draw warning radius
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(transform.position, warningDistance);

            // Draw collision bounds
            Collider col = GetComponent<Collider>();
            if (col != null)
            {
                Gizmos.color = Color.red;
                Gizmos.DrawWireCube(col.bounds.center, col.bounds.size);
            }
        }
        #endif

        #endregion
    }
}
