using UnityEngine;
using System.Collections.Generic;

namespace MobileGameCore.ProceduralGeneration
{
    /// <summary>
    /// Generates procedural particle effects without requiring texture assets.
    /// Creates various game effects: sparkles, explosions, trails, auras, and more.
    /// Zero asset dependencies - everything rendered at runtime!
    ///
    /// USAGE:
    /// 1. Add component to GameObject
    /// 2. Configure effect type and settings
    /// 3. Call Play() to start
    ///
    /// ONE-SHOT EFFECTS:
    /// ProceduralParticles.CreateEffect(EffectType.Sparkle, position, Color.yellow);
    /// </summary>
    public class ProceduralParticles : MonoBehaviour
    {
        [Header("Effect Type")]
        [SerializeField] private EffectType effectType = EffectType.Sparkle;

        [Header("Particle Settings")]
        [SerializeField] private int maxParticles = 100;
        [SerializeField] private float particleLifetime = 2f;
        [SerializeField] private float emissionRate = 20f;

        [Header("Visual Settings")]
        [SerializeField] private Color startColor = Color.yellow;
        [SerializeField] private Color endColor = new Color(1f, 1f, 1f, 0f);
        [SerializeField] private float startSize = 0.2f;
        [SerializeField] private float endSize = 0.05f;

        [Header("Physics")]
        [SerializeField] private Vector3 gravity = new Vector3(0, -2f, 0);
        [SerializeField] private float initialSpeed = 3f;

        [Header("Auto Settings")]
        [SerializeField] private bool playOnStart = false;
        [SerializeField] private bool loop = false;
        [SerializeField] private float duration = 2f;

        private List<Particle> particles = new List<Particle>();
        private float emissionTimer = 0f;
        private float effectTimer = 0f;
        private bool isPlaying = false;
        private Mesh particleMesh;
        private Material particleMaterial;

        public enum EffectType
        {
            Sparkle,        // Collection effects, star bursts
            Explosion,      // Impact effects, burst
            Trail,          // Movement trail, dash effect
            Aura,           // Power-up glow, buff effect
            Portal,         // Teleporter, swirl effect
            RisingGlow,     // Collection zone, pickup area
            RadialBurst,    // Area effect, power-up activation
            Smoke,          // Environmental effect
            Fire            // Environmental effect
        }

        private class Particle
        {
            public Vector3 position;
            public Vector3 velocity;
            public float age;
            public float lifetime;
            public float size;
            public Color color;
            public float rotation;
            public float rotationSpeed;
            public bool active;
        }

        void Awake()
        {
            SetupParticleSystem();
        }

        void Start()
        {
            if (playOnStart)
            {
                Play();
            }
        }

        void SetupParticleSystem()
        {
            // Create simple quad mesh for particles
            particleMesh = CreateParticleMesh();

            // Create particle material
            particleMaterial = new Material(Shader.Find("Particles/Standard Unlit"));
            particleMaterial.SetFloat("_Mode", 3); // Transparent
            particleMaterial.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
            particleMaterial.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.One); // Additive
            particleMaterial.SetInt("_ZWrite", 0);
            particleMaterial.EnableKeyword("_ALPHABLEND_ON");
            particleMaterial.renderQueue = 3000;
        }

        Mesh CreateParticleMesh()
        {
            Mesh mesh = new Mesh();
            mesh.name = "ParticleQuad";

            // Simple quad
            mesh.vertices = new Vector3[]
            {
                new Vector3(-0.5f, -0.5f, 0),
                new Vector3(0.5f, -0.5f, 0),
                new Vector3(0.5f, 0.5f, 0),
                new Vector3(-0.5f, 0.5f, 0)
            };

            mesh.triangles = new int[] { 0, 2, 1, 0, 3, 2 };
            mesh.uv = new Vector2[]
            {
                new Vector2(0, 0),
                new Vector2(1, 0),
                new Vector2(1, 1),
                new Vector2(0, 1)
            };

            mesh.RecalculateNormals();
            return mesh;
        }

        void Update()
        {
            if (!isPlaying)
                return;

            effectTimer += Time.deltaTime;

            // Stop if not looping and duration exceeded
            if (!loop && effectTimer >= duration)
            {
                isPlaying = false;
                return;
            }

            // Emit particles
            EmitParticles();

            // Update existing particles
            UpdateParticles();
        }

        void EmitParticles()
        {
            emissionTimer += Time.deltaTime;
            float emissionInterval = 1f / emissionRate;

            while (emissionTimer >= emissionInterval && particles.Count < maxParticles)
            {
                EmitParticle();
                emissionTimer -= emissionInterval;
            }
        }

        void EmitParticle()
        {
            Particle particle = GetOrCreateParticle();
            if (particle == null)
                return;

            // Reset particle properties
            particle.position = transform.position;
            particle.age = 0f;
            particle.lifetime = particleLifetime + Random.Range(-0.2f, 0.2f);
            particle.size = startSize;
            particle.color = startColor;
            particle.rotation = Random.Range(0f, 360f);
            particle.rotationSpeed = Random.Range(-180f, 180f);
            particle.active = true;

            // Set velocity based on effect type
            particle.velocity = CalculateInitialVelocity();
        }

