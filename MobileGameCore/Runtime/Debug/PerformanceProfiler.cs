using UnityEngine;
using System.Collections.Generic;
using System.Text;

namespace MobileGameCore.Debug
{
    /// <summary>
    /// Performance profiler for monitoring game performance in real-time.
    /// Tracks FPS, memory usage, draw calls, object counts, and provides visual overlay.
    /// Essential for optimization and debugging on mobile devices.
    ///
    /// USAGE:
    /// PerformanceProfiler.Instance.Show(); // Show profiler
    /// PerformanceProfiler.Instance.Toggle(); // Toggle with F1
    /// float fps = PerformanceProfiler.Instance.GetCurrentFPS();
    /// </summary>
    public class PerformanceProfiler : MonoBehaviour
    {
        public static PerformanceProfiler Instance { get; private set; }

        [Header("Display Settings")]
        [SerializeField] private bool showProfiler = true;
        [SerializeField] private KeyCode toggleKey = KeyCode.F1;
        [SerializeField] private int fontSize = 14;
        [SerializeField] private Color textColor = Color.green;
        [SerializeField] private Color warningColor = Color.yellow;
        [SerializeField] private Color errorColor = Color.red;

        [Header("Thresholds")]
        [SerializeField] private float targetFPS = 60f;
        [SerializeField] private float warningFPS = 30f;
        [SerializeField] private int warningMemoryMB = 512;
        [SerializeField] private int criticalMemoryMB = 768;

        [Header("Update Rate")]
        [SerializeField] private float updateInterval = 0.5f;

        // Performance metrics
        private float fps;
        private float minFPS = 999f;
        private float maxFPS = 0f;
        private float avgFPS = 0f;

        private float deltaTime = 0f;
        private float updateTimer = 0f;

        private int frameCount = 0;
        private float frameTimeAccumulator = 0f;

        private long totalMemoryMB;
        private long allocatedMemoryMB;
        private long reservedMemoryMB;
        private long monoMemoryMB;

        private int totalGameObjects;
        private int activeGameObjects;
        private int totalComponents;

        // Draw call tracking
        private int drawCalls;
        private int batches;
        private int triangles;
        private int vertices;

        // FPS history for graph
        private Queue<float> fpsHistory = new Queue<float>();
        private const int maxHistorySize = 60;

        private GUIStyle textStyle;
        private bool stylesInitialized = false;

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

        void Update()
        {
            // Toggle profiler
            if (UnityEngine.Input.GetKeyDown(toggleKey))
            {
                showProfiler = !showProfiler;
            }

            if (!showProfiler)
                return;

            // Calculate delta time
            deltaTime += (Time.unscaledDeltaTime - deltaTime) * 0.1f;

            // Update timer
            updateTimer += Time.unscaledDeltaTime;

            // Track frames
            frameCount++;
            frameTimeAccumulator += Time.unscaledDeltaTime;

            // Update metrics at interval
            if (updateTimer >= updateInterval)
            {
                UpdateMetrics();
                updateTimer = 0f;
            }
        }

        void UpdateMetrics()
        {
            // FPS calculation
            fps = frameCount / frameTimeAccumulator;

            // Track min/max
            if (fps < minFPS) minFPS = fps;
            if (fps > maxFPS && fps < 999) maxFPS = fps;

            // Add to history
            fpsHistory.Enqueue(fps);
            if (fpsHistory.Count > maxHistorySize)
                fpsHistory.Dequeue();

            // Calculate average from history
            float sum = 0f;
            foreach (float f in fpsHistory)
                sum += f;
            avgFPS = sum / fpsHistory.Count;

            // Reset frame tracking
            frameCount = 0;
            frameTimeAccumulator = 0f;

            // Memory stats
            totalMemoryMB = System.GC.GetTotalMemory(false) / (1024 * 1024);
            allocatedMemoryMB = UnityEngine.Profiling.Profiler.GetTotalAllocatedMemoryLong() / (1024 * 1024);
            reservedMemoryMB = UnityEngine.Profiling.Profiler.GetTotalReservedMemoryLong() / (1024 * 1024);
            monoMemoryMB = UnityEngine.Profiling.Profiler.GetMonoUsedSizeLong() / (1024 * 1024);

            // GameObject counts
            totalGameObjects = FindObjectsOfType<GameObject>().Length;
            activeGameObjects = 0;
            totalComponents = 0;

            GameObject[] allObjects = FindObjectsOfType<GameObject>();
            foreach (GameObject obj in allObjects)
            {
                if (obj.activeInHierarchy)
                    activeGameObjects++;
                totalComponents += obj.GetComponents<Component>().Length;
            }

            // Rendering stats (Note: These require Unity Stats in build)
            #if UNITY_EDITOR
            UpdateRenderingStats();
            #endif
        }

