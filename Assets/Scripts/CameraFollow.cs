using System.Collections;
using System.Collections.Generic;
using UnityEngine;


// Simple camera follow script
// TODO replace with Cinemachine
[RequireComponent(typeof(Camera))]
public class CameraFollow : MonoBehaviour
{
    // Set in editor
    [SerializeField] private Transform player; // Drag player here
    [SerializeField] private Vector3 cameraOffset;
    [SerializeField] private float cameraTilt;

    // Cache
    private Camera thisCamera;
    private Quaternion cameraRotate;

    void Start()
    {
        thisCamera = GetComponent<Camera>();

        cameraRotate = Quaternion.AngleAxis(cameraTilt, Vector3.right);
    }

    // Always do camera follow code last, after player has moved.
    void LateUpdate()
    {
        thisCamera.transform.position = (player.transform.forward * cameraOffset.z) +
                                        new Vector3(player.transform.position.x, 
                                        player.transform.position.y + cameraOffset.y, 
                                        player.transform.position.z);
                                                                    
        thisCamera.transform.rotation = player.transform.rotation * cameraRotate;
    }
}
