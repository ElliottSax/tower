using UnityEngine;

public enum PowerUpType
{
    Magnet,
    Shield,
    SpeedBoost,
    DoubleCoins
}

public abstract class PowerUpBase : MonoBehaviour
{
    [Header("Power-Up Settings")]
    public PowerUpType powerUpType;
    public float duration = 10f;

    [Header("Visual")]
    public float rotationSpeed = 90f;

    protected bool isActive = false;
    protected float remainingTime = 0f;
    protected GameObject player;

    void Update()
    {
        // Rotate power-up
        transform.Rotate(Vector3.up * rotationSpeed * Time.deltaTime);

        // If active, countdown
        if (isActive)
        {
            remainingTime -= Time.deltaTime;

            if (remainingTime <= 0f)
            {
                DeactivatePowerUp();
            }
            else
            {
                UpdatePowerUp();
            }
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player") && !isActive)
        {
            player = other.gameObject;
            ActivatePowerUp();
        }
    }

    public void ActivatePowerUp()
    {
        isActive = true;
        remainingTime = duration;

        // Hide visual
        GetComponent<MeshRenderer>().enabled = false;
        GetComponent<Collider>().enabled = false;

        // Override in subclass
        OnActivate();

        Debug.Log(powerUpType + " activated for " + duration + " seconds!");
    }

    public void DeactivatePowerUp()
    {
        isActive = false;

        // Override in subclass
        OnDeactivate();

        Debug.Log(powerUpType + " deactivated!");

        // Destroy power-up
        Destroy(gameObject);
    }

    // Override these in subclasses
    protected abstract void OnActivate();
    protected abstract void OnDeactivate();
    protected virtual void UpdatePowerUp() { }
}
