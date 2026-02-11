using UnityEngine;
using System.Collections.Generic;

namespace MobileGameCore.ProceduralGeneration
{
    /// <summary>
    /// Abstract base class for procedural mesh generation.
    /// Provides utilities for creating 3D geometry programmatically without asset files.
    ///
    /// USAGE:
    /// 1. Inherit from this class
    /// 2. Override GenerateMesh()
    /// 3. Use AddQuad(), AddTriangle(), CreateBox(), CreateCylinder() to build geometry
    /// 4. Call ApplyMesh() when done
    ///
    /// EXAMPLE:
    /// public class ProceduralCrate : ProceduralMeshGenerator
    /// {
    ///     protected override void GenerateMesh()
    ///     {
    ///         CreateBox(Vector3.zero, Vector3.one, Color.white);
    ///         ApplyMesh();
    ///     }
    /// }
    /// </summary>
    public abstract class ProceduralMeshGenerator : MonoBehaviour
    {
        [Header("Mesh Settings")]
        [SerializeField] protected Material meshMaterial;
        [SerializeField] protected bool generateCollider = true;
        [SerializeField] protected bool recalculateNormals = true;
        [SerializeField] protected bool optimizeMesh = true;

        protected Mesh mesh;
        protected MeshFilter meshFilter;
        protected MeshRenderer meshRenderer;
        protected MeshCollider meshCollider;

        // Mesh building data
        protected List<Vector3> vertices = new List<Vector3>();
        protected List<int> triangles = new List<int>();
        protected List<Color> colors = new List<Color>();

        protected virtual void Awake()
        {
            SetupComponents();
        }

        protected virtual void Start()
        {
            GenerateMesh();
        }

        /// <summary>
        /// Setup required Unity components
        /// </summary>
        protected virtual void SetupComponents()
        {
            // Get or create MeshFilter
            meshFilter = GetComponent<MeshFilter>();
            if (meshFilter == null)
            {
                meshFilter = gameObject.AddComponent<MeshFilter>();
            }

            // Get or create MeshRenderer
            meshRenderer = GetComponent<MeshRenderer>();
            if (meshRenderer == null)
            {
                meshRenderer = gameObject.AddComponent<MeshRenderer>();
            }

            // Set material
            if (meshMaterial != null)
            {
                meshRenderer.material = meshMaterial;
            }

            // Get or create MeshCollider if needed
            if (generateCollider)
            {
                meshCollider = GetComponent<MeshCollider>();
                if (meshCollider == null)
                {
                    meshCollider = gameObject.AddComponent<MeshCollider>();
                }
            }

            // Create mesh
            mesh = new Mesh();
            mesh.name = $"{gameObject.name}_ProceduralMesh";
            meshFilter.mesh = mesh;
        }

        /// <summary>
        /// Override this method to generate your custom mesh
        /// </summary>
        protected abstract void GenerateMesh();

        /// <summary>
        /// Clear all mesh data
        /// </summary>
        protected void ClearMesh()
        {
            vertices.Clear();
            triangles.Clear();
            colors.Clear();

            if (mesh != null)
            {
                mesh.Clear();
            }
        }

        /// <summary>
        /// Apply mesh data to the mesh object
        /// </summary>
        protected void ApplyMesh()
        {
            if (mesh == null)
            {
                Debug.LogError("[ProceduralMeshGenerator] Mesh is null!");
                return;
            }

            mesh.Clear();
            mesh.SetVertices(vertices);
            mesh.SetTriangles(triangles, 0);
            mesh.SetColors(colors);

            if (recalculateNormals)
            {
                mesh.RecalculateNormals();
            }

            mesh.RecalculateBounds();

            if (optimizeMesh)
            {
                mesh.Optimize();
            }

            // Update collider
            if (generateCollider && meshCollider != null)
            {
                meshCollider.sharedMesh = mesh;
            }
        }

        #region Mesh Building Utilities

        /// <summary>
        /// Add a quad (4-sided polygon) to the mesh
        /// </summary>
        protected void AddQuad(Vector3 v0, Vector3 v1, Vector3 v2, Vector3 v3, Color color)
        {
            int vertexIndex = vertices.Count;

            // Add vertices
            vertices.Add(v0);
            vertices.Add(v1);
            vertices.Add(v2);
            vertices.Add(v3);

            // Add triangles (two triangles make a quad)
            triangles.Add(vertexIndex);
            triangles.Add(vertexIndex + 1);
            triangles.Add(vertexIndex + 2);

            triangles.Add(vertexIndex);
            triangles.Add(vertexIndex + 2);
            triangles.Add(vertexIndex + 3);

            // Add colors
            colors.Add(color);
            colors.Add(color);
            colors.Add(color);
            colors.Add(color);
        }

        /// <summary>
        /// Add a triangle to the mesh
        /// </summary>
        protected void AddTriangle(Vector3 v0, Vector3 v1, Vector3 v2, Color color)
        {
            int vertexIndex = vertices.Count;

            // Add vertices
            vertices.Add(v0);
            vertices.Add(v1);
            vertices.Add(v2);

            // Add triangle
            triangles.Add(vertexIndex);
            triangles.Add(vertexIndex + 1);
            triangles.Add(vertexIndex + 2);

            // Add colors
            colors.Add(color);
            colors.Add(color);
            colors.Add(color);
        }

