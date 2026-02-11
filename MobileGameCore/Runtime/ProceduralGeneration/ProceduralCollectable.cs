using UnityEngine;

namespace MobileGameCore.ProceduralGeneration
{
    /// <summary>
    /// Generates procedural collectable meshes: coins, bars, gems, diamonds, chests.
    /// Perfect for loot items, currency pickups, treasure chests, etc.
    /// Zero asset dependencies - everything generated at runtime!
    ///
    /// USAGE:
    /// 1. Add this component to a GameObject
    /// 2. Set shape and color
    /// 3. Mesh generates automatically
    ///
    /// RUNTIME USAGE:
    /// ProceduralCollectable collectable = gameObject.AddComponent<ProceduralCollectable>();
    /// collectable.SetCollectableType(ProceduralCollectable.Shape.Coin, Color.yellow);
    /// </summary>
    public class ProceduralCollectable : ProceduralMeshGenerator
    {
        [Header("Collectable Type")]
        [SerializeField] private Shape collectableShape = Shape.Coin;

        [Header("Size Settings")]
        [SerializeField] private float collectableSize = 0.5f;

        [Header("Visual Settings")]
        [SerializeField] private Color collectableColor = new Color(1f, 0.84f, 0f); // Gold
        [SerializeField] private bool addGlowEffect = true;

        public enum Shape
        {
            Coin,
            Bar,
            Gem,
            Diamond,
            Chest
        }

        public enum ColorPreset
        {
            Gold,
            Silver,
            Bronze,
            Diamond,
            Ruby,
            Emerald,
            Sapphire,
            Amethyst
        }

        protected override void GenerateMesh()
        {
            ClearMesh();

            switch (collectableShape)
            {
                case Shape.Coin:
                    GenerateCoin();
                    break;
                case Shape.Bar:
                    GenerateBar();
                    break;
                case Shape.Gem:
                    GenerateGem();
                    break;
                case Shape.Diamond:
                    GenerateDiamond();
                    break;
                case Shape.Chest:
                    GenerateChest();
                    break;
            }

            ApplyMesh();

            // Add glow effect if enabled
            if (addGlowEffect)
            {
                AddGlowEffect();
            }
        }

        void GenerateCoin()
        {
            // Create a cylinder (coin shape)
            CreateCylinder(Vector3.zero, collectableSize * 0.8f, collectableSize * 0.2f, 16, collectableColor);
        }

        void GenerateBar()
        {
            // Create a beveled rectangular prism (gold bar shape)
            Vector3 size = new Vector3(collectableSize * 1.5f, collectableSize * 0.5f, collectableSize);
            CreateBox(Vector3.zero, size, collectableColor);

            // Add beveled edges (simplified)
            float bevel = 0.05f;
            Color darkerColor = collectableColor * 0.8f;

            // Top bevels
            Vector3 halfSize = size * 0.5f;
            AddQuad(
                new Vector3(-halfSize.x + bevel, halfSize.y, halfSize.z),
                new Vector3(halfSize.x - bevel, halfSize.y, halfSize.z),
                new Vector3(halfSize.x, halfSize.y - bevel, halfSize.z),
                new Vector3(-halfSize.x, halfSize.y - bevel, halfSize.z),
                darkerColor
            );
        }

        void GenerateGem()
        {
            // Create octahedron (simple gem shape)
            float size = collectableSize;
            Vector3 top = Vector3.up * size;
            Vector3 bottom = Vector3.down * size;

            // Create 8 triangular faces
            Vector3[] points = new Vector3[]
            {
                new Vector3(size, 0, 0),
                new Vector3(0, 0, size),
                new Vector3(-size, 0, 0),
                new Vector3(0, 0, -size)
            };

            // Upper pyramid
            for (int i = 0; i < 4; i++)
            {
                int next = (i + 1) % 4;
                AddTriangle(top, points[i], points[next], collectableColor);
            }

            // Lower pyramid
            for (int i = 0; i < 4; i++)
            {
                int next = (i + 1) % 4;
                AddTriangle(bottom, points[next], points[i], collectableColor * 0.9f);
            }
        }

        void GenerateDiamond()
        {
            // More complex gem with multiple facets
            float size = collectableSize;
            float topHeight = size * 0.3f;
            float bottomHeight = size * 0.7f;

            Vector3 apex = Vector3.up * topHeight;
            Vector3 bottom = Vector3.down * bottomHeight;

            // Crown (top part) - 8 facets
            int segments = 8;
            float radius = size * 0.8f;

            for (int i = 0; i < segments; i++)
            {
                float angle1 = (i / (float)segments) * Mathf.PI * 2f;
                float angle2 = ((i + 1) / (float)segments) * Mathf.PI * 2f;

                Vector3 p1 = new Vector3(Mathf.Cos(angle1) * radius, 0, Mathf.Sin(angle1) * radius);
                Vector3 p2 = new Vector3(Mathf.Cos(angle2) * radius, 0, Mathf.Sin(angle2) * radius);

                // Top facets
                AddTriangle(apex, p1, p2, collectableColor);

                // Bottom facets (pavilion)
                AddTriangle(bottom, p2, p1, collectableColor * 0.8f);
            }
        }

