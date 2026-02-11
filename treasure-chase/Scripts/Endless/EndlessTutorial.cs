using UnityEngine;
using UnityEngine.Events;
using System.Collections;
using System.Collections.Generic;

namespace TreasureChase.Endless
{
    /// <summary>
    /// Interactive tutorial system for endless runner mode.
    /// Teaches core mechanics: movement, jumping, treasures, obstacles, power-ups.
    /// </summary>
    public class EndlessTutorial : MonoBehaviour
    {
        public static EndlessTutorial Instance { get; private set; }

        [Header("Tutorial Settings")]
        [Tooltip("Show tutorial on first launch?")]
        public bool showOnFirstLaunch = true;

        [Tooltip("Allow skipping tutorial?")]
        public bool allowSkip = true;

        [Header("Tutorial Steps")]
        [Tooltip("All tutorial steps in sequence")]
        public TutorialStep[] tutorialSteps;

        [Header("UI References")]
        [Tooltip("Tutorial UI canvas")]
        public GameObject tutorialCanvas;

        [Tooltip("Tutorial text display")]
        public UnityEngine.UI.Text tutorialText;

        [Tooltip("Highlight overlay for UI elements")]
        public GameObject highlightOverlay;

        [Header("Events")]
        public UnityEvent OnTutorialStarted;
        public UnityEvent OnTutorialCompleted;
        public UnityEvent OnTutorialSkipped;

        // Private fields
        private bool isTutorialActive = false;
        private int currentStepIndex = 0;
        private TutorialStep currentStep;
        private bool stepCompleted = false;

        // Public properties
        public bool IsTutorialActive => isTutorialActive;
        public bool HasCompletedTutorial => PlayerPrefs.GetInt("tutorial_completed", 0) == 1;

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
                Debug.LogWarning("Multiple EndlessTutorial instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            // Hide tutorial UI initially
            if (tutorialCanvas != null)
            {
                tutorialCanvas.SetActive(false);
            }

            // Check if tutorial should start
            if (showOnFirstLaunch && !HasCompletedTutorial)
            {
                StartCoroutine(StartTutorialDelayed(1f));
            }

            Debug.Log($"EndlessTutorial: Initialized (Completed: {HasCompletedTutorial})");
        }

        void Update()
        {
            if (!isTutorialActive) return;

            // Check step completion
            if (!stepCompleted && currentStep != null)
            {
                CheckStepCompletion();
            }

            // Check for skip input
            if (allowSkip && Input.GetKeyDown(KeyCode.Escape))
            {
                SkipTutorial();
            }
        }

        #endregion

        #region Tutorial Flow

        /// <summary>
        /// Starts the tutorial after delay
        /// </summary>
        IEnumerator StartTutorialDelayed(float delay)
        {
            yield return new WaitForSeconds(delay);
            StartTutorial();
        }

        /// <summary>
        /// Starts the tutorial sequence
        /// </summary>
        public void StartTutorial()
        {
            if (isTutorialActive)
            {
                Debug.LogWarning("EndlessTutorial: Tutorial already active!");
                return;
            }

            isTutorialActive = true;
            currentStepIndex = 0;

            // Show tutorial UI
            if (tutorialCanvas != null)
            {
                tutorialCanvas.SetActive(true);
            }

            // Pause game
            Time.timeScale = 0f;

            OnTutorialStarted?.Invoke();

            Debug.Log("📚 Tutorial Started");

            // Start first step
            StartStep(0);
        }

        /// <summary>
        /// Starts a specific tutorial step
        /// </summary>
        void StartStep(int stepIndex)
        {
            if (stepIndex >= tutorialSteps.Length)
            {
                CompleteTutorial();
                return;
            }

            currentStepIndex = stepIndex;
            currentStep = tutorialSteps[stepIndex];
            stepCompleted = false;

            // Display step instructions
            DisplayStepInstructions();

            // Execute step action
            ExecuteStepAction();

            Debug.Log($"📖 Tutorial Step {stepIndex + 1}/{tutorialSteps.Length}: {currentStep.stepName}");
        }

        /// <summary>
        /// Displays step instructions to player
        /// </summary>
        void DisplayStepInstructions()
        {
            if (tutorialText != null)
            {
                tutorialText.text = currentStep.instructionText;
            }

            // Show highlight if needed
            if (highlightOverlay != null && !string.IsNullOrEmpty(currentStep.highlightObjectName))
            {
                HighlightObject(currentStep.highlightObjectName);
            }
            else if (highlightOverlay != null)
            {
                highlightOverlay.SetActive(false);
            }
        }

