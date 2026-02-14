using UnityEngine;
using System.Collections;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Controls camera effects like screen shake and color flash.
    /// Stub implementation - extend with full camera system as needed.
    /// </summary>
    public class CameraController : MonoBehaviour
    {
        public static CameraController Instance { get; private set; }

        [Header("Shake Settings")]
        public float lightShakeIntensity = 0.1f;
        public float mediumShakeIntensity = 0.25f;
        public float heavyShakeIntensity = 0.5f;
        public float shakeDuration = 0.3f;

        private Vector3 originalPosition;
        private bool isShaking = false;

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

        void Start()
        {
            originalPosition = transform.localPosition;
        }

        /// <summary>
        /// Triggers a light camera shake.
        /// </summary>
        public void ShakeLight()
        {
            if (!isShaking)
            {
                StartCoroutine(DoShake(lightShakeIntensity, shakeDuration));
            }
        }

        /// <summary>
        /// Triggers a medium camera shake.
        /// </summary>
        public void ShakeMedium()
        {
            if (!isShaking)
            {
                StartCoroutine(DoShake(mediumShakeIntensity, shakeDuration));
            }
        }

        /// <summary>
        /// Triggers a heavy camera shake.
        /// </summary>
        public void ShakeHeavy()
        {
            if (!isShaking)
            {
                StartCoroutine(DoShake(heavyShakeIntensity, shakeDuration));
            }
        }

        /// <summary>
        /// Performs the camera shake coroutine.
        /// </summary>
        IEnumerator DoShake(float intensity, float duration)
        {
            isShaking = true;
            float elapsed = 0f;

            while (elapsed < duration)
            {
                float x = Random.Range(-1f, 1f) * intensity;
                float y = Random.Range(-1f, 1f) * intensity;

                transform.localPosition = originalPosition + new Vector3(x, y, 0f);

                elapsed += Time.deltaTime;
                yield return null;
            }

            transform.localPosition = originalPosition;
            isShaking = false;
        }

        /// <summary>
        /// Flashes a color overlay on screen.
        /// </summary>
        public void FlashColor(Color color, float duration)
        {
            Debug.Log($"CameraController: FlashColor({color}, {duration}s) - not yet implemented");
        }
    }
}
