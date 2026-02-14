using UnityEngine;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Manages particle effects for abilities, line clears, etc.
    /// Stub implementation - extend with full particle system as needed.
    /// </summary>
    public class ParticleEffectManager : MonoBehaviour
    {
        public static ParticleEffectManager Instance { get; private set; }

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// Plays a particle effect by name at a position.
        /// </summary>
        public void PlayEffect(string effectName, Vector3 position)
        {
            Debug.Log($"ParticleEffectManager: PlayEffect({effectName}) at {position} - not yet implemented");
        }

        /// <summary>
        /// Plays a particle effect by name at a position with a color.
        /// </summary>
        public void PlayEffect(string effectName, Vector3 position, Color color)
        {
            Debug.Log($"ParticleEffectManager: PlayEffect({effectName}) at {position} color {color} - not yet implemented");
        }

        /// <summary>
        /// Stops all active particle effects.
        /// </summary>
        public void StopAllEffects()
        {
            Debug.Log("ParticleEffectManager: StopAllEffects - not yet implemented");
        }
    }
}