        #if UNITY_EDITOR
        void UpdateRenderingStats()
        {
            // Access rendering stats via UnityStats
            drawCalls = UnityEditor.UnityStats.drawCalls;
            batches = UnityEditor.UnityStats.batches;
            triangles = UnityEditor.UnityStats.triangles;
            vertices = UnityEditor.UnityStats.vertices;
        }
        #endif

        void OnGUI()
        {
            if (!showProfiler)
                return;

            InitializeStyles();

            // Draw profiler panel
            float panelWidth = 300f;
            float panelHeight = 400f;
            Rect panelRect = new Rect(10, 10, panelWidth, panelHeight);

            // Background
            GUI.Box(panelRect, "");

            // Content
            GUILayout.BeginArea(panelRect);
            GUILayout.Label("PERFORMANCE PROFILER", textStyle);
            GUILayout.Space(5);

            DrawFPSSection();
            GUILayout.Space(10);

            DrawMemorySection();
            GUILayout.Space(10);

            DrawObjectSection();
            GUILayout.Space(10);

            #if UNITY_EDITOR
            DrawRenderingSection();
            #endif

            GUILayout.EndArea();

            // FPS Graph
            DrawFPSGraph(new Rect(panelWidth + 20, 10, 200, 100));
        }

        void InitializeStyles()
        {
            if (stylesInitialized)
                return;

            textStyle = new GUIStyle(GUI.skin.label);
            textStyle.fontSize = fontSize;
            textStyle.normal.textColor = textColor;
            textStyle.richText = true;

            stylesInitialized = true;
        }

        void DrawFPSSection()
        {
            GUILayout.Label("<b>FRAMERATE</b>", textStyle);

            // Current FPS with color coding
            Color fpsColor = GetFPSColor(fps);
            string fpsText = $"<color=#{ColorUtility.ToHtmlStringRGB(fpsColor)}>FPS: {fps:F1}</color>";
            GUILayout.Label(fpsText, textStyle);

            GUILayout.Label($"Min: {minFPS:F1} | Max: {maxFPS:F1} | Avg: {avgFPS:F1}", textStyle);
            GUILayout.Label($"Frame Time: {deltaTime * 1000f:F1} ms", textStyle);
        }

        void DrawMemorySection()
        {
            GUILayout.Label("<b>MEMORY</b>", textStyle);

            Color memColor = GetMemoryColor(allocatedMemoryMB);
            string memText = $"<color=#{ColorUtility.ToHtmlStringRGB(memColor)}>Allocated: {allocatedMemoryMB} MB</color>";
            GUILayout.Label(memText, textStyle);

            GUILayout.Label($"Reserved: {reservedMemoryMB} MB", textStyle);
            GUILayout.Label($"Mono: {monoMemoryMB} MB", textStyle);
            GUILayout.Label($"GC Total: {totalMemoryMB} MB", textStyle);
        }

        void DrawObjectSection()
        {
            GUILayout.Label("<b>SCENE OBJECTS</b>", textStyle);

            GUILayout.Label($"GameObjects: {activeGameObjects} / {totalGameObjects}", textStyle);
            GUILayout.Label($"Components: {totalComponents}", textStyle);
        }

        void DrawRenderingSection()
        {
            GUILayout.Label("<b>RENDERING</b>", textStyle);

            GUILayout.Label($"Draw Calls: {drawCalls}", textStyle);
            GUILayout.Label($"Batches: {batches}", textStyle);
            GUILayout.Label($"Triangles: {triangles:N0}", textStyle);
            GUILayout.Label($"Vertices: {vertices:N0}", textStyle);
        }

