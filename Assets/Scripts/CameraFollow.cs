using System.Collections;
using System.Collections.Generic;
using UnityEngine;


// Simple camera follow script
[RequireComponent(typeof(Camera))]
public class CameraFollow : MonoBehaviour
{

    [SerializeField] private Transform player; // Drag player here

    private Vector3 cameraOffset;
    private Camera thisCamera;
    private Quaternion cameraRotateStart;

    void Start()
    {
        thisCamera = GetComponent<Camera>();
        cameraOffset = thisCamera.transform.position - player.transform.position;
        cameraRotateStart = thisCamera.transform.rotation;
    }

    // Always do camera follow code last, after player has moved.
    void LateUpdate()
    {
        thisCamera.transform.position = (player.transform.forward * cameraOffset.z) +
                                        new Vector3(player.transform.position.x, 
                                        player.transform.position.y + cameraOffset.y, 
                                        player.transform.position.z);
                                                                    
        thisCamera.transform.rotation = player.transform.rotation *  cameraRotateStart;
    }
}