        /// <summary>
        /// Executes step-specific action
        /// </summary>
        void ExecuteStepAction()
        {
            switch (currentStep.stepType)
            {
                case TutorialStepType.Wait:
                    StartCoroutine(WaitAndProceed(currentStep.waitDuration));
                    break;

                case TutorialStepType.TapAnywhere:
                    // Wait for tap/click
                    break;

                case TutorialStepType.SwipeLeft:
                case TutorialStepType.SwipeRight:
                    // Wait for swipe
                    break;

                case TutorialStepType.Jump:
                    // Wait for jump
                    break;

                case TutorialStepType.CollectTreasure:
                    // Spawn tutorial treasure
                    SpawnTutorialTreasure();
                    break;

                case TutorialStepType.AvoidObstacle:
                    // Spawn tutorial obstacle
                    SpawnTutorialObstacle();
                    break;

                case TutorialStepType.UsePowerUp:
                    // Spawn tutorial power-up
                    SpawnTutorialPowerUp();
                    break;
            }
        }

        /// <summary>
        /// Checks if current step is completed
        /// </summary>
        void CheckStepCompletion()
        {
            bool completed = false;

            switch (currentStep.stepType)
            {
                case TutorialStepType.TapAnywhere:
                    completed = Input.GetMouseButtonDown(0) || Input.touchCount > 0;
                    break;

                case TutorialStepType.SwipeLeft:
                    completed = CheckSwipeLeft();
                    break;

                case TutorialStepType.SwipeRight:
                    completed = CheckSwipeRight();
                    break;

                case TutorialStepType.Jump:
                    completed = Input.GetKeyDown(KeyCode.Space) || Input.GetMouseButtonDown(0);
                    break;

                case TutorialStepType.CollectTreasure:
                    // Will be marked complete by treasure collection event
                    break;

                case TutorialStepType.AvoidObstacle:
                    // Will be marked complete by passing obstacle
                    break;

                case TutorialStepType.UsePowerUp:
                    // Will be marked complete by power-up activation
                    break;
            }

            if (completed)
            {
                CompleteStep();
            }
        }

        /// <summary>
        /// Completes current step and moves to next
        /// </summary>
        public void CompleteStep()
        {
            if (stepCompleted) return;

            stepCompleted = true;

            Debug.Log($"✅ Tutorial Step Completed: {currentStep.stepName}");

            // Visual feedback
            ShowStepCompletionFeedback();

            // Move to next step after delay
            StartCoroutine(ProceedToNextStep(currentStep.delayBeforeNext));
        }

        /// <summary>
        /// Proceeds to next step after delay
        /// </summary>
        IEnumerator ProceedToNextStep(float delay)
        {
            yield return new WaitForSecondsRealtime(delay);
            StartStep(currentStepIndex + 1);
        }

        /// <summary>
        /// Waits for duration then proceeds
        /// </summary>
        IEnumerator WaitAndProceed(float duration)
        {
            yield return new WaitForSecondsRealtime(duration);
            CompleteStep();
        }

        /// <summary>
        /// Completes the entire tutorial
        /// </summary>
        void CompleteTutorial()
        {
            isTutorialActive = false;

            // Mark as completed
            PlayerPrefs.SetInt("tutorial_completed", 1);
            PlayerPrefs.Save();

            // Hide tutorial UI
            if (tutorialCanvas != null)
            {
                tutorialCanvas.SetActive(false);
            }

            // Resume game
            Time.timeScale = 1f;

            OnTutorialCompleted?.Invoke();

            Debug.Log("🎓 Tutorial Completed!");

            // Award completion bonus
            var economyManager = FindObjectOfType<EconomyManager>();
            if (economyManager != null)
            {
                economyManager.AddCoins(100);
            }
        }

        /// <summary>
        /// Skips tutorial
        /// </summary>
        public void SkipTutorial()
        {
            if (!allowSkip) return;

            isTutorialActive = false;

            // Mark as completed
            PlayerPrefs.SetInt("tutorial_completed", 1);
            PlayerPrefs.Save();

            // Hide tutorial UI
            if (tutorialCanvas != null)
            {
                tutorialCanvas.SetActive(false);
            }

            // Resume game
            Time.timeScale = 1f;

            OnTutorialSkipped?.Invoke();

            Debug.Log("⏭️ Tutorial Skipped");
        }

        #endregion

        #region Tutorial Actions

        /// <summary>
        /// Spawns a tutorial treasure
        /// </summary>
        void SpawnTutorialTreasure()
        {
            var playerController = FindObjectOfType<PlayerController>();
            if (playerController == null) return;

            // Spawn treasure ahead of player
            Vector3 spawnPos = playerController.transform.position + Vector3.forward * 20f;

            // Use treasure from existing game (or spawn simple prefab)
            var treasurePrefab = Resources.Load<GameObject>("Prefabs/Treasure");
            if (treasurePrefab != null)
            {
                GameObject treasure = Instantiate(treasurePrefab, spawnPos, Quaternion.identity);
                treasure.tag = "Collectible";

                // Subscribe to collection event
                var collectible = treasure.GetComponent<Collectible>();
                if (collectible != null)
                {
                    collectible.OnCollected.AddListener(() => CompleteStep());
                }
            }
        }

