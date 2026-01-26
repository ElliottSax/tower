using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Handles block dragging, placement validation, and placement execution.
    /// Works with GridSystem to place blocks on the grid.
    /// </summary>
    public class BlockPlacer : MonoBehaviour
    {
        public static BlockPlacer Instance { get; private set; }

        [Header("Dragging Settings")]
        [Tooltip("Layer mask for raycasting to grid")]
        public LayerMask gridLayer;

        [Tooltip("Height offset when dragging block")]
        public float dragHeight = 2f;

        [Tooltip("Snap to grid when close?")]
        public bool snapToGrid = true;

        [Tooltip("Snap distance threshold")]
        public float snapThreshold = 0.5f;

        [Header("Visual Feedback")]
        [Tooltip("Valid placement color")]
        public Color validPlacementColor = Color.green;

        [Tooltip("Invalid placement color")]
        public Color invalidPlacementColor = Color.red;

        [Tooltip("Show placement preview?")]
        public bool showPreview = true;

        [Header("Events")]
        public UnityEvent<BlockShape, int, int> OnBlockPlaced;
        public UnityEvent<BlockShape> OnPlacementFailed;

        // Private fields
        private BlockShape currentBlock;
        private GameObject currentBlockObject;
        private bool isDragging = false;
        private Vector2Int targetGridPos;
        private bool isValidPlacement = false;
        private List<GameObject> previewObjects;

        // Camera reference
        private Camera mainCamera;

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
                Debug.LogWarning("Multiple BlockPlacer instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            mainCamera = Camera.main;
            previewObjects = new List<GameObject>();

            Debug.Log("BlockPlacer: Initialized");
        }

        void Update()
        {
            if (isDragging)
            {
                UpdateDrag();
            }

            // Handle placement
            if (isDragging && Input.GetMouseButtonUp(0))
            {
                TryPlaceBlock();
            }
        }

        #endregion

        #region Block Dragging

        /// <summary>
        /// Starts dragging a block
        /// </summary>
        public void StartDragging(BlockShape block, GameObject blockObject)
        {
            if (isDragging)
            {
                Debug.LogWarning("BlockPlacer: Already dragging a block!");
                return;
            }

            currentBlock = block;
            currentBlockObject = blockObject;
            isDragging = true;

            // Create preview objects
            if (showPreview)
            {
                CreatePreviewObjects();
            }

            Debug.Log($"🎮 Started dragging {block.shapeName}");
        }

        /// <summary>
        /// Updates block position during drag
        /// </summary>
        void UpdateDrag()
        {
            // Get mouse position in world
            Vector3 mousePos = GetMouseWorldPosition();

            if (currentBlockObject != null)
            {
                // Move block to mouse position (elevated)
                currentBlockObject.transform.position = mousePos + Vector3.up * dragHeight;
            }

            // Check placement validity
            UpdatePlacementPreview(mousePos);
        }

        /// <summary>
        /// Updates placement preview and validity
        /// </summary>
        void UpdatePlacementPreview(Vector3 worldPos)
        {
            if (GridSystem.Instance == null) return;

            // Convert world position to grid coordinates
            targetGridPos = GridSystem.Instance.WorldToGridPosition(worldPos);

            // Check if placement is valid
            isValidPlacement = GridSystem.Instance.CanPlaceBlock(currentBlock, targetGridPos.x, targetGridPos.y);

            // Update preview visuals
            UpdatePreviewVisuals();
        }

        /// <summary>
        /// Attempts to place the current block
        /// </summary>
        void TryPlaceBlock()
        {
            if (!isDragging) return;

            if (isValidPlacement && GridSystem.Instance != null)
            {
                // Place block on grid
                int colorIndex = Random.Range(0, 5); // Random color
                bool success = GridSystem.Instance.PlaceBlock(currentBlock, targetGridPos.x, targetGridPos.y, colorIndex);

                if (success)
                {
                    // Success feedback
                    OnBlockPlaced?.Invoke(currentBlock, targetGridPos.x, targetGridPos.y);

                    // Play sound
                    if (AudioManager.Instance != null)
                    {
                        AudioManager.Instance.PlaySFX("block_place");
                    }

                    // Destroy block object
                    if (currentBlockObject != null)
                    {
                        Destroy(currentBlockObject);
                    }

                    // Check for line clears
                    if (GridSystem.Instance != null)
                    {
                        int linesCleared = GridSystem.Instance.CheckAndClearLines();

                        if (linesCleared > 0)
                        {
                            // Award points for line clears
                            var scoreManager = FindObjectOfType<ScoreManager>();
                            if (scoreManager != null)
                            {
                                scoreManager.AddLineBonus(linesCleared);
                            }
                        }
                    }

                    Debug.Log($"✅ Block placed successfully at ({targetGridPos.x}, {targetGridPos.y})");
                }
            }
            else
            {
                // Invalid placement
                OnPlacementFailed?.Invoke(currentBlock);

                // Return block to original position (or destroy)
                if (currentBlockObject != null)
                {
                    // Snap back animation could go here
                    Destroy(currentBlockObject);
                }

                // Play error sound
                if (AudioManager.Instance != null)
                {
                    AudioManager.Instance.PlaySFX("error");
                }

                Debug.LogWarning("❌ Invalid block placement");
            }

            // Clean up
            StopDragging();
        }

        /// <summary>
        /// Stops dragging
        /// </summary>
        void StopDragging()
        {
            isDragging = false;
            currentBlock = null;
            currentBlockObject = null;
            isValidPlacement = false;

            // Clear preview objects
            ClearPreviewObjects();
        }

        #endregion

        #region Preview System

        /// <summary>
        /// Creates preview objects for block placement
        /// </summary>
        void CreatePreviewObjects()
        {
            if (currentBlock == null || GridSystem.Instance == null) return;

            ClearPreviewObjects();

            foreach (Vector2Int offset in currentBlock.occupiedCells)
            {
                GameObject preview = GameObject.CreatePrimitive(PrimitiveType.Cube);
                preview.name = "Preview";
                preview.transform.localScale = Vector3.one * GridSystem.Instance.cellSize * 0.9f;

                // Make semi-transparent
                var renderer = preview.GetComponent<Renderer>();
                if (renderer != null)
                {
                    Material previewMat = new Material(Shader.Find("Standard"));
                    previewMat.SetFloat("_Mode", 3); // Transparent
                    previewMat.color = new Color(1, 1, 1, 0.3f);
                    renderer.material = previewMat;
                }

                // Disable collider
                var collider = preview.GetComponent<Collider>();
                if (collider != null)
                {
                    collider.enabled = false;
                }

                previewObjects.Add(preview);
            }
        }

        /// <summary>
        /// Updates preview object positions and colors
        /// </summary>
        void UpdatePreviewVisuals()
        {
            if (previewObjects.Count == 0 || currentBlock == null || GridSystem.Instance == null)
                return;

            Color previewColor = isValidPlacement ? validPlacementColor : invalidPlacementColor;

            for (int i = 0; i < currentBlock.occupiedCells.Count && i < previewObjects.Count; i++)
            {
                Vector2Int offset = currentBlock.occupiedCells[i];
                int gridX = targetGridPos.x + offset.x;
                int gridY = targetGridPos.y + offset.y;

                // Position preview
                Vector3 worldPos = GridSystem.Instance.GetCellWorldPosition(gridX, gridY);
                previewObjects[i].transform.position = worldPos;

                // Update color
                var renderer = previewObjects[i].GetComponent<Renderer>();
                if (renderer != null)
                {
                    Color color = previewColor;
                    color.a = 0.5f;
                    renderer.material.color = color;
                }

                // Show/hide based on validity
                bool isValidCell = GridSystem.Instance.IsValidPosition(gridX, gridY);
                previewObjects[i].SetActive(isValidCell);
            }
        }

        /// <summary>
        /// Clears preview objects
        /// </summary>
        void ClearPreviewObjects()
        {
            foreach (GameObject preview in previewObjects)
            {
                if (preview != null)
                {
                    Destroy(preview);
                }
            }
            previewObjects.Clear();
        }

        #endregion

        #region Utility

        /// <summary>
        /// Gets mouse position in world space
        /// </summary>
        Vector3 GetMouseWorldPosition()
        {
            if (mainCamera == null) return Vector3.zero;

            Vector3 mousePos = Input.mousePosition;
            mousePos.z = 10f; // Distance from camera

            return mainCamera.ScreenToWorldPoint(mousePos);
        }

        #endregion

        #region Public Methods

        /// <summary>
        /// Checks if currently dragging
        /// </summary>
        public bool IsDragging()
        {
            return isDragging;
        }

        /// <summary>
        /// Cancels current drag
        /// </summary>
        public void CancelDrag()
        {
            if (isDragging)
            {
                if (currentBlockObject != null)
                {
                    Destroy(currentBlockObject);
                }
                StopDragging();

                Debug.Log("Drag cancelled");
            }
        }

        #endregion
    }
}
