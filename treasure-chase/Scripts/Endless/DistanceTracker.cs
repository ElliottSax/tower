using UnityEngine;
using UnityEngine.Events;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Tracks player's distance traveled in the endless run.
    /// Provides distance-based milestones and achievements.
    /// </summary>
    public class DistanceTracker : MonoBehaviour
    {
        public static DistanceTracker Instance { get; private set; }

        [Header("Distance Settings")]
        [Tooltip("Multiplier for converting Unity units to display distance (e.g., meters)")]
        public float distanceMultiplier = 1f;

        [Tooltip("Milestone interval (e.g., every 100 meters)")]
        public float milestoneInterval = 100f;

        [Header("Events")]
        public UnityEvent<float> OnDistanceChanged;
        public UnityEvent<int> OnMilestoneReached; // Milestone number (1, 2, 3, etc.)

        // Private fields
        private Transform player;
        private float startZ;
        private float currentDistance;
        private float highestDistance;
        private int lastMilestone = 0;

        // Public properties
        public float CurrentDistance => currentDistance;
        public float HighestDistance => highestDistance;
        public int CurrentMilestone => Mathf.FloorToInt(currentDistance / milestoneInterval);

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
                Debug.LogWarning("Multiple DistanceTracker instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Find player vehicle
            var vehicleController = FindObjectOfType<VehicleController>();
            if (vehicleController != null)
            {
                player = vehicleController.transform;
                startZ = player.position.z;
            }
            else
            {
                Debug.LogError("DistanceTracker: No VehicleController found in scene!");
                return;
            }

            // Load highest distance from save system
            LoadHighestDistance();

            Debug.Log($"DistanceTracker: Initialized. Start Z={startZ}, Highest Distance={highestDistance}m");
        }

        void Update()
        {
            if (player == null) return;

            // Calculate current distance
            float rawDistance = player.position.z - startZ;
            currentDistance = rawDistance * distanceMultiplier;

            // Check for new record
            if (currentDistance > highestDistance)
            {
                highestDistance = currentDistance;
            }

            // Invoke distance changed event
            OnDistanceChanged?.Invoke(currentDistance);

            // Check for milestones
            CheckMilestones();
        }

        #endregion

        #region Milestone System

        /// <summary>
        /// Checks if player has reached a new milestone
        /// </summary>
        void CheckMilestones()
        {
            int currentMilestone = CurrentMilestone;

            if (currentMilestone > lastMilestone)
            {
                lastMilestone = currentMilestone;

                // Fire milestone event
                OnMilestoneReached?.Invoke(currentMilestone);

                // Log for debugging
                Debug.Log($"🎯 Milestone Reached: {currentMilestone * milestoneInterval}m");

                // Award bonus coins (optional - connect to EconomyManager)
                AwardMilestoneBonus(currentMilestone);

                // Check achievements (optional - connect to AchievementSystem)
                CheckDistanceAchievements();
            }
        }

        /// <summary>
        /// Awards bonus coins for reaching milestones
        /// </summary>
        void AwardMilestoneBonus(int milestone)
        {
            // Award coins based on milestone number
            int bonusCoins = milestone * 10; // 10 coins per milestone

            // Connect to EconomyManager (if available)
            var economyManager = FindObjectOfType<EconomyManager>();
            if (economyManager != null)
            {
                economyManager.AddCoins(bonusCoins);
                Debug.Log($"💰 Milestone Bonus: +{bonusCoins} coins");
            }
        }

        /// <summary>
        /// Checks and unlocks distance-based achievements
        /// </summary>
        void CheckDistanceAchievements()
        {
            var achievementSystem = FindObjectOfType<AchievementSystem>();
            if (achievementSystem == null) return;

            // Check various distance achievements
            if (currentDistance >= 1000f)
                achievementSystem.UnlockAchievement("marathon");

            if (currentDistance >= 5000f)
                achievementSystem.UnlockAchievement("ultra_marathon");

            if (currentDistance >= 10000f)
                achievementSystem.UnlockAchievement("endless_legend");

            if (currentDistance >= 25000f)
                achievementSystem.UnlockAchievement("endless_master");
        }

        #endregion

        #region Save/Load

        /// <summary>
        /// Loads highest distance from save system
        /// </summary>
        void LoadHighestDistance()
        {
            var saveSystem = FindObjectOfType<SaveSystem>();
            if (saveSystem != null)
            {
                highestDistance = saveSystem.GetFloat("highest_distance_endless", 0f);
            }
            else
            {
                // Fallback to PlayerPrefs
                highestDistance = PlayerPrefs.GetFloat("HighestDistance", 0f);
            }
        }

        /// <summary>
        /// Saves highest distance to save system
        /// </summary>
        public void SaveHighestDistance()
        {
            var saveSystem = FindObjectOfType<SaveSystem>();
            if (saveSystem != null)
            {
                saveSystem.SetFloat("highest_distance_endless", highestDistance);
                saveSystem.Save();
            }
            else
            {
                // Fallback to PlayerPrefs
                PlayerPrefs.SetFloat("HighestDistance", highestDistance);
                PlayerPrefs.Save();
            }

            Debug.Log($"💾 Saved Highest Distance: {highestDistance}m");
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Resets the distance tracker for a new run
        /// </summary>
        public void ResetDistance()
        {
            if (player != null)
            {
                startZ = player.position.z;
            }

            currentDistance = 0f;
            lastMilestone = 0;

            Debug.Log("DistanceTracker: Reset for new run");
        }

        /// <summary>
        /// Returns distance in formatted string (e.g., "1,234m")
        /// </summary>
        public string GetFormattedDistance()
        {
            return $"{currentDistance:N0}m";
        }

        /// <summary>
        /// Returns highest distance in formatted string
        /// </summary>
        public string GetFormattedHighestDistance()
        {
            return $"{highestDistance:N0}m";
        }

        /// <summary>
        /// Returns progress to next milestone (0-1)
        /// </summary>
        public float GetMilestoneProgress()
        {
            float distanceIntoMilestone = currentDistance % milestoneInterval;
            return distanceIntoMilestone / milestoneInterval;
        }

        #endregion

        #region Debug

        #if UNITY_EDITOR
        [ContextMenu("Test Milestone")]
        void TestMilestone()
        {
            CheckMilestones();
        }

        [ContextMenu("Add 100m")]
        void Add100m()
        {
            if (player != null)
            {
                player.position += Vector3.forward * 100f;
            }
        }

        void OnGUI()
        {
            if (!Application.isPlaying) return;

            // Display debug info
            GUIStyle style = new GUIStyle();
            style.fontSize = 20;
            style.normal.textColor = Color.white;

            GUI.Label(new Rect(10, 10, 300, 30), $"Distance: {GetFormattedDistance()}", style);
            GUI.Label(new Rect(10, 35, 300, 30), $"Best: {GetFormattedHighestDistance()}", style);
            GUI.Label(new Rect(10, 60, 300, 30), $"Milestone: {CurrentMilestone}", style);
            GUI.Label(new Rect(10, 85, 300, 30), $"Progress: {GetMilestoneProgress():P0}", style);
        }
        #endif

        #endregion
    }
}