        Vector3 CalculateInitialVelocity()
        {
            switch (effectType)
            {
                case EffectType.Sparkle:
                    // Burst outward in all directions
                    return Random.onUnitSphere * initialSpeed;

                case EffectType.Explosion:
                    // Strong outward burst with upward bias
                    Vector3 dir = Random.onUnitSphere;
                    dir.y = Mathf.Abs(dir.y); // Bias upward
                    return dir * initialSpeed * 1.5f;

                case EffectType.Trail:
                    // Emit backwards with spread
                    Vector3 back = -transform.forward;
                    Vector3 randomOffset = Random.insideUnitSphere * 0.5f;
                    return (back + randomOffset) * initialSpeed * 0.5f;

                case EffectType.Aura:
                    // Gentle upward drift
                    return new Vector3(
                        Random.Range(-0.5f, 0.5f),
                        Random.Range(1f, 2f),
                        Random.Range(-0.5f, 0.5f)
                    );

                case EffectType.Portal:
                    // Swirl around center
                    float angle = Random.Range(0f, 360f) * Mathf.Deg2Rad;
                    float radius = Random.Range(0.5f, 2f);
                    return new Vector3(
                        Mathf.Cos(angle) * radius,
                        Random.Range(-1f, 1f),
                        Mathf.Sin(angle) * radius
                    );

                case EffectType.RisingGlow:
                    // Rise upward from area
                    return new Vector3(
                        Random.Range(-0.3f, 0.3f),
                        Random.Range(2f, 4f),
                        Random.Range(-0.3f, 0.3f)
                    );

                case EffectType.RadialBurst:
                    // Radial burst on horizontal plane
                    Vector3 radial = Random.onUnitSphere;
                    radial.y = 0; // Keep on horizontal plane
                    return radial.normalized * initialSpeed;

                case EffectType.Smoke:
                    // Gentle upward rise with drift
                    return new Vector3(
                        Random.Range(-0.3f, 0.3f),
                        Random.Range(0.5f, 1.5f),
                        Random.Range(-0.3f, 0.3f)
                    );

                case EffectType.Fire:
                    // Upward with flicker
                    return new Vector3(
                        Random.Range(-0.5f, 0.5f),
                        Random.Range(2f, 3f),
                        Random.Range(-0.5f, 0.5f)
                    );

                default:
                    return Random.onUnitSphere * initialSpeed;
            }
        }

        Particle GetOrCreateParticle()
        {
            // Find inactive particle
            foreach (var p in particles)
            {
                if (!p.active)
                    return p;
            }

            // Create new particle if under limit
            if (particles.Count < maxParticles)
            {
                Particle newParticle = new Particle();
                particles.Add(newParticle);
                return newParticle;
            }

            return null;
        }

        void UpdateParticles()
        {
            foreach (var particle in particles)
            {
                if (!particle.active)
                    continue;

                particle.age += Time.deltaTime;

                // Deactivate if lifetime exceeded
                if (particle.age >= particle.lifetime)
                {
                    particle.active = false;
                    continue;
                }

                // Update position
                particle.velocity += gravity * Time.deltaTime;
                particle.position += particle.velocity * Time.deltaTime;

                // Update rotation
                particle.rotation += particle.rotationSpeed * Time.deltaTime;

                // Update size and color (interpolate based on age)
                float t = particle.age / particle.lifetime;
                particle.size = Mathf.Lerp(startSize, endSize, t);
                particle.color = Color.Lerp(startColor, endColor, t);
            }
        }

        void LateUpdate()
        {
            // Render all active particles
            RenderParticles();
        }

        void RenderParticles()
        {
            if (particleMesh == null || particleMaterial == null)
                return;

            // Check for main camera
            if (Camera.main == null)
            {
                Debug.LogWarning("[ProceduralParticles] No main camera found, cannot render particles");
                return;
            }

            Vector3 cameraForward = Camera.main.transform.forward;

            foreach (var particle in particles)
            {
                if (!particle.active)
                    continue;

                // Create transform matrix for particle (billboard)
                Matrix4x4 matrix = Matrix4x4.TRS(
                    particle.position,
                    Quaternion.Euler(0, 0, particle.rotation) * Quaternion.LookRotation(cameraForward),
                    Vector3.one * particle.size
                );

                // Set color
                particleMaterial.color = particle.color;

                // Draw particle
                Graphics.DrawMesh(particleMesh, matrix, particleMaterial, gameObject.layer);
            }
        }

        #region Public API

        /// <summary>
        /// Start playing the particle effect
        /// </summary>
        public void Play()
        {
            isPlaying = true;
            effectTimer = 0f;
            emissionTimer = 0f;
        }

        /// <summary>
        /// Stop playing and clear particles
        /// </summary>
        public void Stop()
        {
            isPlaying = false;
            ClearParticles();
        }

        /// <summary>
        /// Clear all active particles
        /// </summary>
        public void ClearParticles()
        {
            foreach (var particle in particles)
            {
                particle.active = false;
            }
        }

