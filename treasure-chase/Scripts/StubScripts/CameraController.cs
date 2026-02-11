using UnityEngine;
using System.Collections;

/// <summary>
/// STUB CameraController for Day 1 setup.
/// Replace with real CameraController from Treasure Multiplier later.
/// </summary>
public class CameraController : MonoBehaviour
{
    public static CameraController Instance { get; private set; }

    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
        }
        else
        {
            Destroy(gameObject);
        }
    }

    /// <summary>
    /// Light camera shake
    /// </summary>
    public void ShakeLight()
    {
        Debug.Log("[STUB] CameraController.ShakeLight");
        // TODO: Implement camera shake
    }

    /// <summary>
    /// Medium camera shake
    /// </summary>
    public void ShakeMedium()
    {
        Debug.Log("[STUB] CameraController.ShakeMedium");
        // TODO: Implement camera shake
    }

    /// <summary>
    /// Heavy camera shake
    /// </summary>
    public void ShakeHeavy()
    {
        Debug.Log("[STUB] CameraController.ShakeHeavy");
        // TODO: Implement camera shake
    }

    /// <summary>
    /// Custom camera shake
    /// </summary>
    public void Shake(float intensity, float duration)
    {
        Debug.Log($"[STUB] CameraController.Shake: intensity={intensity}, duration={duration}");
        // TODO: Implement camera shake
    }

    /// <summary>
    /// Flash screen with color
    /// </summary>
    public void FlashColor(Color color, float duration)
    {
        Debug.Log($"[STUB] CameraController.FlashColor: {color} for {duration}s");
        // TODO: Implement screen flash
    }

    /// <summary>
    /// Fade to black
    /// </summary>
    public void FadeToBlack(float duration)
    {
        Debug.Log($"[STUB] CameraController.FadeToBlack: {duration}s");
        // TODO: Implement fade
    }

    /// <summary>
    /// Fade from black
    /// </summary>
    public void FadeFromBlack(float duration)
    {
        Debug.Log($"[STUB] CameraController.FadeFromBlack: {duration}s");
        // TODO: Implement fade
    }
}
