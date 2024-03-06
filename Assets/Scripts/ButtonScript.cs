using System.Runtime.InteropServices;
using UnityEngine;
using TMPro;

public class ButtonScript : MonoBehaviour
{

    [SerializeField]
    TextMeshProUGUI m_StatusText;
    [SerializeField]
    TextMeshProUGUI m_MonitorText;
    [DllImport("__Internal")]
    private static extern void _startTracking();
    [DllImport("__Internal")]
    private static extern void _stopTracking();
    [DllImport("__Internal")]
    private static extern double _getCPUUsage();
    [DllImport("__Internal")]
    private static extern double _getRAMUsage();
    [DllImport("__Internal")]
    private static extern double _getFPSAverage();

    public void StartTracking()
    {
        m_StatusText.text = "Status: Start Tracking...";
        _startTracking();
    }

    public void StopTracking()
    {
        m_StatusText.text = "Status: Stop Tracking";
        _stopTracking();
        var cpuPerformance = _getCPUUsage();
        var gpuPerformance = _getFPSAverage();
        var ramPerformance = _getRAMUsage();
        m_MonitorText.text = $"CPU usage: {cpuPerformance.ToString("N2")}%\nFPS: {gpuPerformance.ToString("N2")}\nRAM usage increased: {ramPerformance / 1024 / 1024} MB";
    }
}
