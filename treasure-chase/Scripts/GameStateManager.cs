using UnityEngine;
using UnityEngine.Events;

public class GameStateManager : MonoBehaviour
{
    public static GameStateManager Instance { get; private set; }

    [Header("Game State")]
    public bool isGameActive = true;
    public bool isGameOver = false;
    public bool isPaused = false;

    [Header("Events")]
    public UnityEvent OnGameStart;
    public UnityEvent OnGameOver;
    public UnityEvent OnGamePause;
    public UnityEvent OnGameResume;

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

    void Start()
    {
        StartGame();
    }

    public void StartGame()
    {
        isGameActive = true;
        isGameOver = false;
        isPaused = false;
        Time.timeScale = 1f;
        OnGameStart?.Invoke();
        Debug.Log("Game Started!");
    }

    public void GameOver()
    {
        if (isGameOver) return; // Prevent multiple calls

        isGameActive = false;
        isGameOver = true;
        Time.timeScale = 0f; // Freeze game
        OnGameOver?.Invoke();
        Debug.Log("Game Over!");
    }

    public void PauseGame()
    {
        if (!isGameActive || isGameOver) return;

        isPaused = true;
        Time.timeScale = 0f;
        OnGamePause?.Invoke();
        Debug.Log("Game Paused");
    }

    public void ResumeGame()
    {
        if (!isPaused || isGameOver) return;

        isPaused = false;
        Time.timeScale = 1f;
        OnGameResume?.Invoke();
        Debug.Log("Game Resumed");
    }

    public void RestartGame()
    {
        Time.timeScale = 1f;
        UnityEngine.SceneManagement.SceneManager.LoadScene(
            UnityEngine.SceneManagement.SceneManager.GetActiveScene().buildIndex
        );
    }
}
