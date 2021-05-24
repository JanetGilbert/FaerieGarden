using System.Collections;
using System.Collections.Generic;
using UnityEngine;


// Simple camera follow script
public class CameraFollow : MonoBehaviour
{

    [SerializeField] private Transform player; // Drag player here
    private Vector3 cameraOffset;

    void Start()
    {
        cameraOffset = Camera.main.transform.position - player.transform.position;
    }

    // Always do camera follow code last, after player has moved.
    void LateUpdate()
    {
        Camera.main.transform.position = player.transform.position + cameraOffset;
    }
}
