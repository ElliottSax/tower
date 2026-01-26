using UnityEngine;

public class CoinBehavior : MonoBehaviour
{
    [Header("Rotation")]
    public float rotationSpeed = 180f;
    public Vector3 rotationAxis = Vector3.up;

    [Header("Bobbing")]
    public bool enableBobbing = true;
    public float bobbingSpeed = 2f;
    public float bobbingAmount = 0.3f;

    [Header("Value")]
    public int coinValue = 10;

    [Header("Effects")]
    public GameObject collectionEffectPrefab;

    private Vector3 startPosition;
    private float timeOffset;

    void Start()
    {
        startPosition = transform.position;
        timeOffset = Random.Range(0f, 100f);
    }

    void Update()
    {
        // Rotate coin
        transform.Rotate(rotationAxis * rotationSpeed * Time.deltaTime);

        // Bob up and down
        if (enableBobbing)
        {
            float newY = startPosition.y + Mathf.Sin((Time.time + timeOffset) * bobbingSpeed) * bobbingAmount;
            transform.position = new Vector3(transform.position.x, newY, transform.position.z);
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Player"))
        {
            Collect();
        }
    }

    void Collect()
    {
        // Notify score manager
        if (EndlessScoreManager.Instance != null)
        {
            EndlessScoreManager.Instance.AddCoins(coinValue);
        }
        else if (FindObjectOfType<SimpleHUDController>() != null)
        {
            FindObjectOfType<SimpleHUDController>().AddCoins(coinValue);
        }

        // Spawn collection effect
        if (collectionEffectPrefab != null)
        {
            Instantiate(collectionEffectPrefab, transform.position, Quaternion.identity);
        }

        Debug.Log("Coin collected! +" + coinValue);

        // Destroy coin
        Destroy(gameObject);
    }
}
