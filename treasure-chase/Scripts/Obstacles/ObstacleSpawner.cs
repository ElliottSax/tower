using UnityEngine;
using System.Collections.Generic;

namespace TreasureChase.Obstacles
{
    /// <summary>
    /// Spawns obstacles in terrain chunks with dynamic difficulty scaling.
    /// Supports patterns, random spawning, and theme-specific obstacles.
    /// </summary>
    public class ObstacleSpawner : MonoBehaviour
    {
        [Header("Obstacle Prefabs")]
        [Tooltip("Array of obstacle prefabs to spawn")]
        public GameObject[] standardObstacles;

        [Tooltip("Theme-specific obstacles (set at runtime by WorldManager)")]
        public GameObject[] themeObstacles;

        [Header("Spawn Settings")]
        [Tooltip("Base probability of spawning obstacle per chunk (0-1)")]
        [Range(0f, 1f)]
        public float baseSpawnChance = 0.5f;

        [Tooltip("Minimum spacing between obstacles (meters)")]
        public float minObstacleSpacing = 10f;

        [Tooltip("Maximum obstacles per chunk")]
        [Range(1, 10)]
        public int maxObstaclesPerChunk = 3;

        [Header("Difficulty Scaling")]
        [Tooltip("Rate at which difficulty increases over distance")]
        public float difficultyIncreaseRate = 0.001f;

        [Tooltip("Maximum difficulty multiplier")]
        public float maxDifficulty = 5f;

        [Tooltip("Distance before difficulty starts increasing")]
        public float easyModeDuration = 300f; // 300 meters

        [Header("Lane Settings")]
        [Tooltip("Lane positions (X coordinates)")]
        public float[] lanePositions = { -3f, 0f, 3f }; // Left, Center, Right

        // Private fields
        private float currentDifficulty = 1f;

        #region Public Methods

        /// <summary>
        /// Spawns obstacles in a terrain chunk
        /// </summary>
        public void SpawnInChunk(GameObject chunk, Vector3 chunkPosition, float chunkLength)
        {
            // Update difficulty based on distance
            UpdateDifficulty(chunkPosition.z);

            // Determine number of obstacles for this chunk
            int obstacleCount = CalculateObstacleCount();

            // Track spawned positions to enforce spacing
            List<float> spawnedZPositions = new List<float>();

            for (int i = 0; i < obstacleCount; i++)
            {
                // Choose random position within chunk
                float randomZ = GetRandomSpawnZ(chunkPosition.z, chunkLength, spawnedZPositions);
                if (randomZ < 0) continue; // Failed to find valid position

                // Choose random lane
                int randomLane = Random.Range(0, lanePositions.Length);
                float xPos = lanePositions[randomLane];

                // Choose obstacle type
                GameObject obstaclePrefab = ChooseObstaclePrefab();
                if (obstaclePrefab == null) continue;

                // Spawn obstacle
                Vector3 spawnPos = new Vector3(xPos, 0f, randomZ);
                GameObject obstacle = Instantiate(obstaclePrefab, spawnPos, Quaternion.identity, chunk.transform);
                obstacle.tag = "Obstacle";

                // Track spawned position
                spawnedZPositions.Add(randomZ);

                #if UNITY_EDITOR
                Debug.Log($"Spawned {obstaclePrefab.name} at lane {randomLane}, Z={randomZ}");
                #endif
            }
        }

        /// <summary>
        /// Sets theme-specific obstacles
        /// </summary>
        public void SetThemeObstacles(GameObject[] obstacles)
        {
            themeObstacles = obstacles;
            Debug.Log($"ObstacleSpawner: Theme obstacles set ({obstacles.Length} types)");
        }

        #endregion

        #region Private Methods

        /// <summary>
        /// Updates difficulty based on distance traveled
        /// </summary>
        void UpdateDifficulty(float distance)
        {
            if (distance < easyModeDuration)
            {
                currentDifficulty = 1f; // Easy mode
            }
            else
            {
                // Gradually increase difficulty after easy mode
                float distanceAfterEasy = distance - easyModeDuration;
                currentDifficulty = 1f + (distanceAfterEasy * difficultyIncreaseRate);
                currentDifficulty = Mathf.Min(currentDifficulty, maxDifficulty);
            }
        }

        /// <summary>
        /// Calculates number of obstacles to spawn based on difficulty
        /// </summary>
        int CalculateObstacleCount()
        {
            // Increase spawn chance with difficulty
            float adjustedChance = baseSpawnChance * currentDifficulty;

            // Random chance to spawn
            if (Random.value > adjustedChance)
            {
                return 0; // No obstacles this chunk
            }

            // More obstacles at higher difficulty
            int count = Mathf.FloorToInt(1f + (currentDifficulty - 1f));
            return Mathf.Clamp(count, 1, maxObstaclesPerChunk);
        }

        /// <summary>
        /// Gets a random spawn Z position with spacing enforcement
        /// </summary>
        float GetRandomSpawnZ(float chunkStart, float chunkLength, List<float> existingPositions)
        {
            // Try to find valid position (max 10 attempts)
            for (int attempt = 0; attempt < 10; attempt++)
            {
                float randomZ = chunkStart + Random.Range(5f, chunkLength - 5f);

                // Check spacing from existing obstacles
                bool validPosition = true;
                foreach (float existingZ in existingPositions)
                {
                    if (Mathf.Abs(randomZ - existingZ) < minObstacleSpacing)
                    {
                        validPosition = false;
                        break;
                    }
                }

                if (validPosition)
                {
                    return randomZ;
                }
            }

            // Failed to find valid position
            return -1f;
        }

        /// <summary>
        /// Chooses an obstacle prefab to spawn (standard or theme)
        /// </summary>
        GameObject ChooseObstaclePrefab()
        {
            // Combine standard and theme obstacles
            List<GameObject> availableObstacles = new List<GameObject>();

            if (standardObstacles != null && standardObstacles.Length > 0)
            {
                availableObstacles.AddRange(standardObstacles);
            }

            if (themeObstacles != null && themeObstacles.Length > 0)
            {
                // 50% chance to use theme obstacle
                if (Random.value > 0.5f)
                {
                    return themeObstacles[Random.Range(0, themeObstacles.Length)];
                }
            }

            if (availableObstacles.Count == 0)
            {
                Debug.LogWarning("ObstacleSpawner: No obstacle prefabs assigned!");
                return null;
            }

            return availableObstacles[Random.Range(0, availableObstacles.Count)];
        }

        #endregion

        #region Debug

        #if UNITY_EDITOR
        [ContextMenu("Test Spawn")]
        void TestSpawn()
        {
            GameObject testChunk = new GameObject("TestChunk");
            SpawnInChunk(testChunk, Vector3.zero, 50f);
        }

        void OnDrawGizmos()
        {
            // Draw lane positions
            Gizmos.color = Color.cyan;
            foreach (float xPos in lanePositions)
            {
                Gizmos.DrawLine(
                    new Vector3(xPos, 0, -100),
                    new Vector3(xPos, 0, 100)
                );
            }
        }
        #endif

        #endregion
    }
}
