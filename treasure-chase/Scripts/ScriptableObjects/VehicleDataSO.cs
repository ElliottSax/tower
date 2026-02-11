using UnityEngine;
using TreasureChase.Progression;

namespace TreasureChase.Data
{
    /// <summary>
    /// ScriptableObject for Vehicle Data.
    /// Create via: Assets > Create > Treasure Chase > Vehicle Data
    /// </summary>
    [CreateAssetMenu(fileName = "Vehicle_", menuName = "Treasure Chase/Vehicle Data", order = 1)]
    public class VehicleDataSO : ScriptableObject
    {
        public VehicleData data;

        /// <summary>
        /// Initialize with default values
        /// </summary>
        void OnValidate()
        {
            if (string.IsNullOrEmpty(data.vehicleName))
            {
                data.vehicleName = name.Replace("Vehicle_", "").Replace("_", " ");
            }
        }
    }
}
