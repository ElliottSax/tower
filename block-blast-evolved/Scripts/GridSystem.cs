using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Events;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Core grid system for Block Blast Evolved.
    /// Manages 8x8 grid of cells, block placement, and line clearing.
    /// </summary>
    public class GridSystem : MonoBehaviour
    {
        public static GridSystem Instance { get; private set; }

        [Header("Grid Settings")]
        [Tooltip("Grid dimensions (typically 8x8 or 10x10)")]
        public int gridWidth = 8;
        public int gridHeight = 8;

        [Tooltip("Size of each cell (world units)")]
        public float cellSize = 1f;

        [Tooltip("Spacing between cells")]
        public float cellSpacing = 0.1f;

        [Header("Prefabs")]
        [Tooltip("Cell prefab for visual representation")]
        public GameObject cellPrefab;

        [Tooltip("Block piece prefab")]
        public GameObject blockPrefab;

        [Header("Materials")]
        public Material emptyMaterial;
        public Material filledMaterial;
        public Material previewMaterial;
        public Material[] colorMaterials; // Different block colors

        [Header("Events")]
        public UnityEvent<int, int> OnCellFilled;
        public UnityEvent<int, int> OnCellCleared;
        public UnityEvent<List<Vector2Int>> OnLineCleared;
        public UnityEvent OnGridFull;

        // Grid data
        private GridCell[,] grid;
        private List<GameObject> cellObjects;

        // Public properties
        public int GridWidth => gridWidth;
        public int GridHeight => gridHeight;
        public GridCell[,] Grid => grid;

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
                Debug.LogWarning("Multiple GridSystem instances detected. Destroying duplicate.");
                Destroy(gameObject);
            }
        }

        void Start()
        {
            InitializeGrid();
            Debug.Log($"GridSystem: Initialized {gridWidth}x{gridHeight} grid");
        }

        #endregion

        #region Grid Initialization

        /// <summary>
        /// Initializes the grid data and visual representation
        /// </summary>
        void InitializeGrid()
        {
            // Initialize data structure
            grid = new GridCell[gridWidth, gridHeight];
            cellObjects = new List<GameObject>();

            // Create grid cells
            for (int x = 0; x < gridWidth; x++)
            {
                for (int y = 0; y < gridHeight; y++)
                {
                    // Initialize cell data
                    grid[x, y] = new GridCell
                    {
                        x = x,
                        y = y,
                        isEmpty = true,
                        blockType = BlockType.None,
                        colorIndex = -1
                    };

                    // Create visual cell
                    CreateCellVisual(x, y);
                }
            }

            // Center grid on screen
            CenterGrid();
        }

        /// <summary>
        /// Creates visual representation of a cell
        /// </summary>
        void CreateCellVisual(int x, int y)
        {
            Vector3 position = GetCellWorldPosition(x, y);

            GameObject cellObject;
            if (cellPrefab != null)
            {
                cellObject = Instantiate(cellPrefab, position, Quaternion.identity, transform);
            }
            else
            {
                // Fallback: Create cube
                cellObject = GameObject.CreatePrimitive(PrimitiveType.Cube);
                cellObject.transform.position = position;
                cellObject.transform.localScale = Vector3.one * cellSize;
                cellObject.transform.parent = transform;
            }

            cellObject.name = $"Cell_{x}_{y}";

            // Apply empty material
            var renderer = cellObject.GetComponent<Renderer>();
            if (renderer != null && emptyMaterial != null)
            {
                renderer.material = emptyMaterial;
            }

            cellObjects.Add(cellObject);
            grid[x, y].visualObject = cellObject;
        }

        /// <summary>
        /// Centers grid in world space
        /// </summary>
        void CenterGrid()
        {
            float totalWidth = gridWidth * (cellSize + cellSpacing);
            float totalHeight = gridHeight * (cellSize + cellSpacing);

            Vector3 offset = new Vector3(-totalWidth / 2f, -totalHeight / 2f, 0f);
            transform.position = offset;
        }

        #endregion

        #region Cell Queries

        /// <summary>
        /// Gets world position of cell
        /// </summary>
        public Vector3 GetCellWorldPosition(int x, int y)
        {
            return new Vector3(
                x * (cellSize + cellSpacing),
                y * (cellSize + cellSpacing),
                0f
            );
        }

        /// <summary>
        /// Gets grid coordinates from world position
        /// </summary>
        public Vector2Int WorldToGridPosition(Vector3 worldPos)
        {
            Vector3 localPos = worldPos - transform.position;
            int x = Mathf.RoundToInt(localPos.x / (cellSize + cellSpacing));
            int y = Mathf.RoundToInt(localPos.y / (cellSize + cellSpacing));
            return new Vector2Int(x, y);
        }

        /// <summary>
        /// Checks if coordinates are valid
        /// </summary>
        public bool IsValidPosition(int x, int y)
        {
            return x >= 0 && x < gridWidth && y >= 0 && y < gridHeight;
        }

        /// <summary>
        /// Checks if cell is empty
        /// </summary>
        public bool IsCellEmpty(int x, int y)
        {
            if (!IsValidPosition(x, y)) return false;
            return grid[x, y].isEmpty;
        }

        /// <summary>
        /// Gets cell at position
        /// </summary>
        public GridCell GetCell(int x, int y)
        {
            if (!IsValidPosition(x, y)) return null;
            return grid[x, y];
        }

        #endregion

        #region Block Placement

        /// <summary>
        /// Checks if block shape can be placed at position
        /// </summary>
        public bool CanPlaceBlock(BlockShape shape, int startX, int startY)
        {
            foreach (Vector2Int offset in shape.occupiedCells)
            {
                int x = startX + offset.x;
                int y = startY + offset.y;

                if (!IsValidPosition(x, y) || !IsCellEmpty(x, y))
                {
                    return false;
                }
            }

            return true;
        }

        /// <summary>
        /// Places block on grid
        /// </summary>
        public bool PlaceBlock(BlockShape shape, int startX, int startY, int colorIndex = 0)
        {
            if (!CanPlaceBlock(shape, startX, startY))
            {
                Debug.LogWarning($"Cannot place block at ({startX}, {startY})");
                return false;
            }

            // Place block pieces
            List<Vector2Int> placedCells = new List<Vector2Int>();

            foreach (Vector2Int offset in shape.occupiedCells)
            {
                int x = startX + offset.x;
                int y = startY + offset.y;

                // Update cell data
                grid[x, y].isEmpty = false;
                grid[x, y].blockType = shape.blockType;
                grid[x, y].colorIndex = colorIndex;

                // Update visual
                UpdateCellVisual(x, y, colorIndex);

                placedCells.Add(new Vector2Int(x, y));

                // Fire event
                OnCellFilled?.Invoke(x, y);
            }

            Debug.Log($"✅ Block placed at ({startX}, {startY}) - {placedCells.Count} cells");

            return true;
        }

        /// <summary>
        /// Updates cell visual representation
        /// </summary>
        void UpdateCellVisual(int x, int y, int colorIndex)
        {
            GridCell cell = grid[x, y];
            if (cell.visualObject == null) return;

            var renderer = cell.visualObject.GetComponent<Renderer>();
            if (renderer == null) return;

            if (cell.isEmpty)
            {
                renderer.material = emptyMaterial;
            }
            else
            {
                // Apply color material
                if (colorIndex >= 0 && colorIndex < colorMaterials.Length)
                {
                    renderer.material = colorMaterials[colorIndex];
                }
                else
                {
                    renderer.material = filledMaterial;
                }
            }
        }

        #endregion

        #region Line Clearing

        /// <summary>
        /// Checks and clears completed lines (rows and columns)
        /// </summary>
        public int CheckAndClearLines()
        {
            List<int> completedRows = new List<int>();
            List<int> completedColumns = new List<int>();

            // Check rows
            for (int y = 0; y < gridHeight; y++)
            {
                if (IsRowComplete(y))
                {
                    completedRows.Add(y);
                }
            }

            // Check columns
            for (int x = 0; x < gridWidth; x++)
            {
                if (IsColumnComplete(x))
                {
                    completedColumns.Add(x);
                }
            }

            // Clear completed lines
            int totalCleared = 0;

            foreach (int row in completedRows)
            {
                ClearRow(row);
                totalCleared++;
            }

            foreach (int column in completedColumns)
            {
                ClearColumn(column);
                totalCleared++;
            }

            if (totalCleared > 0)
            {
                Debug.Log($"🎯 Cleared {totalCleared} lines!");
            }

            return totalCleared;
        }

        /// <summary>
        /// Checks if row is complete
        /// </summary>
        bool IsRowComplete(int y)
        {
            for (int x = 0; x < gridWidth; x++)
            {
                if (grid[x, y].isEmpty)
                {
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// Checks if column is complete
        /// </summary>
        bool IsColumnComplete(int x)
        {
            for (int y = 0; y < gridHeight; y++)
            {
                if (grid[x, y].isEmpty)
                {
                    return false;
                }
            }
            return true;
        }

        /// <summary>
        /// Clears a row
        /// </summary>
        void ClearRow(int y)
        {
            List<Vector2Int> clearedCells = new List<Vector2Int>();

            for (int x = 0; x < gridWidth; x++)
            {
                grid[x, y].isEmpty = true;
                grid[x, y].blockType = BlockType.None;
                grid[x, y].colorIndex = -1;

                UpdateCellVisual(x, y, -1);
                clearedCells.Add(new Vector2Int(x, y));

                OnCellCleared?.Invoke(x, y);
            }

            OnLineCleared?.Invoke(clearedCells);
        }

        /// <summary>
        /// Clears a column
        /// </summary>
        void ClearColumn(int x)
        {
            List<Vector2Int> clearedCells = new List<Vector2Int>();

            for (int y = 0; y < gridHeight; y++)
            {
                grid[x, y].isEmpty = true;
                grid[x, y].blockType = BlockType.None;
                grid[x, y].colorIndex = -1;

                UpdateCellVisual(x, y, -1);
                clearedCells.Add(new Vector2Int(x, y));

                OnCellCleared?.Invoke(x, y);
            }

            OnLineCleared?.Invoke(clearedCells);
        }

        #endregion

        #region Grid State

        /// <summary>
        /// Checks if grid is full (game over)
        /// </summary>
        public bool IsGridFull()
        {
            int emptyCount = 0;

            for (int x = 0; x < gridWidth; x++)
            {
                for (int y = 0; y < gridHeight; y++)
                {
                    if (grid[x, y].isEmpty)
                    {
                        emptyCount++;
                    }
                }
            }

            // Consider grid "full" if less than 10% empty
            float emptyPercentage = (float)emptyCount / (gridWidth * gridHeight);
            return emptyPercentage < 0.1f;
        }

        /// <summary>
        /// Clears entire grid
        /// </summary>
        public void ClearGrid()
        {
            for (int x = 0; x < gridWidth; x++)
            {
                for (int y = 0; y < gridHeight; y++)
                {
                    grid[x, y].isEmpty = true;
                    grid[x, y].blockType = BlockType.None;
                    grid[x, y].colorIndex = -1;

                    UpdateCellVisual(x, y, -1);
                }
            }

            Debug.Log("Grid cleared");
        }

        #endregion

        #region Debug

        #if UNITY_EDITOR
        [ContextMenu("Clear Grid")]
        void DebugClearGrid()
        {
            ClearGrid();
        }

        [ContextMenu("Fill Random Cells")]
        void DebugFillRandom()
        {
            for (int i = 0; i < 20; i++)
            {
                int x = Random.Range(0, gridWidth);
                int y = Random.Range(0, gridHeight);
                int color = Random.Range(0, colorMaterials.Length);

                if (IsCellEmpty(x, y))
                {
                    grid[x, y].isEmpty = false;
                    grid[x, y].colorIndex = color;
                    UpdateCellVisual(x, y, color);
                }
            }
        }

        void OnDrawGizmos()
        {
            if (grid == null) return;

            // Draw grid lines
            Gizmos.color = Color.gray;

            for (int x = 0; x <= gridWidth; x++)
            {
                Vector3 start = GetCellWorldPosition(x, 0);
                Vector3 end = GetCellWorldPosition(x, gridHeight);
                Gizmos.DrawLine(start, end);
            }

            for (int y = 0; y <= gridHeight; y++)
            {
                Vector3 start = GetCellWorldPosition(0, y);
                Vector3 end = GetCellWorldPosition(gridWidth, y);
                Gizmos.DrawLine(start, end);
            }
        }
        #endif

        #endregion
    }

    /// <summary>
    /// Represents a single grid cell
    /// </summary>
    [System.Serializable]
    public class GridCell
    {
        public int x;
        public int y;
        public bool isEmpty = true;
        public BlockType blockType = BlockType.None;
        public int colorIndex = -1;
        public GameObject visualObject;
    }

    /// <summary>
    /// Block types
    /// </summary>
    public enum BlockType
    {
        None,
        Single,
        Line2,
        Line3,
        Line4,
        Line5,
        LShape,
        TShape,
        Square,
        ZShape
    }

    /// <summary>
    /// Defines a block shape
    /// </summary>
    [System.Serializable]
    public class BlockShape
    {
        public BlockType blockType;
        public string shapeName;
        public List<Vector2Int> occupiedCells; // Relative positions

        public static BlockShape CreateLine3()
        {
            return new BlockShape
            {
                blockType = BlockType.Line3,
                shapeName = "Line 3",
                occupiedCells = new List<Vector2Int>
                {
                    new Vector2Int(0, 0),
                    new Vector2Int(1, 0),
                    new Vector2Int(2, 0)
                }
            };
        }

        public static BlockShape CreateLShape()
        {
            return new BlockShape
            {
                blockType = BlockType.LShape,
                shapeName = "L Shape",
                occupiedCells = new List<Vector2Int>
                {
                    new Vector2Int(0, 0),
                    new Vector2Int(0, 1),
                    new Vector2Int(0, 2),
                    new Vector2Int(1, 0)
                }
            };
        }

        public static BlockShape CreateSquare()
        {
            return new BlockShape
            {
                blockType = BlockType.Square,
                shapeName = "Square",
                occupiedCells = new List<Vector2Int>
                {
                    new Vector2Int(0, 0),
                    new Vector2Int(1, 0),
                    new Vector2Int(0, 1),
                    new Vector2Int(1, 1)
                }
            };
        }
    }
}
