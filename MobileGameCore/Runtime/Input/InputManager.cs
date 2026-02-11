using UnityEngine;
using UnityEngine.InputSystem;

namespace MobileGameCore.Input
{
    /// <summary>
    /// Handles touch/tilt/swipe input for mobile games.
    /// Uses Unity's new Input System for better mobile support.
    /// Provides multiple input modes that users can switch between.
    ///
    /// FEATURES:
    /// - Virtual Joystick (Unity Input System)
    /// - Tilt Controls (accelerometer)
    /// - Swipe Controls (touch)
    /// - Keyboard fallback for editor testing
    /// - Settings persistence
    ///
    /// USAGE:
    /// Vector2 move = InputManager.Instance.MoveInput;
    /// InputManager.Instance.SetInputMode(InputManager.InputMode.Tilt);
    /// </summary>
    public class InputManager : MonoBehaviour
    {
        public static InputManager Instance { get; private set; }

        [Header("Input Mode")]
        [SerializeField] private InputMode inputMode = InputMode.VirtualJoystick;

        [Header("Virtual Joystick")]
        [SerializeField] private GameObject joystickUI;

        [Header("Tilt Settings")]
        [SerializeField, Range(0.01f, 0.5f)] private float tiltDeadZone = 0.1f;
        [SerializeField, Range(0.5f, 3f)] private float tiltSensitivity = 1.5f;

        [Header("Swipe Settings")]
        [SerializeField, Range(10f, 200f)] private float swipeThreshold = 50f;

        private PlayerInput playerInput;
        private InputAction moveAction;
        private Vector2 currentMoveInput;
        private Vector2 swipeStartPos;
        private bool isSwipeActive = false;

        public enum InputMode
        {
            VirtualJoystick,
            Tilt,
            Swipe
        }

        public Vector2 MoveInput => currentMoveInput;
        public InputMode CurrentInputMode => inputMode;

        // Events
        public System.Action<InputMode> OnInputModeChanged;

        void Awake()
        {
            // Singleton
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
                return;
            }

            LoadSavedInputMode();
            SetupInput();
        }

        void LoadSavedInputMode()
        {
            if (PlayerPrefs.HasKey("InputMode"))
            {
                int savedMode = PlayerPrefs.GetInt("InputMode", 0);
                if (System.Enum.IsDefined(typeof(InputMode), savedMode))
                {
                    inputMode = (InputMode)savedMode;
                    Debug.Log($"[InputManager] Loaded saved input mode: {inputMode}");
                }
            }
        }

        void SetupInput()
        {
            playerInput = GetComponent<PlayerInput>();
            if (playerInput == null)
            {
                Debug.LogWarning("[InputManager] PlayerInput component missing! Add PlayerInput component for virtual joystick support.");
                // Not fatal - tilt and swipe can still work
            }
            else
            {
                moveAction = playerInput.actions["Move"];
                if (moveAction == null)
                {
                    Debug.LogError("[InputManager] 'Move' action not found in PlayerInput! Check Input Actions asset.");
                }
            }

            // Show/hide joystick based on mode
            UpdateJoystickVisibility();
        }

        void UpdateJoystickVisibility()
        {
            if (joystickUI != null)
            {
                joystickUI.SetActive(inputMode == InputMode.VirtualJoystick);
            }
        }

        void Update()
        {
            switch (inputMode)
            {
                case InputMode.VirtualJoystick:
                    HandleVirtualJoystickInput();
                    break;

                case InputMode.Tilt:
                    HandleTiltInput();
                    break;

                case InputMode.Swipe:
                    HandleSwipeInput();
                    break;
            }

            // Clamp input to valid range
            currentMoveInput = Vector2.ClampMagnitude(currentMoveInput, 1f);
        }

        void HandleVirtualJoystickInput()
        {
            if (moveAction != null)
            {
                currentMoveInput = moveAction.ReadValue<Vector2>();
            }
            else
            {
                // Fallback: keyboard input for testing in editor
                #if UNITY_EDITOR
                float horizontal = UnityEngine.Input.GetAxis("Horizontal");
                float vertical = UnityEngine.Input.GetAxis("Vertical");
                currentMoveInput = new Vector2(horizontal, vertical);
                #else
                currentMoveInput = Vector2.zero;
                #endif
            }
        }

        void HandleTiltInput()
        {
            // Accelerometer-based input
            Vector3 tilt = UnityEngine.Input.acceleration;

            // Apply sensitivity
            currentMoveInput = new Vector2(tilt.x * tiltSensitivity, tilt.y * tiltSensitivity);

            // Dead zone
            if (currentMoveInput.magnitude < tiltDeadZone)
                currentMoveInput = Vector2.zero;

            // Fallback for editor testing
            #if UNITY_EDITOR
            if (currentMoveInput.magnitude < 0.01f)
            {
                float horizontal = UnityEngine.Input.GetAxis("Horizontal");
                float vertical = UnityEngine.Input.GetAxis("Vertical");
                currentMoveInput = new Vector2(horizontal, vertical);
            }
            #endif
        }