        /// <summary>
        /// Create a box mesh
        /// </summary>
        protected void CreateBox(Vector3 center, Vector3 size, Color color)
        {
            Vector3 halfSize = size * 0.5f;

            // Front face
            AddQuad(
                center + new Vector3(-halfSize.x, -halfSize.y, halfSize.z),
                center + new Vector3(halfSize.x, -halfSize.y, halfSize.z),
                center + new Vector3(halfSize.x, halfSize.y, halfSize.z),
                center + new Vector3(-halfSize.x, halfSize.y, halfSize.z),
                color
            );

            // Back face
            AddQuad(
                center + new Vector3(halfSize.x, -halfSize.y, -halfSize.z),
                center + new Vector3(-halfSize.x, -halfSize.y, -halfSize.z),
                center + new Vector3(-halfSize.x, halfSize.y, -halfSize.z),
                center + new Vector3(halfSize.x, halfSize.y, -halfSize.z),
                color
            );

            // Left face
            AddQuad(
                center + new Vector3(-halfSize.x, -halfSize.y, -halfSize.z),
                center + new Vector3(-halfSize.x, -halfSize.y, halfSize.z),
                center + new Vector3(-halfSize.x, halfSize.y, halfSize.z),
                center + new Vector3(-halfSize.x, halfSize.y, -halfSize.z),
                color
            );

            // Right face
            AddQuad(
                center + new Vector3(halfSize.x, -halfSize.y, halfSize.z),
                center + new Vector3(halfSize.x, -halfSize.y, -halfSize.z),
                center + new Vector3(halfSize.x, halfSize.y, -halfSize.z),
                center + new Vector3(halfSize.x, halfSize.y, halfSize.z),
                color
            );

            // Top face
            AddQuad(
                center + new Vector3(-halfSize.x, halfSize.y, halfSize.z),
                center + new Vector3(halfSize.x, halfSize.y, halfSize.z),
                center + new Vector3(halfSize.x, halfSize.y, -halfSize.z),
                center + new Vector3(-halfSize.x, halfSize.y, -halfSize.z),
                color
            );

            // Bottom face
            AddQuad(
                center + new Vector3(-halfSize.x, -halfSize.y, -halfSize.z),
                center + new Vector3(halfSize.x, -halfSize.y, -halfSize.z),
                center + new Vector3(halfSize.x, -halfSize.y, halfSize.z),
                center + new Vector3(-halfSize.x, -halfSize.y, halfSize.z),
                color
            );
        }

        /// <summary>
        /// Create a cylinder mesh
        /// </summary>
        protected void CreateCylinder(Vector3 center, float radius, float height, int segments, Color color)
        {
            float angleStep = 360f / segments;
            float halfHeight = height * 0.5f;

            // Side faces
            for (int i = 0; i < segments; i++)
            {
                float angle1 = i * angleStep * Mathf.Deg2Rad;
                float angle2 = (i + 1) * angleStep * Mathf.Deg2Rad;

                Vector3 bottom1 = center + new Vector3(Mathf.Cos(angle1) * radius, -halfHeight, Mathf.Sin(angle1) * radius);
                Vector3 bottom2 = center + new Vector3(Mathf.Cos(angle2) * radius, -halfHeight, Mathf.Sin(angle2) * radius);
                Vector3 top1 = center + new Vector3(Mathf.Cos(angle1) * radius, halfHeight, Mathf.Sin(angle1) * radius);
                Vector3 top2 = center + new Vector3(Mathf.Cos(angle2) * radius, halfHeight, Mathf.Sin(angle2) * radius);

                AddQuad(bottom1, bottom2, top2, top1, color);
            }

            // Top and bottom caps
            for (int i = 0; i < segments; i++)
            {
                float angle1 = i * angleStep * Mathf.Deg2Rad;
                float angle2 = (i + 1) * angleStep * Mathf.Deg2Rad;

                // Bottom cap
                Vector3 bottom1 = center + new Vector3(Mathf.Cos(angle1) * radius, -halfHeight, Mathf.Sin(angle1) * radius);
                Vector3 bottom2 = center + new Vector3(Mathf.Cos(angle2) * radius, -halfHeight, Mathf.Sin(angle2) * radius);
                AddTriangle(center + Vector3.down * halfHeight, bottom2, bottom1, color);

                // Top cap
                Vector3 top1 = center + new Vector3(Mathf.Cos(angle1) * radius, halfHeight, Mathf.Sin(angle1) * radius);
                Vector3 top2 = center + new Vector3(Mathf.Cos(angle2) * radius, halfHeight, Mathf.Sin(angle2) * radius);
                AddTriangle(center + Vector3.up * halfHeight, top1, top2, color);
            }
        }

        #endregion

        #if UNITY_EDITOR
        [ContextMenu("Regenerate Mesh")]
        public void RegenerateMesh()
        {
            GenerateMesh();
        }
        #endif
    }
}
