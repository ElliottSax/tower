using UnityEngine;

public class PlayerController : MonoBehaviour
{
    [Header("Movement Settings")]
    public float forwardSpeed = 10f;
    public float laneSpeed = 12f;
    public float laneDistance = 3f;

    [Header("Jump Settings")]
    public float jumpForce = 8f;
    public LayerMask groundLayer;
    public Transform groundCheck;
    public float groundCheckRadius = 0.2f;

    [Header("Collision")]
    public LayerMask obstacleLayer;
    public GameObject deathParticles;

    [Header("Shield")]
    public bool isShielded = false;

    [Header("Audio (Optional)")]
    public AudioClip laneSwitchSound;
    public AudioClip jumpSound;
    public AudioClip deathSound;

    // Private variables
    private int currentLane = 1; // 0=left, 1=center, 2=right
    private Vector3 targetPosition;
    private Rigidbody rb;
    private bool isGrounded = false;
    private AudioSource audioSource;

    // Lane switching animation
    private bool isSwitchingLane = false;
    private float laneSwitchProgress = 0f;
    private Vector3 startLanePosition;
    private Vector3 targetLanePosition;
    public AnimationCurve laneSwitchCurve = AnimationCurve.EaseInOut(0, 0, 1, 1);

    void Start()
    {
        rb = GetComponent<Rigidbody>();

        // Add AudioSource if doesn't exist
        audioSource = GetComponent<AudioSource>();
        if (audioSource == null)
            audioSource = gameObject.AddComponent<AudioSource>();

        // Create ground check if doesn't exist
        if (groundCheck == null)
        {
            GameObject groundCheckObj = new GameObject("GroundCheck");
            groundCheckObj.transform.SetParent(transform);
            groundCheckObj.transform.localPosition = new Vector3(0, -0.5f, 0);
            groundCheck = groundCheckObj.transform;
        }
    }

    void Update()
    {
        // Don't process input if game is over or paused
        if (GameStateManager.Instance != null && !GameStateManager.Instance.isGameActive)
            return;

        // Check if grounded
        isGrounded = Physics.CheckSphere(groundCheck.position, groundCheckRadius, groundLayer);

        // Move forward automatically
        transform.Translate(Vector3.forward * forwardSpeed * Time.deltaTime);

        // Jump input
        if (Input.GetKeyDown(KeyCode.Space) && isGrounded)
        {
            Jump();
        }

        // Lane switching input
        if (Input.GetKeyDown(KeyCode.LeftArrow) && currentLane > 0 && !isSwitchingLane)
        {
            StartLaneSwitch(currentLane - 1);
        }
        if (Input.GetKeyDown(KeyCode.RightArrow) && currentLane < 2 && !isSwitchingLane)
        {
            StartLaneSwitch(currentLane + 1);
        }

        // Execute lane switch animation
        if (isSwitchingLane)
        {
            laneSwitchProgress += laneSpeed * Time.deltaTime;

            if (laneSwitchProgress >= 1f)
            {
                laneSwitchProgress = 1f;
                isSwitchingLane = false;
            }

            float curveValue = laneSwitchCurve.Evaluate(laneSwitchProgress);
            Vector3 newPos = Vector3.Lerp(startLanePosition, targetLanePosition, curveValue);
            newPos.y = transform.position.y;
            newPos.z = transform.position.z;
            transform.position = newPos;
        }
    }

    void StartLaneSwitch(int targetLane)
    {
        currentLane = targetLane;
        startLanePosition = transform.position;
        targetLanePosition = new Vector3((currentLane - 1) * laneDistance, transform.position.y, transform.position.z);
        laneSwitchProgress = 0f;
        isSwitchingLane = true;

        // Play sound
        if (audioSource != null && laneSwitchSound != null)
            audioSource.PlayOneShot(laneSwitchSound);
    }

    void Jump()
    {
        if (rb != null)
        {
            rb.velocity = new Vector3(rb.velocity.x, 0, rb.velocity.z);
            rb.AddForce(Vector3.up * jumpForce, ForceMode.Impulse);
            Debug.Log("Jump!");

            // Play sound
            if (audioSource != null && jumpSound != null)
                audioSource.PlayOneShot(jumpSound);
        }
    }

    void OnTriggerEnter(Collider other)
    {
        if (other.CompareTag("Obstacle"))
        {
            if (isShielded)
            {
                // Shield protects - destroy obstacle instead
                Destroy(other.gameObject);
                Debug.Log("Shield protected you!");
            }
            else
            {
                Die();
            }
        }
    }

    void Die()
    {
        Debug.Log("Player Hit Obstacle!");

        // Play death sound
        if (audioSource != null && deathSound != null)
            audioSource.PlayOneShot(deathSound);

        // Screen shake
        if (CameraShake.Instance != null)
        {
            CameraShake.Instance.TriggerShake(0.5f, 0.3f);
        }

        // Spawn death effect
        if (deathParticles != null)
        {
            Instantiate(deathParticles, transform.position, Quaternion.identity);
        }

        // Trigger game over
        if (GameStateManager.Instance != null)
        {
            GameStateManager.Instance.GameOver();
        }

        // Disable player controls
        enabled = false;
    }

    // Visualize ground check in editor
    void OnDrawGizmosSelected()
    {
        if (groundCheck != null)
        {
            Gizmos.color = Color.yellow;
            Gizmos.DrawWireSphere(groundCheck.position, groundCheckRadius);
        }
    }
}
