using UnityEngine;

namespace BlockBlastEvolved
{
    /// <summary>
    /// Handles saving and loading player data using PlayerPrefs.
    /// Stub implementation - extend with file-based or cloud save as needed.
    /// </summary>
    public class SaveSystem : MonoBehaviour
    {
        public static SaveSystem Instance { get; private set; }

        void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else
            {
                Destroy(gameObject);
            }
        }

        /// <summary>
        /// Sets a string value.
        /// </summary>
        public void SetString(string key, string value)
        {
            PlayerPrefs.SetString(key, value);
        }

        /// <summary>
        /// Gets a string value with default.
        /// </summary>
        public string GetString(string key, string defaultValue = "")
        {
            return PlayerPrefs.GetString(key, defaultValue);
        }

        /// <summary>
        /// Sets an integer value.
        /// </summary>
        public void SetInt(string key, int value)
        {
            PlayerPrefs.SetInt(key, value);
        }

        /// <summary>
        /// Gets an integer value with default.
        /// </summary>
        public int GetInt(string key, int defaultValue = 0)
        {
            return PlayerPrefs.GetInt(key, defaultValue);
        }

        /// <summary>
        /// Sets a float value.
        /// </summary>
        public void SetFloat(string key, float value)
        {
            PlayerPrefs.SetFloat(key, value);
        }

        /// <summary>
        /// Gets a float value with default.
        /// </summary>
        public float GetFloat(string key, float defaultValue = 0f)
        {
            return PlayerPrefs.GetFloat(key, defaultValue);
        }

        /// <summary>
        /// Saves all pending changes to disk.
        /// </summary>
        public void Save()
        {
            PlayerPrefs.Save();
            Debug.Log("SaveSystem: Data saved");
        }

        /// <summary>
        /// Deletes all saved data.
        /// </summary>
        public void DeleteAll()
        {
            PlayerPrefs.DeleteAll();
            Debug.Log("SaveSystem: All data deleted");
        }

        /// <summary>
        /// Checks if a key exists.
        /// </summary>
        public bool HasKey(string key)
        {
            return PlayerPrefs.HasKey(key);
        }
    }
}
