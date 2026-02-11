using UnityEngine;

public class ShieldPowerUp : PowerUpBase
{
    private GameObject shieldVisual;
    private PlayerController playerController;

    protected override void OnActivate()
    {
        if (player != null)
        {
            // Disable collision with obstacles
            playerController = player.GetComponent<PlayerController>();
            if (playerController != null)
            {
                playerController.isShielded = true;
            }

            // Create shield visual
            CreateDefaultShield();
        }
    }

    void CreateDefaultShield()
    {
        GameObject shield = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        shield.transform.SetParent(player.transform);
        shield.transform.localPosition = Vector3.zero;
        shield.transform.localScale = Vector3.one * 2.5f;

        // Remove collider (visual only)
        Destroy(shield.GetComponent<Collider>());

        // Make transparent blue
        Renderer renderer = shield.GetComponent<Renderer>();
        Material mat = new Material(Shader.Find("Standard"));
        mat.color = new Color(0, 0.5f, 1f, 0.3f); // Blue transparent
        mat.SetFloat("_Mode", 3); // Transparent mode
        mat.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
        mat.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
        mat.SetInt("_ZWrite", 0);
        mat.DisableKeyword("_ALPHATEST_ON");
        mat.EnableKeyword("_ALPHABLEND_ON");
        mat.DisableKeyword("_ALPHAPREMULTIPLY_ON");
        mat.renderQueue = 3000;
        renderer.material = mat;

        shieldVisual = shield;
    }

    protected override void OnDeactivate()
    {
        // Remove shield
        if (playerController != null)
        {
            playerController.isShielded = false;
        }

        if (shieldVisual != null)
        {
            Destroy(shieldVisual);
        }
    }
}
