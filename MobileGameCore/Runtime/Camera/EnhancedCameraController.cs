using UnityEngine;
using System.Collections;

namespace MobileGameCore.Camera
{
    /// <summary>
    /// Enhanced camera controller with smooth follow, screen shake, zoom effects, and cinematic features.
    /// Provides professional game feel with dynamic camera responses to gameplay events.
    ///
    /// FEATURES:
    /// - Smooth follow with customizable speed
    /// - Screen shake (light, medium, heavy, explosion presets)
    /// - Dynamic zoom based on target velocity
    /// - Look-ahead system for movement direction
    /// - Cinematic focus on specific positions
    /// - Bounds constraints
    ///
    /// USAGE:
    /// EnhancedCameraController.Instance.SetTarget(player.transform);
    /// EnhancedCameraController.Instance.ShakeMedium();
    /// EnhancedCameraController.Instance.AddShake(0.5f);
    /// </summary>
    public class EnhancedCameraController : MonoBehaviour
    {
        public static EnhancedCameraController Instance { get; private set; }

        [Header("Target")]
        [SerializeField] private Transform target;
        [SerializeField] private Vector3 offset = new Vector3(0, 8, -12);
        [SerializeField] private bool lookAtTarget = true;

        [Header("Follow Settings")]
        [SerializeField] private float followSpeed = 5f;
        [SerializeField] private float rotationSpeed = 3f;
        [SerializeField] private bool smoothFollow = true;

        [Header("Bounds")]
        [SerializeField] private bool useBounds = true;
        [SerializeField] private Vector3 minBounds = new Vector3(-50, 0, 0);
        [SerializeField] private Vector3 maxBounds = new Vector3(50, 50, 200);

        [Header("Screen Shake")]
        [SerializeField] private float shakeDecay = 5f;
        [SerializeField] private float maxShakeIntensity = 2f;

        [Header("Dynamic Zoom")]
        [SerializeField] private bool dynamicZoom = true;
        [SerializeField] private float minZoom = 8f;
        [SerializeField] private float maxZoom = 15f;
        [SerializeField] private float zoomSpeed = 2f;

        [Header("Look Ahead")]
        [SerializeField] private bool lookAhead = true;
        [SerializeField] private float lookAheadDistance = 5f;
        [SerializeField] private float lookAheadSpeed = 2f;

        private UnityEngine.Camera cam;
        private Vector3 currentVelocity;
        private Vector3 shakeOffset;
        private float shakeIntensity;
        private float targetZoom;
        private Vector3 lookAheadOffset;

        // Event tracking
        private bool isShaking = false;
        private Coroutine shakeCoroutine;

        // Events
        public System.Action OnShakeStarted;
        public System.Action OnShakeEnded;

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            cam = GetComponent<UnityEngine.Camera>();
            if (cam == null)
            {
                cam = gameObject.AddComponent<UnityEngine.Camera>();
            }

            targetZoom = offset.y;
        }

        void Start()
        {
            // Auto-find target if not set
            if (target == null)
            {
                GameObject player = GameObject.FindGameObjectWithTag("Player");
                if (player != null)
                {
                    target = player.transform;
                }
            }
        }

        void LateUpdate()
        {
            if (target == null)
                return;

            UpdateLookAhead();
            UpdateZoom();
            UpdatePosition();
            UpdateRotation();
            UpdateShake();
        }

        void UpdateLookAhead()
        {
            if (!lookAhead || target == null)
            {
                lookAheadOffset = Vector3.zero;
                return;
            }

            // Get target velocity (if it has a Rigidbody)
            Rigidbody rb = target.GetComponent<Rigidbody>();
            if (rb != null)
            {
                Vector3 targetDirection = rb.velocity.normalized;
                Vector3 targetLookAhead = targetDirection * lookAheadDistance;
                lookAheadOffset = Vector3.Lerp(lookAheadOffset, targetLookAhead, lookAheadSpeed * Time.deltaTime);
            }
        }

