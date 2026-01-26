using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    [Header("Target")]
    public Transform target;

    [Header("Follow Settings")]
    public Vector3 offset = new Vector3(0, 5, -10);
    public float smoothSpeed = 5f;

    [Header("Look At")]
    public bool lookAtTarget = true;
    public Vector3 lookOffset = Vector3.zero;

    void LateUpdate()
    {
        if (target == null) return;

        // Calculate desired position
        Vector3 desiredPosition = target.position + offset;

        // Smoothly move to desired position
        Vector3 smoothedPosition = Vector3.Lerp(transform.position, desiredPosition, smoothSpeed * Time.deltaTime);
        transform.position = smoothedPosition;

        // Look at target
        if (lookAtTarget)
        {
            Vector3 lookPosition = target.position + lookOffset;
            transform.LookAt(lookPosition);
        }
    }
}
