using UnityEngine;
using System.Collections.Generic;
using TreasureChase.Obstacles;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Manages infinite terrain generation using chunk-based pooling system.
    /// Spawns terrain ahead of player and recycles chunks behind.
    /// </summary>
    public class InfiniteTerrainManager : MonoBehaviour
    {
        public static InfiniteTerrainManager Instance { get; private set; }

        [Header("Terrain Settings")]
        [Tooltip("Prefab for terrain chunks (50 units long recommended)")]
        public GameObject terrainChunkPrefab;

        [Tooltip("Number of chunks to keep ahead of player")]
        [Range(3, 10)]
        public int chunksAhead = 5;

        [Tooltip("Number of chunks to keep behind player")]
        [Range(1, 3)]
        public int chunksBehind = 2;

        [Tooltip("Length of each terrain chunk in world units")]
        public float chunkLength = 50f;

        [Header("Spawning")]
        [Tooltip("Reference to obstacle spawner for populating chunks")]
        public ObstacleSpawner obstacleSpawner;

        [Tooltip("Reference to coin spawner for populating chunks")]
        public CoinSpawner coinSpawner;

        [Header("World Theme")]
        public WorldTheme currentTheme;

        // Private fields
        private Transform player;
        private float nextChunkZ = 0f;
        private List<GameObject> activeChunks = new List<GameObject>();
        private Queue<GameObject> chunkPool = new Queue<GameObject>();
        private int totalChunksSpawned = 0;

        #region Unity Lifecycle

        void Awake()
        {
            // Singleton pattern
            if (Instance == null)
            {
                Instance = this;
            }
            else
            {
                Debug.LogWarning("Multiple InfiniteTerrainManager instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Find player - try PlayerController first, then VehicleController
            var playerController = FindObjectOfType<PlayerController>();
            if (playerController != null)
            {
                player = playerController.transform;
            }
            else
            {
                Debug.LogError("InfiniteTerrainManager: No PlayerController found in scene!");
                return;
            }

            // Generate initial chunks
            for (int i = 0; i < chunksAhead; i++)
            {
                SpawnChunk();
            }

            Debug.Log($"InfiniteTerrainManager: Initialized with {chunksAhead} chunks ahead");
        }

        void Update()
        {
            if (player == null) return;

            // Check if we need to spawn new chunk ahead
            if (player.position.z > nextChunkZ - (chunksAhead * chunkLength))
            {
                SpawnChunk();
            }

            // Recycle old chunks behind player
            if (activeChunks.Count > 0)
            {
                GameObject oldestChunk = activeChunks[0];
                float chunkZ = oldestChunk.transform.position.z;

                if (chunkZ < player.position.z - (chunksBehind * chunkLength))
                {
                    RecycleChunk(oldestChunk);
                }
            }
        }

        #endregion

        #region Chunk Management

        /// <summary>
        /// Spawns a new terrain chunk ahead of the player
        /// </summary>
        void SpawnChunk()
        {
            GameObject chunk;

            // Try to get chunk from pool
            if (chunkPool.Count > 0)
            {
                chunk = chunkPool.Dequeue();
                chunk.SetActive(true);
            }
            else
            {
                // Create new chunk if pool is empty
                if (terrainChunkPrefab == null)
                {
                    Debug.LogError("InfiniteTerrainManager: Terrain chunk prefab not assigned!");
                    return;
                }

                chunk = Instantiate(terrainChunkPrefab, transform);
            }

            // Position chunk
            chunk.transform.position = new Vector3(0, 0, nextChunkZ);
            chunk.name = $"TerrainChunk_{totalChunksSpawned}";

            // Add to active list
            activeChunks.Add(chunk);
            nextChunkZ += chunkLength;
            totalChunksSpawned++;

            // Populate chunk with content
            PopulateChunk(chunk);

            #if UNITY_EDITOR
            Debug.Log($"Spawned chunk {totalChunksSpawned} at Z={chunk.transform.position.z}");
            #endif
        }

        /// <summary>
        /// Recycles a chunk back into the pool
        /// </summary>
        void RecycleChunk(GameObject chunk)
        {
            activeChunks.Remove(chunk);

            // Clear any spawned objects (treasures, obstacles, etc.)
            ClearChunkContent(chunk);

            // Deactivate and add to pool
            chunk.SetActive(false);
            chunkPool.Enqueue(chunk);

            #if UNITY_EDITOR
            Debug.Log($"Recycled chunk at Z={chunk.transform.position.z}. Pool size: {chunkPool.Count}");
            #endif
        }

        /// <summary>
        /// Populates a chunk with treasures, obstacles, gates, and power-ups
        /// </summary>
        void PopulateChunk(GameObject chunk)
        {
            Vector3 chunkPosition = chunk.transform.position;

            // Spawn obstacles (if spawner exists)
            if (obstacleSpawner != null)
            {
                obstacleSpawner.SpawnInChunk(chunk, chunkPosition, chunkLength);
            }

            // Spawn coins (if spawner exists)
            if (coinSpawner != null)
            {
                coinSpawner.SpawnCoinsForChunk(chunk, chunkPosition.z, chunkLength);
            }

            // Apply world theme if set
            if (currentTheme != null)
            {
                ApplyThemeToChunk(chunk);
            }
        }

        /// <summary>
        /// Clears all spawned content from a chunk before recycling
        /// </summary>
        void ClearChunkContent(GameObject chunk)
        {
            // Find all child objects (treasures, obstacles, etc.)
            // Note: This assumes spawned objects are parented to the chunk
            Transform chunkTransform = chunk.transform;

            for (int i = chunkTransform.childCount - 1; i >= 0; i--)
            {
                Transform child = chunkTransform.GetChild(i);

                // Only destroy dynamically spawned objects (not terrain mesh)
                if (child.CompareTag("Treasure") ||
                    child.CompareTag("Obstacle") ||
                    child.CompareTag("PowerUp") ||
                    child.CompareTag("Gate"))
                {
                    Destroy(child.gameObject);
                }
            }
        }

        /// <summary>
        /// Applies visual theme to a chunk (materials, decorations, etc.)
        /// </summary>
        void ApplyThemeToChunk(GameObject chunk)
        {
            if (currentTheme == null) return;

            // Apply terrain material
            var renderer = chunk.GetComponent<Renderer>();
            if (renderer != null && currentTheme.terrainMaterial != null)
            {
                renderer.material = currentTheme.terrainMaterial;
            }

            // Spawn environment decorations (TODO: implement)
            // Random.Range for variety
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Sets the current world theme and applies it to active chunks
        /// </summary>
        public void SetTheme(WorldTheme theme)
        {
            currentTheme = theme;

            // Apply to all active chunks
            foreach (var chunk in activeChunks)
            {
                ApplyThemeToChunk(chunk);
            }

            Debug.Log($"InfiniteTerrainManager: Theme changed to {theme.themeName}");
        }

        /// <summary>
        /// Sets current theme (called by WorldManager during transition start)
        /// </summary>
        public void SetCurrentTheme(WorldTheme theme)
        {
            SetTheme(theme);
        }

        /// <summary>
        /// Called when theme change is applied (called by WorldManager after transition midpoint)
        /// </summary>
        public void OnThemeChanged(WorldTheme theme)
        {
            // Re-apply theme to ensure all chunks are updated
            SetTheme(theme);
        }

        /// <summary>
        /// Returns the total number of chunks spawned (useful for difficulty scaling)
        /// </summary>
        public int GetTotalChunksSpawned() => totalChunksSpawned;

        /// <summary>
        /// Returns the current pool size (for debugging/optimization)
        /// </summary>
        public int GetPoolSize() => chunkPool.Count;

        #endregion

        #region Debug

        #if UNITY_EDITOR
        void OnDrawGizmos()
        {
            if (!Application.isPlaying) return;

            // Draw chunk boundaries
            Gizmos.color = Color.yellow;

            foreach (var chunk in activeChunks)
            {
                Vector3 center = chunk.transform.position + Vector3.forward * (chunkLength / 2f);
                Gizmos.DrawWireCube(center, new Vector3(10f, 0.5f, chunkLength));
            }

            // Draw player position
            if (player != null)
            {
                Gizmos.color = Color.green;
                Gizmos.DrawSphere(player.position, 1f);
            }
        }
        #endif

        #endregion
    }
}
