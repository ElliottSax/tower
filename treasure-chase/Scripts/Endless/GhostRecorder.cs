using UnityEngine;
using System.Collections.Generic;
using System.IO;
using System.Runtime.Serialization.Formatters.Binary;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Records and plays back player runs as ghost replays.
    /// Used for tournaments, time trials, and personal best comparison.
    /// </summary>
    public class GhostRecorder : MonoBehaviour
    {
        public static GhostRecorder Instance { get; private set; }

        [Header("Recording Settings")]
        [Tooltip("Frequency of recording (samples per second)")]
        public int recordingFrequency = 30;

        [Tooltip("Maximum recording duration (seconds)")]
        public float maxRecordingDuration = 600f; // 10 minutes

        [Header("Ghost Visualization")]
        [Tooltip("Ghost player prefab (semi-transparent)")]
        public GameObject ghostPrefab;

        [Tooltip("Ghost material color")]
        public Color ghostColor = new Color(0.5f, 0.5f, 1f, 0.5f);

        [Header("Playback")]
        [Tooltip("Show ghost by default?")]
        public bool showGhostByDefault = true;

        // Private fields
        private bool isRecording = false;
        private bool isPlaying = false;
        private GhostRun currentRecording;
        private GhostRun currentPlayback;
        private GameObject ghostObject;
        private float recordTimer = 0f;
        private float playbackTimer = 0f;
        private int playbackIndex = 0;

        // Public properties
        public bool IsRecording => isRecording;
        public bool IsPlaying => isPlaying;
        public GhostRun PersonalBestGhost { get; private set; }

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
                Debug.LogWarning("Multiple GhostRecorder instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Load personal best ghost
            LoadPersonalBest();

            Debug.Log("GhostRecorder: Initialized");
        }

        void Update()
        {
            if (isRecording)
            {
                UpdateRecording();
            }

            if (isPlaying)
            {
                UpdatePlayback();
            }
        }

        #endregion

        #region Recording

        /// <summary>
        /// Starts recording a new ghost run
        /// </summary>
        public void StartRecording()
        {
            if (isRecording)
            {
                Debug.LogWarning("GhostRecorder: Already recording!");
                return;
            }

            currentRecording = new GhostRun();
            currentRecording.startTime = Time.time;
            currentRecording.frames = new List<GhostFrame>();

            isRecording = true;
            recordTimer = 0f;

            Debug.Log("🎬 Ghost recording started");
        }

        /// <summary>
        /// Updates recording each frame
        /// </summary>
        void UpdateRecording()
        {
            recordTimer += Time.deltaTime;

            // Check max duration
            if (recordTimer >= maxRecordingDuration)
            {
                StopRecording();
                return;
            }

            // Record at specified frequency
            float interval = 1f / recordingFrequency;
            if (recordTimer - (currentRecording.frames.Count * interval) >= interval)
            {
                RecordFrame();
            }
        }

        /// <summary>
        /// Records a single frame of player data
        /// </summary>
        void RecordFrame()
        {
            var vehicleController = FindObjectOfType<VehicleController>();
            if (vehicleController == null) return;

            GhostFrame frame = new GhostFrame
            {
                timestamp = recordTimer,
                position = vehicleController.transform.position,
                rotation = vehicleController.transform.rotation,
                velocity = vehicleController.GetVelocity(),
                laneIndex = vehicleController.GetCurrentLane(),
                isJumping = vehicleController.IsJumping,
                isPowerUpActive = vehicleController.HasAnyPowerUp()
            };

            currentRecording.frames.Add(frame);
        }

        /// <summary>
        /// Stops recording and saves the ghost run
        /// </summary>
        public void StopRecording()
        {
            if (!isRecording) return;

            isRecording = false;

            // Finalize recording
            currentRecording.endTime = Time.time;
            currentRecording.totalDuration = recordTimer;
            currentRecording.finalDistance = DistanceTracker.Instance?.CurrentDistance ?? 0f;
            currentRecording.finalScore = EndlessScoreManager.Instance?.CurrentScore ?? 0;

            Debug.Log($"🎬 Ghost recording stopped - {currentRecording.frames.Count} frames, {currentRecording.totalDuration:F1}s");

            // Check if this is a new personal best
            if (IsNewPersonalBest(currentRecording))
            {
                SavePersonalBest(currentRecording);
            }
        }

        #endregion

        #region Playback

        /// <summary>
        /// Starts playing back a ghost run
        /// </summary>
        public void StartPlayback(GhostRun ghostRun)
        {
            if (ghostRun == null || ghostRun.frames.Count == 0)
            {
                Debug.LogWarning("GhostRecorder: Invalid ghost run!");
                return;
            }

            currentPlayback = ghostRun;
            playbackTimer = 0f;
            playbackIndex = 0;
            isPlaying = true;

            // Create ghost object
            CreateGhostObject();

            Debug.Log($"👻 Ghost playback started - {ghostRun.frames.Count} frames");
        }

        /// <summary>
        /// Updates ghost playback each frame
        /// </summary>
        void UpdatePlayback()
        {
            playbackTimer += Time.deltaTime;

            // Check if playback finished
            if (playbackIndex >= currentPlayback.frames.Count)
            {
                StopPlayback();
                return;
            }

            // Find current frame
            while (playbackIndex < currentPlayback.frames.Count &&
                   currentPlayback.frames[playbackIndex].timestamp <= playbackTimer)
            {
                UpdateGhostPosition(currentPlayback.frames[playbackIndex]);
                playbackIndex++;
            }
        }

        /// <summary>
        /// Updates ghost object position
        /// </summary>
        void UpdateGhostPosition(GhostFrame frame)
        {
            if (ghostObject == null) return;

            ghostObject.transform.position = frame.position;
            ghostObject.transform.rotation = frame.rotation;

            // Update ghost visual based on state
            var ghostRenderer = ghostObject.GetComponent<Renderer>();
            if (ghostRenderer != null)
            {
                Color color = frame.isPowerUpActive ? Color.yellow : ghostColor;
                ghostRenderer.material.color = color;
            }
        }

        /// <summary>
        /// Stops ghost playback
        /// </summary>
        public void StopPlayback()
        {
            if (!isPlaying) return;

            isPlaying = false;
            DestroyGhostObject();

            Debug.Log("👻 Ghost playback stopped");
        }

        /// <summary>
        /// Creates ghost visualization object
        /// </summary>
        void CreateGhostObject()
        {
            if (ghostObject != null)
            {
                Destroy(ghostObject);
            }

            if (ghostPrefab != null)
            {
                ghostObject = Instantiate(ghostPrefab);
                ghostObject.name = "Ghost";

                // Make semi-transparent
                var renderer = ghostObject.GetComponent<Renderer>();
                if (renderer != null)
                {
                    renderer.material.color = ghostColor;
                    renderer.material.SetFloat("_Mode", 3); // Transparent
                    renderer.material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                    renderer.material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                    renderer.material.SetInt("_ZWrite", 0);
                    renderer.material.DisableKeyword("_ALPHATEST_ON");
                    renderer.material.EnableKeyword("_ALPHABLEND_ON");
                    renderer.material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                    renderer.material.renderQueue = 3000;
                }
            }
            else
            {
                // Fallback: Create simple cube
                ghostObject = GameObject.CreatePrimitive(PrimitiveType.Cube);
                ghostObject.name = "Ghost";
                var renderer = ghostObject.GetComponent<Renderer>();
                renderer.material.color = ghostColor;
            }
        }

        /// <summary>
        /// Destroys ghost visualization
        /// </summary>
        void DestroyGhostObject()
        {
            if (ghostObject != null)
            {
                Destroy(ghostObject);
                ghostObject = null;
            }
        }

        #endregion

        #region Personal Best

        /// <summary>
        /// Checks if recording is a new personal best
        /// </summary>
        bool IsNewPersonalBest(GhostRun run)
        {
            if (PersonalBestGhost == null) return true;
            return run.finalScore > PersonalBestGhost.finalScore;
        }

        /// <summary>
        /// Saves ghost as personal best
        /// </summary>
        void SavePersonalBest(GhostRun run)
        {
            PersonalBestGhost = run;

            // Save to disk
            string path = GetPersonalBestPath();
            try
            {
                BinaryFormatter formatter = new BinaryFormatter();
                FileStream stream = new FileStream(path, FileMode.Create);
                formatter.Serialize(stream, run);
                stream.Close();

                Debug.Log($"🏆 New Personal Best saved! Score: {run.finalScore}, Distance: {run.finalDistance:F0}m");
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Failed to save personal best: {e.Message}");
            }
        }

        /// <summary>
        /// Loads personal best from disk
        /// </summary>
        void LoadPersonalBest()
        {
            string path = GetPersonalBestPath();
            if (!File.Exists(path))
            {
                Debug.Log("GhostRecorder: No personal best found");
                return;
            }

            try
            {
                BinaryFormatter formatter = new BinaryFormatter();
                FileStream stream = new FileStream(path, FileMode.Open);
                PersonalBestGhost = formatter.Deserialize(stream) as GhostRun;
                stream.Close();

                Debug.Log($"GhostRecorder: Personal best loaded - Score: {PersonalBestGhost.finalScore}, Distance: {PersonalBestGhost.finalDistance:F0}m");
            }
            catch (System.Exception e)
            {
                Debug.LogError($"Failed to load personal best: {e.Message}");
            }
        }

        /// <summary>
        /// Gets file path for personal best
        /// </summary>
        string GetPersonalBestPath()
        {
            return Path.Combine(Application.persistentDataPath, "personal_best_ghost.dat");
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Plays back personal best ghost
        /// </summary>
        public void PlayPersonalBest()
        {
            if (PersonalBestGhost != null)
            {
                StartPlayback(PersonalBestGhost);
            }
            else
            {
                Debug.Log("GhostRecorder: No personal best available");
            }
        }

        /// <summary>
        /// Toggles ghost visibility
        /// </summary>
        public void ToggleGhostVisibility()
        {
            if (ghostObject != null)
            {
                ghostObject.SetActive(!ghostObject.activeSelf);
            }
        }

        /// <summary>
        /// Exports ghost run to JSON for sharing
        /// </summary>
        public string ExportGhostToJSON(GhostRun ghostRun)
        {
            return JsonUtility.ToJson(ghostRun, prettyPrint: true);
        }

        /// <summary>
        /// Imports ghost run from JSON
        /// </summary>
        public GhostRun ImportGhostFromJSON(string json)
        {
            return JsonUtility.FromJson<GhostRun>(json);
        }

        #endregion
    }

    /// <summary>
    /// Represents a complete ghost run
    /// </summary>
    [System.Serializable]
    public class GhostRun
    {
        public float startTime;
        public float endTime;
        public float totalDuration;
        public float finalDistance;
        public int finalScore;
        public List<GhostFrame> frames;
    }

    /// <summary>
    /// Represents a single frame of ghost data
    /// </summary>
    [System.Serializable]
    public class GhostFrame
    {
        public float timestamp;
        public Vector3 position;
        public Quaternion rotation;
        public Vector3 velocity;
        public int laneIndex;
        public bool isJumping;
        public bool isPowerUpActive;
    }
}