        /// <summary>
        /// Create a one-shot particle effect at a position
        /// </summary>
        public static GameObject CreateEffect(EffectType type, Vector3 position, Color color, float scale = 1f)
        {
            GameObject effectObj = new GameObject($"ParticleEffect_{type}");
            effectObj.transform.position = position;

            ProceduralParticles effect = effectObj.AddComponent<ProceduralParticles>();
            effect.effectType = type;
            effect.startColor = color;
            effect.endColor = new Color(color.r, color.g, color.b, 0f);
            effect.startSize = 0.2f * scale;
            effect.duration = 1.5f;
            effect.loop = false;
            effect.playOnStart = true;

            // Auto-destroy after duration
            Destroy(effectObj, 3f);

            return effectObj;
        }

        /// <summary>
        /// Configure effect preset with predefined settings
        /// </summary>
        public void SetEffectPreset(EffectType type)
        {
            effectType = type;

            switch (type)
            {
                case EffectType.Sparkle:
                    startColor = Color.yellow;
                    endColor = new Color(1f, 1f, 1f, 0f);
                    startSize = 0.15f;
                    endSize = 0.05f;
                    emissionRate = 50f;
                    particleLifetime = 0.8f;
                    initialSpeed = 2f;
                    gravity = new Vector3(0, -1f, 0);
                    break;

                case EffectType.Explosion:
                    startColor = new Color(1f, 0.5f, 0f);
                    endColor = new Color(1f, 0f, 0f, 0f);
                    startSize = 0.3f;
                    endSize = 0.1f;
                    emissionRate = 100f;
                    particleLifetime = 1f;
                    initialSpeed = 5f;
                    gravity = new Vector3(0, -2f, 0);
                    break;

                case EffectType.Trail:
                    startColor = new Color(0.5f, 0.5f, 1f, 0.5f);
                    endColor = new Color(0.2f, 0.2f, 0.5f, 0f);
                    startSize = 0.2f;
                    endSize = 0.05f;
                    emissionRate = 30f;
                    particleLifetime = 1.5f;
                    initialSpeed = 1f;
                    gravity = new Vector3(0, -1f, 0);
                    break;

                case EffectType.Aura:
                    startColor = new Color(0.2f, 1f, 0.8f, 0.3f);
                    endColor = new Color(0.2f, 1f, 0.8f, 0f);
                    startSize = 0.25f;
                    endSize = 0.1f;
                    emissionRate = 20f;
                    particleLifetime = 2f;
                    initialSpeed = 1.5f;
                    gravity = Vector3.zero;
                    break;

                case EffectType.Portal:
                    startColor = new Color(0.5f, 0.2f, 1f, 0.6f);
                    endColor = new Color(0.8f, 0.4f, 1f, 0f);
                    startSize = 0.2f;
                    endSize = 0.05f;
                    emissionRate = 40f;
                    particleLifetime = 2f;
                    initialSpeed = 2f;
                    gravity = Vector3.zero;
                    break;

                case EffectType.RisingGlow:
                    startColor = new Color(1f, 0.84f, 0f, 0.8f);
                    endColor = new Color(1f, 1f, 0.5f, 0f);
                    startSize = 0.15f;
                    endSize = 0.05f;
                    emissionRate = 60f;
                    particleLifetime = 1.5f;
                    initialSpeed = 3f;
                    gravity = Vector3.zero;
                    break;

                case EffectType.RadialBurst:
                    startColor = new Color(0.2f, 0.8f, 1f, 0.7f);
                    endColor = new Color(0.5f, 1f, 1f, 0f);
                    startSize = 0.2f;
                    endSize = 0.1f;
                    emissionRate = 80f;
                    particleLifetime = 1f;
                    initialSpeed = 4f;
                    gravity = Vector3.zero;
                    break;

                case EffectType.Smoke:
                    startColor = new Color(0.3f, 0.3f, 0.3f, 0.6f);
                    endColor = new Color(0.5f, 0.5f, 0.5f, 0f);
                    startSize = 0.3f;
                    endSize = 0.6f;
                    emissionRate = 15f;
                    particleLifetime = 3f;
                    initialSpeed = 1f;
                    gravity = new Vector3(0, 0.5f, 0); // Positive gravity = rise
                    break;

                case EffectType.Fire:
                    startColor = new Color(1f, 0.3f, 0f, 0.8f);
                    endColor = new Color(1f, 0.8f, 0f, 0f);
                    startSize = 0.25f;
                    endSize = 0.15f;
                    emissionRate = 40f;
                    particleLifetime = 1.5f;
                    initialSpeed = 2f;
                    gravity = new Vector3(0, 1f, 0); // Rise up
                    break;
            }
        }

        #endregion

        #if UNITY_EDITOR
        [ContextMenu("Play Effect")]
        void TestPlay()
        {
            Play();
        }

        [ContextMenu("Stop Effect")]
        void TestStop()
        {
            Stop();
        }

        [ContextMenu("Cycle Effect Type")]
        void CycleEffectType()
        {
            effectType = (EffectType)(((int)effectType + 1) % System.Enum.GetValues(typeof(EffectType)).Length);
            SetEffectPreset(effectType);
        }
        #endif
    }
}