        void UpdateZoom()
        {
            if (!dynamicZoom || target == null)
                return;

            // Adjust zoom based on target speed
            Rigidbody rb = target.GetComponent<Rigidbody>();
            if (rb != null)
            {
                float speed = rb.velocity.magnitude;
                float speedRatio = Mathf.Clamp01(speed / 30f); // Normalize to 0-1
                targetZoom = Mathf.Lerp(minZoom, maxZoom, speedRatio);
            }

            // Smooth zoom
            offset.y = Mathf.Lerp(offset.y, targetZoom, zoomSpeed * Time.deltaTime);
        }

        void UpdatePosition()
        {
            if (target == null)
                return;

            // Calculate desired position
            Vector3 targetPosition = target.position + offset + lookAheadOffset;

            // Apply bounds
            if (useBounds)
            {
                targetPosition.x = Mathf.Clamp(targetPosition.x, minBounds.x, maxBounds.x);
                targetPosition.y = Mathf.Clamp(targetPosition.y, minBounds.y, maxBounds.y);
                targetPosition.z = Mathf.Clamp(targetPosition.z, minBounds.z, maxBounds.z);
            }

            // Smooth follow or instant
            if (smoothFollow)
            {
                transform.position = Vector3.SmoothDamp(transform.position, targetPosition, ref currentVelocity, 1f / followSpeed);
            }
            else
            {
                transform.position = targetPosition;
            }

            // Apply shake offset
            transform.position += shakeOffset;
        }

        void UpdateRotation()
        {
            if (!lookAtTarget || target == null)
                return;

            Vector3 lookPosition = target.position + lookAheadOffset;
            Quaternion targetRotation = Quaternion.LookRotation(lookPosition - transform.position);

            if (smoothFollow)
            {
                transform.rotation = Quaternion.Slerp(transform.rotation, targetRotation, rotationSpeed * Time.deltaTime);
            }
            else
            {
                transform.rotation = targetRotation;
            }
        }

        void UpdateShake()
        {
            if (shakeIntensity > 0)
            {
                // Generate random shake offset
                shakeOffset = Random.insideUnitSphere * shakeIntensity;

                // Decay shake over time
                shakeIntensity = Mathf.Max(0, shakeIntensity - shakeDecay * Time.deltaTime);

                if (shakeIntensity <= 0.01f)
                {
                    shakeIntensity = 0;
                    shakeOffset = Vector3.zero;

                    if (isShaking)
                    {
                        isShaking = false;
                        OnShakeEnded?.Invoke();
                    }
                }
            }
        }

        #region Public API

        /// <summary>
        /// Set the camera target
        /// </summary>
        public void SetTarget(Transform newTarget)
        {
            target = newTarget;
        }

        /// <summary>
        /// Get current camera target
        /// </summary>
        public Transform GetTarget()
        {
            return target;
        }

        /// <summary>
        /// Trigger screen shake with specified intensity and duration
        /// </summary>
        public void Shake(float intensity, float duration)
        {
            if (shakeCoroutine != null)
            {
                StopCoroutine(shakeCoroutine);
            }

            shakeCoroutine = StartCoroutine(ShakeCoroutine(intensity, duration));
        }

        /// <summary>
        /// Add instant shake intensity (stacks with existing shake)
        /// </summary>
        public void AddShake(float intensity)
        {
            if (!isShaking)
            {
                isShaking = true;
                OnShakeStarted?.Invoke();
            }

            shakeIntensity = Mathf.Min(shakeIntensity + intensity, maxShakeIntensity);
        }

        /// <summary>
        /// Quick shake presets
        /// </summary>
        public void ShakeLight() => Shake(0.2f, 0.2f);
        public void ShakeMedium() => Shake(0.5f, 0.3f);
        public void ShakeHeavy() => Shake(1.0f, 0.5f);
        public void ShakeExplosion() => Shake(1.5f, 0.7f);

        /// <summary>
        /// Stop all shaking immediately
        /// </summary>
        public void StopShake()
        {
            if (shakeCoroutine != null)
            {
                StopCoroutine(shakeCoroutine);
            }
            shakeIntensity = 0;
            shakeOffset = Vector3.zero;
            isShaking = false;
        }