        void DrawFPSGraph(Rect rect)
        {
            // Background
            GUI.Box(rect, "");

            if (fpsHistory.Count < 2)
                return;

            // Convert history to array for easier access
            float[] history = fpsHistory.ToArray();

            // Calculate graph bounds
            float graphHeight = rect.height - 20;
            float graphWidth = rect.width - 20;
            float stepX = graphWidth / (maxHistorySize - 1);

            // Find max/min for scaling
            float minValue = targetFPS * 0.5f;
            float maxValue = targetFPS * 1.5f;

            // Draw target FPS line
            float targetY = rect.y + 10 + graphHeight * (1f - (targetFPS - minValue) / (maxValue - minValue));
            DrawLine(new Vector2(rect.x + 10, targetY), new Vector2(rect.x + rect.width - 10, targetY), Color.gray);

            // Draw graph line
            for (int i = 0; i < history.Length - 1; i++)
            {
                float x1 = rect.x + 10 + (i * stepX);
                float y1 = rect.y + 10 + graphHeight * (1f - (history[i] - minValue) / (maxValue - minValue));

                float x2 = rect.x + 10 + ((i + 1) * stepX);
                float y2 = rect.y + 10 + graphHeight * (1f - (history[i + 1] - minValue) / (maxValue - minValue));

                Color lineColor = GetFPSColor(history[i]);
                DrawLine(new Vector2(x1, y1), new Vector2(x2, y2), lineColor);
            }

            // Label
            GUI.Label(new Rect(rect.x, rect.y + rect.height - 15, rect.width, 20), "FPS History", textStyle);
        }

        void DrawLine(Vector2 start, Vector2 end, Color color)
        {
            // Simple line drawing using GUI textures
            Texture2D tex = new Texture2D(1, 1);
            tex.SetPixel(0, 0, color);
            tex.Apply();

            float angle = Mathf.Atan2(end.y - start.y, end.x - start.x) * Mathf.Rad2Deg;
            float distance = Vector2.Distance(start, end);

            GUIUtility.RotateAroundPivot(angle, start);
            GUI.DrawTexture(new Rect(start.x, start.y, distance, 2), tex);
            GUIUtility.RotateAroundPivot(-angle, start);

            Destroy(tex);
        }

        Color GetFPSColor(float currentFPS)
        {
            if (currentFPS >= targetFPS)
                return textColor; // Green
            else if (currentFPS >= warningFPS)
                return warningColor; // Yellow
            else
                return errorColor; // Red
        }

        Color GetMemoryColor(long memoryMB)
        {
            if (memoryMB >= criticalMemoryMB)
                return errorColor;
            else if (memoryMB >= warningMemoryMB)
                return warningColor;
            else
                return textColor;
        }

        #region Public API

        /// <summary>
        /// Show the profiler
        /// </summary>
        public void Show()
        {
            showProfiler = true;
        }

        /// <summary>
        /// Hide the profiler
        /// </summary>
        public void Hide()
        {
            showProfiler = false;
        }

        /// <summary>
        /// Toggle profiler visibility
        /// </summary>
        public void Toggle()
        {
            showProfiler = !showProfiler;
        }

        /// <summary>
        /// Reset min/max FPS tracking
        /// </summary>
        public void ResetFPSTracking()
        {
            minFPS = 999f;
            maxFPS = 0f;
            fpsHistory.Clear();
        }

        /// <summary>
        /// Get current FPS
        /// </summary>
        public float GetCurrentFPS()
        {
            return fps;
        }

        /// <summary>
        /// Get current memory usage in MB
        /// </summary>
        public long GetAllocatedMemory()
        {
            return allocatedMemoryMB;
        }

        /// <summary>
        /// Get performance summary as string
        /// </summary>
        public string GetPerformanceSummary()
        {
            StringBuilder sb = new StringBuilder();
            sb.AppendLine($"FPS: {fps:F1} (Min: {minFPS:F1}, Max: {maxFPS:F1}, Avg: {avgFPS:F1})");
            sb.AppendLine($"Memory: {allocatedMemoryMB} MB allocated, {reservedMemoryMB} MB reserved");
            sb.AppendLine($"Objects: {activeGameObjects} active GameObjects, {totalComponents} components");
            #if UNITY_EDITOR
            sb.AppendLine($"Rendering: {drawCalls} draw calls, {batches} batches, {triangles:N0} triangles");
            #endif
            return sb.ToString();
        }

        /// <summary>
        /// Log performance summary to console
        /// </summary>
        [ContextMenu("Log Performance Summary")]
        public void LogPerformanceSummary()
        {
            UnityEngine.Debug.Log($"<color=cyan>=== PERFORMANCE PROFILER ===</color>\n{GetPerformanceSummary()}");
        }

        #endregion
    }
}