        void HandleSwipeInput()
        {
            // Touch-based swipe detection
            if (UnityEngine.Input.touchCount > 0)
            {
                Touch touch = UnityEngine.Input.GetTouch(0);

                switch (touch.phase)
                {
                    case TouchPhase.Began:
                        swipeStartPos = touch.position;
                        isSwipeActive = true;
                        break;

                    case TouchPhase.Moved:
                    case TouchPhase.Stationary:
                        if (isSwipeActive)
                        {
                            Vector2 swipeDelta = touch.position - swipeStartPos;

                            // Normalize based on screen size and threshold
                            float screenFactor = Mathf.Min(Screen.width, Screen.height);
                            Vector2 normalizedSwipe = swipeDelta / (screenFactor * 0.5f);

                            // Apply threshold
                            if (swipeDelta.magnitude > swipeThreshold)
                            {
                                currentMoveInput = Vector2.ClampMagnitude(normalizedSwipe, 1f);
                            }
                            else
                            {
                                currentMoveInput = Vector2.zero;
                            }
                        }
                        break;

                    case TouchPhase.Ended:
                    case TouchPhase.Canceled:
                        isSwipeActive = false;
                        currentMoveInput = Vector2.zero;
                        break;
                }
            }
            else
            {
                // No touch - zero input
                currentMoveInput = Vector2.zero;
                isSwipeActive = false;

                // Fallback for editor testing
                #if UNITY_EDITOR
                float horizontal = UnityEngine.Input.GetAxis("Horizontal");
                float vertical = UnityEngine.Input.GetAxis("Vertical");
                currentMoveInput = new Vector2(horizontal, vertical);
                #endif
            }
        }

        #region Public API

        /// <summary>
        /// Change input mode at runtime (e.g., from settings menu)
        /// </summary>
        public void SetInputMode(InputMode mode)
        {
            if (!System.Enum.IsDefined(typeof(InputMode), mode))
            {
                Debug.LogError($"[InputManager] Invalid input mode: {mode}");
                return;
            }

            inputMode = mode;
            PlayerPrefs.SetInt("InputMode", (int)mode);
            PlayerPrefs.Save();

            UpdateJoystickVisibility();

            // Reset current input when switching modes
            currentMoveInput = Vector2.zero;
            isSwipeActive = false;

            Debug.Log($"[InputManager] Input mode changed to: {mode}");

            OnInputModeChanged?.Invoke(mode);

            // Track analytics if available
            try
            {
                var analyticsType = System.Type.GetType("MobileGameCore.AnalyticsManager");
                if (analyticsType != null)
                {
                    var instanceProp = analyticsType.GetProperty("Instance");
                    if (instanceProp != null)
                    {
                        var instance = instanceProp.GetValue(null);
                        if (instance != null)
                        {
                            var trackEventMethod = analyticsType.GetMethod("TrackEvent");
                            var dict = new System.Collections.Generic.Dictionary<string, object>
                            {
                                { "mode", mode.ToString() }
                            };
                            trackEventMethod?.Invoke(instance, new object[] { "input_mode_changed", dict });
                        }
                    }
                }
            }
            catch { /* Analytics not available */ }
        }

        /// <summary>
        /// Get localized display name for input mode
        /// </summary>
        public string GetInputModeName(InputMode mode)
        {
            switch (mode)
            {
                case InputMode.VirtualJoystick: return "Virtual Joystick";
                case InputMode.Tilt: return "Tilt Controls";
                case InputMode.Swipe: return "Swipe Controls";
                default: return "Unknown";
            }
        }

        /// <summary>
        /// Set joystick UI reference (for runtime setup)
        /// </summary>
        public void SetJoystickUI(GameObject joystick)
        {
            joystickUI = joystick;
            UpdateJoystickVisibility();
        }

        /// <summary>
        /// Get current raw input value
        /// </summary>
        public Vector2 GetRawInput()
        {
            return currentMoveInput;
        }

        /// <summary>
        /// Check if input is active (magnitude > 0)
        /// </summary>
        public bool HasInput()
        {
            return currentMoveInput.magnitude > 0.01f;
        }

        #endregion

        #if UNITY_EDITOR
        void OnValidate()
        {
            // Validate settings in editor
            tiltDeadZone = Mathf.Clamp(tiltDeadZone, 0.01f, 0.5f);
            tiltSensitivity = Mathf.Clamp(tiltSensitivity, 0.5f, 3f);
            swipeThreshold = Mathf.Clamp(swipeThreshold, 10f, 200f);
        }
        #endif
    }
}