        /// <summary>
        /// Smooth zoom to specific distance
        /// </summary>
        public void ZoomTo(float distance, float speed = 2f)
        {
            StartCoroutine(ZoomCoroutine(distance, speed));
        }

        /// <summary>
        /// Instantly set zoom distance
        /// </summary>
        public void SetZoom(float distance)
        {
            offset.y = distance;
            targetZoom = distance;
        }

        /// <summary>
        /// Get current zoom distance
        /// </summary>
        public float GetZoom()
        {
            return offset.y;
        }

        /// <summary>
        /// Enable/disable dynamic zoom
        /// </summary>
        public void SetDynamicZoom(bool enabled)
        {
            dynamicZoom = enabled;
        }

        /// <summary>
        /// Enable/disable look ahead
        /// </summary>
        public void SetLookAhead(bool enabled)
        {
            lookAhead = enabled;
        }

        /// <summary>
        /// Enable/disable smooth follow
        /// </summary>
        public void SetSmoothFollow(bool enabled)
        {
            smoothFollow = enabled;
        }

        /// <summary>
        /// Set camera bounds
        /// </summary>
        public void SetBounds(Vector3 min, Vector3 max)
        {
            minBounds = min;
            maxBounds = max;
            useBounds = true;
        }

        /// <summary>
        /// Disable camera bounds
        /// </summary>
        public void DisableBounds()
        {
            useBounds = false;
        }

        /// <summary>
        /// Cinematic focus on position
        /// </summary>
        public void FocusOn(Vector3 position, float duration = 2f)
        {
            StartCoroutine(FocusCoroutine(position, duration));
        }

        /// <summary>
        /// Check if camera is currently shaking
        /// </summary>
        public bool IsShaking()
        {
            return isShaking;
        }

        #endregion

        #region Coroutines

        IEnumerator ShakeCoroutine(float intensity, float duration)
        {
            if (!isShaking)
            {
                isShaking = true;
                OnShakeStarted?.Invoke();
            }

            shakeIntensity = Mathf.Min(intensity, maxShakeIntensity);

            float elapsed = 0f;
            float startIntensity = shakeIntensity;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                shakeIntensity = Mathf.Lerp(startIntensity, 0, elapsed / duration);
                yield return null;
            }

            shakeIntensity = 0;
            shakeOffset = Vector3.zero;
            isShaking = false;
            OnShakeEnded?.Invoke();
        }

        IEnumerator ZoomCoroutine(float targetDistance, float speed)
        {
            float startDistance = offset.y;
            float elapsed = 0f;
            float duration = Mathf.Abs(targetDistance - startDistance) / speed;

            while (elapsed < duration)
            {
                elapsed += Time.deltaTime;
                float t = elapsed / duration;
                offset.y = Mathf.Lerp(startDistance, targetDistance, t);
                yield return null;
            }

            offset.y = targetDistance;
            targetZoom = targetDistance;
        }

        IEnumerator FocusCoroutine(Vector3 focusPosition, float duration)
        {
            Transform originalTarget = target;
            bool originalLookAt = lookAtTarget;

            // Create temporary target
            GameObject tempTarget = new GameObject("CameraFocusTarget");
            tempTarget.transform.position = focusPosition;
            target = tempTarget.transform;
            lookAtTarget = true;

            yield return new WaitForSeconds(duration);

            // Restore original target
            target = originalTarget;
            lookAtTarget = originalLookAt;
            Destroy(tempTarget);
        }

        #endregion

        #region Gizmos

        void OnDrawGizmosSelected()
        {
            if (useBounds)
            {
                // Draw bounds box
                Gizmos.color = Color.yellow;
                Vector3 center = (minBounds + maxBounds) * 0.5f;
                Vector3 size = maxBounds - minBounds;
                Gizmos.DrawWireCube(center, size);
            }

            if (target != null)
            {
                // Draw target connection
                Gizmos.color = Color.cyan;
                Gizmos.DrawLine(transform.position, target.position);

                // Draw look ahead
                if (lookAhead)
                {
                    Gizmos.color = Color.green;
                    Gizmos.DrawWireSphere(target.position + lookAheadOffset, 1f);
                }
            }
        }

        #endregion
    }
}
