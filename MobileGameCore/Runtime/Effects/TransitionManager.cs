using UnityEngine;
using UnityEngine.SceneManagement;
using System.Collections;
using UnityEngine.UI;

namespace MobileGameCore.Effects
{
    /// <summary>
    /// Manages scene transitions with visual effects (fades, wipes, zooms).
    /// Provides smooth loading screens and professional scene changes.
    ///
    /// USAGE:
    /// TransitionManager.Instance.LoadScene("GameScene");
    /// TransitionManager.Instance.LoadScene(1, TransitionManager.TransitionType.FadeToWhite);
    /// TransitionManager.Instance.FadeOut(0.5f);
    /// </summary>
    public class TransitionManager : MonoBehaviour
    {
        public static TransitionManager Instance { get; private set; }

        [Header("Transition Settings")]
        [SerializeField] private TransitionType defaultTransition = TransitionType.Fade;
        [SerializeField] private float defaultDuration = 0.5f;
        [SerializeField] private Color transitionColor = Color.black;

        [Header("Loading Screen")]
        [SerializeField] private bool showLoadingScreen = true;
        [SerializeField] private float minLoadingTime = 1f;

        [Header("Canvas Setup")]
        [SerializeField] private Canvas transitionCanvas;
        [SerializeField] private Image fadeImage;
        [SerializeField] private Text loadingText;
        [SerializeField] private Image loadingSpinner;

        private bool isTransitioning = false;
        private float transitionProgress = 0f;

        public enum TransitionType
        {
            Fade,
            FadeToWhite,
            Wipe,
            ZoomIn,
            ZoomOut,
            Circle,
            Pixelate
        }