        void GenerateChest()
        {
            // Treasure/loot chest (box + lid)
            float size = collectableSize;

            // Main body
            CreateBox(new Vector3(0, size * 0.25f, 0), new Vector3(size * 1.2f, size * 0.5f, size * 0.8f), new Color(0.55f, 0.27f, 0.07f)); // Brown

            // Lid (slightly offset up)
            Vector3 lidCenter = new Vector3(0, size * 0.6f, 0);
            CreateBox(lidCenter, new Vector3(size * 1.3f, size * 0.2f, size * 0.9f), new Color(0.45f, 0.22f, 0.06f));

            // Trim/accent color
            CreateBox(new Vector3(0, size * 0.5f, 0), new Vector3(size * 1.4f, size * 0.05f, size), collectableColor);
        }

        void AddGlowEffect()
        {
            // Create a light component for glow
            Light glowLight = GetComponent<Light>();
            if (glowLight == null)
            {
                glowLight = gameObject.AddComponent<Light>();
            }

            glowLight.type = LightType.Point;
            glowLight.range = collectableSize * 5f;
            glowLight.intensity = 2f;
            glowLight.color = collectableColor;

            // Add pulsing animation
            ProceduralGlowPulse pulse = GetComponent<ProceduralGlowPulse>();
            if (pulse == null)
            {
                pulse = gameObject.AddComponent<ProceduralGlowPulse>();
            }
            pulse.Initialize(glowLight);
        }

        /// <summary>
        /// Set collectable type and regenerate mesh
        /// </summary>
        public void SetCollectableType(Shape shape, Color color)
        {
            collectableShape = shape;
            collectableColor = color;
            GenerateMesh();
        }

        /// <summary>
        /// Set collectable type using color preset
        /// </summary>
        public void SetCollectableType(Shape shape, ColorPreset preset)
        {
            collectableShape = shape;
            collectableColor = GetPresetColor(preset);
            GenerateMesh();
        }

        /// <summary>
        /// Get predefined color for common collectable types
        /// </summary>
        public static Color GetPresetColor(ColorPreset preset)
        {
            switch (preset)
            {
                case ColorPreset.Gold:
                    return new Color(1f, 0.84f, 0f); // Gold
                case ColorPreset.Silver:
                    return new Color(0.75f, 0.75f, 0.75f); // Silver
                case ColorPreset.Bronze:
                    return new Color(0.8f, 0.5f, 0.2f); // Bronze
                case ColorPreset.Diamond:
                    return new Color(0.7f, 0.9f, 1f); // Light blue
                case ColorPreset.Ruby:
                    return new Color(1f, 0.1f, 0.2f); // Red
                case ColorPreset.Emerald:
                    return new Color(0.2f, 0.9f, 0.3f); // Green
                case ColorPreset.Sapphire:
                    return new Color(0.15f, 0.35f, 0.8f); // Blue
                case ColorPreset.Amethyst:
                    return new Color(0.6f, 0.2f, 0.8f); // Purple
                default:
                    return Color.yellow;
            }
        }

        #if UNITY_EDITOR
        [ContextMenu("Cycle Shape")]
        void CycleShape()
        {
            collectableShape = (Shape)(((int)collectableShape + 1) % System.Enum.GetValues(typeof(Shape)).Length);
            GenerateMesh();
        }

        [ContextMenu("Random Color")]
        void RandomColor()
        {
            collectableColor = new Color(Random.value, Random.value, Random.value);
            GenerateMesh();
        }
        #endif
    }

    /// <summary>
    /// Simple component to pulse light intensity for glow effect.
    /// Automatically added by ProceduralCollectable when glow is enabled.
    /// </summary>
    public class ProceduralGlowPulse : MonoBehaviour
    {
        private Light targetLight;
        private float baseIntensity;
        private float pulseSpeed = 2f;
        private float pulseAmount = 0.5f;

        public void Initialize(Light light)
        {
            targetLight = light;
            baseIntensity = light.intensity;
        }

        public void SetPulseSettings(float speed, float amount)
        {
            pulseSpeed = speed;
            pulseAmount = amount;
        }

        void Update()
        {
            if (targetLight != null)
            {
                float pulse = Mathf.Sin(Time.time * pulseSpeed) * pulseAmount;
                targetLight.intensity = baseIntensity + pulse;
            }
        }
    }
}
