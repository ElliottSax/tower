using UnityEngine;

public class CoinSpawner : MonoBehaviour
{
    [Header("Coin Settings")]
    public GameObject coinPrefab;
    public int coinsPerChunk = 5;
    public float coinHeight = 1f;

    [Header("Lane Positions")]
    public float[] lanePositions = { -3f, 0f, 3f };

    [Header("Patterns")]
    public bool usePatterns = true;

    public void SpawnCoinsForChunk(GameObject chunk, float chunkStartZ, float chunkLength)
    {
        if (coinPrefab == null) return;

        if (usePatterns)
        {
            SpawnCoinPattern(chunk.transform, chunkStartZ, chunkLength);
        }
        else
        {
            SpawnRandomCoins(chunk.transform, chunkStartZ, chunkLength);
        }
    }

    void SpawnRandomCoins(Transform parent, float startZ, float length)
    {
        for (int i = 0; i < coinsPerChunk; i++)
        {
            // Random lane
            int randomLane = Random.Range(0, lanePositions.Length);
            float x = lanePositions[randomLane];

            // Random Z within chunk
            float z = startZ + Random.Range(5f, length - 5f);

            // Spawn coin
            Vector3 position = new Vector3(x, coinHeight, z);
            GameObject coin = Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }

    void SpawnCoinPattern(Transform parent, float startZ, float length)
    {
        // Choose random pattern
        int pattern = Random.Range(0, 4);

        switch (pattern)
        {
            case 0: // Single lane line
                SpawnSingleLane(parent, startZ, length);
                break;
            case 1: // Zigzag
                SpawnZigzag(parent, startZ, length);
                break;
            case 2: // All lanes horizontal
                SpawnHorizontalLine(parent, startZ + length * 0.5f);
                break;
            case 3: // Random scatter
                SpawnRandomCoins(parent, startZ, length);
                break;
        }
    }

    void SpawnSingleLane(Transform parent, float startZ, float length)
    {
        int lane = Random.Range(0, lanePositions.Length);
        float x = lanePositions[lane];

        for (int i = 0; i < 5; i++)
        {
            float z = startZ + (length / 6f) * (i + 1);
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }

    void SpawnZigzag(Transform parent, float startZ, float length)
    {
        int currentLane = 1; // Start center

        for (int i = 0; i < 5; i++)
        {
            float x = lanePositions[currentLane];
            float z = startZ + (length / 6f) * (i + 1);
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);

            // Alternate lanes
            currentLane = (currentLane == 0) ? 2 : (currentLane == 2) ? 0 : Random.Range(0, 2) * 2;
        }
    }

    void SpawnHorizontalLine(Transform parent, float z)
    {
        foreach (float x in lanePositions)
        {
            Vector3 position = new Vector3(x, coinHeight, z);
            Instantiate(coinPrefab, position, Quaternion.identity, parent);
        }
    }
}
