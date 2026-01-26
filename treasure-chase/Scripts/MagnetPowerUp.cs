using UnityEngine;

public class MagnetPowerUp : PowerUpBase
{
    [Header("Magnet Settings")]
    public float magnetRadius = 10f;
    public float magnetStrength = 15f;

    private SphereCollider magnetCollider;

    protected override void OnActivate()
    {
        // Create magnet collider on player
        if (player != null)
        {
            magnetCollider = player.AddComponent<SphereCollider>();
            magnetCollider.isTrigger = true;
            magnetCollider.radius = magnetRadius;
        }
    }

    protected override void UpdatePowerUp()
    {
        // Attract nearby coins
        Collider[] nearbyColliders = Physics.OverlapSphere(player.transform.position, magnetRadius);

        foreach (Collider col in nearbyColliders)
        {
            if (col.CompareTag("Coin"))
            {
                // Pull coin toward player
                Vector3 direction = (player.transform.position - col.transform.position).normalized;
                col.transform.position += direction * magnetStrength * Time.deltaTime;
            }
        }
    }

    protected override void OnDeactivate()
    {
        // Remove magnet collider
        if (magnetCollider != null)
        {
            Destroy(magnetCollider);
        }
    }
}