        /// <summary>
        /// Spawns a tutorial obstacle
        /// </summary>
        void SpawnTutorialObstacle()
        {
            var playerController = FindObjectOfType<PlayerController>();
            if (playerController == null) return;

            // Spawn obstacle ahead of player
            Vector3 spawnPos = playerController.transform.position + Vector3.forward * 30f;

            var obstaclePrefab = Resources.Load<GameObject>("Prefabs/Obstacle");
            if (obstaclePrefab != null)
            {
                GameObject obstacle = Instantiate(obstaclePrefab, spawnPos, Quaternion.identity);
                obstacle.tag = "Obstacle";

                // Complete step when player passes it
                StartCoroutine(CheckObstaclePass(obstacle.transform));
            }
        }

        /// <summary>
        /// Spawns a tutorial power-up
        /// </summary>
        void SpawnTutorialPowerUp()
        {
            var playerController = FindObjectOfType<PlayerController>();
            if (playerController == null) return;

            Vector3 spawnPos = playerController.transform.position + Vector3.forward * 20f;

            var powerUpPrefab = Resources.Load<GameObject>("Prefabs/PowerUp");
            if (powerUpPrefab != null)
            {
                GameObject powerUp = Instantiate(powerUpPrefab, spawnPos, Quaternion.identity);
                powerUp.tag = "PowerUp";
            }
        }

        /// <summary>
        /// Checks if player passed obstacle
        /// </summary>
        IEnumerator CheckObstaclePass(Transform obstacleTransform)
        {
            var playerController = FindObjectOfType<PlayerController>();
            if (playerController == null) yield break;

            while (playerController.transform.position.z < obstacleTransform.position.z)
            {
                yield return null;
            }

            // Player passed obstacle
            CompleteStep();
        }

        /// <summary>
        /// Highlights a game object
        /// </summary>
        void HighlightObject(string objectName)
        {
            GameObject targetObject = GameObject.Find(objectName);
            if (targetObject != null && highlightOverlay != null)
            {
                highlightOverlay.SetActive(true);
                highlightOverlay.transform.position = targetObject.transform.position;
            }
        }

        /// <summary>
        /// Shows step completion feedback
        /// </summary>
        void ShowStepCompletionFeedback()
        {
            // Play success sound
            if (AudioManager.Instance != null)
            {
                AudioManager.Instance.PlaySFX("ui_success");
            }

            // Flash green
            if (CameraController.Instance != null)
            {
                CameraController.Instance.FlashColor(Color.green, 0.3f);
            }
        }

        #endregion

        #region Input Detection

        private Vector2 swipeStartPos;
        private bool isSwiping = false;

        /// <summary>
        /// Checks for left swipe
        /// </summary>
        bool CheckSwipeLeft()
        {
            if (Input.GetMouseButtonDown(0))
            {
                swipeStartPos = Input.mousePosition;
                isSwiping = true;
            }

            if (Input.GetMouseButtonUp(0) && isSwiping)
            {
                Vector2 swipeEndPos = Input.mousePosition;
                Vector2 swipeDelta = swipeEndPos - swipeStartPos;

                if (swipeDelta.x < -50f) // Swipe left
                {
                    isSwiping = false;
                    return true;
                }
                isSwiping = false;
            }

            return false;
        }

        /// <summary>
        /// Checks for right swipe
        /// </summary>
        bool CheckSwipeRight()
        {
            if (Input.GetMouseButtonDown(0))
            {
                swipeStartPos = Input.mousePosition;
                isSwiping = true;
            }

            if (Input.GetMouseButtonUp(0) && isSwiping)
            {
                Vector2 swipeEndPos = Input.mousePosition;
                Vector2 swipeDelta = swipeEndPos - swipeStartPos;

                if (swipeDelta.x > 50f) // Swipe right
                {
                    isSwiping = false;
                    return true;
                }
                isSwiping = false;
            }

            return false;
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Resets tutorial progress
        /// </summary>
        public void ResetTutorial()
        {
            PlayerPrefs.SetInt("tutorial_completed", 0);
            PlayerPrefs.Save();
            Debug.Log("Tutorial progress reset");
        }

        #endregion
    }

    /// <summary>
    /// Tutorial step configuration
    /// </summary>
    [System.Serializable]
    public class TutorialStep
    {
        public string stepName = "Introduction";
        public TutorialStepType stepType = TutorialStepType.TapAnywhere;
        [TextArea(3, 5)]
        public string instructionText = "Tap anywhere to continue";
        public string highlightObjectName = ""; // Optional object to highlight
        public float waitDuration = 2f; // For Wait step type
        public float delayBeforeNext = 0.5f; // Delay before next step
    }

    /// <summary>
    /// Tutorial step types
    /// </summary>
    public enum TutorialStepType
    {
        Wait,              // Just wait for duration
        TapAnywhere,       // Wait for tap/click
        SwipeLeft,         // Wait for left swipe
        SwipeRight,        // Wait for right swipe
        Jump,              // Wait for jump input
        CollectTreasure,   // Wait for treasure collection
        AvoidObstacle,     // Wait for passing obstacle
        UsePowerUp         // Wait for power-up use
    }
}