        // Events
        public System.Action OnTransitionStarted;
        public System.Action OnTransitionCompleted;

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
                SetupTransitionCanvas();
            }
            else
            {
                Destroy(gameObject);
            }
        }

        void SetupTransitionCanvas()
        {
            // Create canvas if not assigned
            if (transitionCanvas == null)
            {
                GameObject canvasObj = new GameObject("TransitionCanvas");
                canvasObj.transform.SetParent(transform);

                transitionCanvas = canvasObj.AddComponent<Canvas>();
                transitionCanvas.renderMode = RenderMode.ScreenSpaceOverlay;
                transitionCanvas.sortingOrder = 9999; // Render on top of everything

                CanvasScaler scaler = canvasObj.AddComponent<CanvasScaler>();
                scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
                scaler.referenceResolution = new Vector2(1920, 1080);

                canvasObj.AddComponent<GraphicRaycaster>();
            }

            // Create fade image if not assigned
            if (fadeImage == null)
            {
                GameObject fadeObj = new GameObject("FadeImage");
                fadeObj.transform.SetParent(transitionCanvas.transform);

                fadeImage = fadeObj.AddComponent<Image>();
                fadeImage.color = new Color(0, 0, 0, 0); // Start transparent

                RectTransform rt = fadeImage.rectTransform;
                rt.anchorMin = Vector2.zero;
                rt.anchorMax = Vector2.one;
                rt.offsetMin = Vector2.zero;
                rt.offsetMax = Vector2.zero;
            }

            // Create loading UI
            CreateLoadingUI();

            // Hide initially
            transitionCanvas.gameObject.SetActive(false);
        }

        void CreateLoadingUI()
        {
            // Loading text
            if (loadingText == null)
            {
                GameObject textObj = new GameObject("LoadingText");
                textObj.transform.SetParent(transitionCanvas.transform);

                loadingText = textObj.AddComponent<Text>();
                loadingText.text = "Loading...";
                loadingText.font = Resources.GetBuiltinResource<Font>("Arial.ttf");
                loadingText.fontSize = 48;
                loadingText.color = Color.white;
                loadingText.alignment = TextAnchor.MiddleCenter;

                RectTransform rt = loadingText.rectTransform;
                rt.anchorMin = new Vector2(0.5f, 0.3f);
                rt.anchorMax = new Vector2(0.5f, 0.3f);
                rt.sizeDelta = new Vector2(800, 100);
            }

            // Loading spinner
            if (loadingSpinner == null)
            {
                GameObject spinnerObj = new GameObject("LoadingSpinner");
                spinnerObj.transform.SetParent(transitionCanvas.transform);

                loadingSpinner = spinnerObj.AddComponent<Image>();
                loadingSpinner.color = Color.white;

                // Create simple spinner texture
                Texture2D spinnerTex = CreateSpinnerTexture();
                loadingSpinner.sprite = Sprite.Create(spinnerTex,
                    new Rect(0, 0, spinnerTex.width, spinnerTex.height),
                    new Vector2(0.5f, 0.5f));

                RectTransform rt = loadingSpinner.rectTransform;
                rt.anchorMin = new Vector2(0.5f, 0.5f);
                rt.anchorMax = new Vector2(0.5f, 0.5f);
                rt.sizeDelta = new Vector2(100, 100);
            }

            loadingText.gameObject.SetActive(false);
            loadingSpinner.gameObject.SetActive(false);
        }

        Texture2D CreateSpinnerTexture()
        {
            int size = 64;
            Texture2D tex = new Texture2D(size, size);

            Color clear = new Color(1, 1, 1, 0);
            Vector2 center = new Vector2(size / 2, size / 2);
            float radius = size / 2 - 2;

            for (int y = 0; y < size; y++)
            {
                for (int x = 0; x < size; x++)
                {
                    Vector2 pos = new Vector2(x, y);
                    float dist = Vector2.Distance(pos, center);

                    if (dist < radius && dist > radius - 8)
                    {
                        // Create arc (3/4 circle)
                        float angle = Mathf.Atan2(y - center.y, x - center.x) * Mathf.Rad2Deg;
                        if (angle < 0) angle += 360;

                        if (angle < 270)
                        {
                            float alpha = 1f - (angle / 270f);
                            tex.SetPixel(x, y, new Color(1, 1, 1, alpha));
                        }
                        else
                        {
                            tex.SetPixel(x, y, clear);
                        }
                    }
                    else
                    {
                        tex.SetPixel(x, y, clear);
                    }
                }
            }

            tex.Apply();
            return tex;
        }

        void Update()
        {
            // Rotate loading spinner
            if (loadingSpinner != null && loadingSpinner.gameObject.activeSelf)
            {
                loadingSpinner.transform.Rotate(0, 0, -180f * Time.deltaTime);
            }
        }

        #region Public API

        /// <summary>
        /// Load scene with transition
        /// </summary>
        public void LoadScene(string sceneName, TransitionType transition = TransitionType.Fade, float duration = -1f)
        {
            if (isTransitioning)
            {
                UnityEngine.Debug.LogWarning("[TransitionManager] Transition already in progress!");
                return;
            }

            if (duration < 0)
                duration = defaultDuration;

            StartCoroutine(LoadSceneCoroutine(sceneName, transition, duration));
        }

        /// <summary>
        /// Load scene by index with transition
        /// </summary>
        public void LoadScene(int sceneIndex, TransitionType transition = TransitionType.Fade, float duration = -1f)
        {
            if (isTransitioning)
            {
                UnityEngine.Debug.LogWarning("[TransitionManager] Transition already in progress!");
                return;
            }

            if (duration < 0)
                duration = defaultDuration;

            StartCoroutine(LoadSceneCoroutine(sceneIndex, transition, duration));
        }

        /// <summary>
        /// Reload current scene
        /// </summary>
        public void ReloadCurrentScene(TransitionType transition = TransitionType.Fade)
        {
            LoadScene(SceneManager.GetActiveScene().buildIndex, transition);
        }

        /// <summary>
        /// Simple fade in (no scene load)
        /// </summary>
        public void FadeIn(float duration = -1f)
        {
            if (duration < 0)
                duration = defaultDuration;

            StartCoroutine(FadeCoroutine(1f, 0f, duration));
        }

        /// <summary>
        /// Simple fade out (no scene load)
        /// </summary>
        public void FadeOut(float duration = -1f)
        {
            if (duration < 0)
                duration = defaultDuration;

            StartCoroutine(FadeCoroutine(0f, 1f, duration));
        }

        #endregion

        #region Coroutines

        IEnumerator LoadSceneCoroutine(string sceneName, TransitionType transition, float duration)
        {
            isTransitioning = true;
            transitionCanvas.gameObject.SetActive(true);
            OnTransitionStarted?.Invoke();

            // Transition out
            yield return StartCoroutine(TransitionOut(transition, duration * 0.5f));

            // Show loading screen
            if (showLoadingScreen)
            {
                loadingText.gameObject.SetActive(true);
                loadingSpinner.gameObject.SetActive(true);
            }

            // Load scene asynchronously
            float startTime = Time.realtimeSinceStartup;
            AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneName);
            asyncLoad.allowSceneActivation = false;

            // Wait for load to complete
            while (!asyncLoad.isDone)
            {
                transitionProgress = Mathf.Clamp01(asyncLoad.progress / 0.9f);

                // Wait for minimum loading time
                if (asyncLoad.progress >= 0.9f && Time.realtimeSinceStartup - startTime >= minLoadingTime)
                {
                    asyncLoad.allowSceneActivation = true;
                }

                yield return null;
            }

            // Hide loading screen
            loadingText.gameObject.SetActive(false);
            loadingSpinner.gameObject.SetActive(false);

            // Small delay after load
            yield return new WaitForSeconds(0.1f);

            // Transition in
            yield return StartCoroutine(TransitionIn(transition, duration * 0.5f));

            transitionCanvas.gameObject.SetActive(false);
            isTransitioning = false;
            OnTransitionCompleted?.Invoke();
        }

        IEnumerator LoadSceneCoroutine(int sceneIndex, TransitionType transition, float duration)
        {
            isTransitioning = true;
            transitionCanvas.gameObject.SetActive(true);
            OnTransitionStarted?.Invoke();

            // Transition out
            yield return StartCoroutine(TransitionOut(transition, duration * 0.5f));

            // Show loading screen
            if (showLoadingScreen)
            {
                loadingText.gameObject.SetActive(true);
                loadingSpinner.gameObject.SetActive(true);
            }

            // Load scene asynchronously
            float startTime = Time.realtimeSinceStartup;
            AsyncOperation asyncLoad = SceneManager.LoadSceneAsync(sceneIndex);
            asyncLoad.allowSceneActivation = false;

            // Wait for load to complete
            while (!asyncLoad.isDone)
            {
                transitionProgress = Mathf.Clamp01(asyncLoad.progress / 0.9f);

                // Wait for minimum loading time
                if (asyncLoad.progress >= 0.9f && Time.realtimeSinceStartup - startTime >= minLoadingTime)
                {
                    asyncLoad.allowSceneActivation = true;
                }

                yield return null;
            }

            // Hide loading screen
            loadingText.gameObject.SetActive(false);
            loadingSpinner.gameObject.SetActive(false);

            // Small delay after load
            yield return new WaitForSeconds(0.1f);

            // Transition in
            yield return StartCoroutine(TransitionIn(transition, duration * 0.5f));

            transitionCanvas.gameObject.SetActive(false);
            isTransitioning = false;
            OnTransitionCompleted?.Invoke();
        }

        IEnumerator TransitionOut(TransitionType transition, float duration)
        {
            switch (transition)
            {
                case TransitionType.Fade:
                    yield return StartCoroutine(FadeCoroutine(0f, 1f, duration));
                    break;

                case TransitionType.FadeToWhite:
                    fadeImage.color = Color.white;
                    yield return StartCoroutine(FadeCoroutine(0f, 1f, duration));
                    break;

                case TransitionType.ZoomOut:
                    yield return StartCoroutine(ZoomTransition(1f, 0f, duration));
                    break;

                default:
                    yield return StartCoroutine(FadeCoroutine(0f, 1f, duration));
                    break;
            }
        }

        IEnumerator TransitionIn(TransitionType transition, float duration)
        {
            switch (transition)
            {
                case TransitionType.Fade:
                case TransitionType.FadeToWhite:
                    yield return StartCoroutine(FadeCoroutine(1f, 0f, duration));
                    fadeImage.color = transitionColor; // Reset to black
                    break;

                case TransitionType.ZoomOut:
                    yield return StartCoroutine(ZoomTransition(0f, 1f, duration));
                    break;

                default:
                    yield return StartCoroutine(FadeCoroutine(1f, 0f, duration));
                    break;
            }
        }

        IEnumerator FadeCoroutine(float startAlpha, float endAlpha, float duration)
        {
            float elapsed = 0f;
            Color color = fadeImage.color;

            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                float t = elapsed / duration;

                color.a = Mathf.Lerp(startAlpha, endAlpha, t);
                fadeImage.color = color;

                yield return null;
            }

            color.a = endAlpha;
            fadeImage.color = color;
        }

        IEnumerator ZoomTransition(float startScale, float endScale, float duration)
        {
            float elapsed = 0f;
            Color color = fadeImage.color;

            while (elapsed < duration)
            {
                elapsed += Time.unscaledDeltaTime;
                float t = elapsed / duration;

                float scale = Mathf.Lerp(startScale, endScale, t);
                fadeImage.transform.localScale = Vector3.one * scale;

                color.a = 1f - Mathf.Abs(scale - 0.5f) * 2f; // Fade based on scale
                fadeImage.color = color;

                yield return null;
            }

            fadeImage.transform.localScale = Vector3.one;
        }

        #endregion

        #region Utilities

        /// <summary>
        /// Check if currently transitioning
        /// </summary>
        public bool IsTransitioning()
        {
            return isTransitioning;
        }

        /// <summary>
        /// Get current transition progress (0-1)
        /// </summary>
        public float GetTransitionProgress()
        {
            return transitionProgress;
        }

        /// <summary>
        /// Set loading text message
        /// </summary>
        public void SetLoadingText(string text)
        {
            if (loadingText != null)
            {
                loadingText.text = text;
            }
        }

        #endregion
    }
}
