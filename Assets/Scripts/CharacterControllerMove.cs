using UnityEngine;
using System.Collections;

/// <summary>
/// Implements player character control system and animation.
/// </summary>
public class CharacterControllerMove : MonoBehaviour
{
    [Header("Speed Settings")]
    [SerializeField] private float speed = 6.0f;
    [SerializeField] private float jumpSpeed = 8.0f;
    [SerializeField] private float gravity = 20.0f;
    [SerializeField] private float rotateSpeed = 10.0f; 

    // Controls
    private float turnMove;
    private float forwardMove;
    private bool jump;

    // Cache
    private CharacterController characterController;
    private Animator animator;

    //Movement
    private float jumpY;
    Vector3 moveDirection = Vector3.zero;

    void Start()
    {
        characterController = GetComponent<CharacterController>();
        animator = GetComponent<Animator>();
    }

    private void FixedUpdate()
    {
        

        animator.SetBool("Grounded", characterController.isGrounded);

        if (characterController.isGrounded) // We are grounded, so recalculate move direction
        {
            transform.Rotate(0.0f, turnMove * rotateSpeed * Time.fixedDeltaTime, 0.0f);

            moveDirection = transform.forward * forwardMove  * speed;

            animator.SetFloat("MoveSpeed", forwardMove);
            animator.SetFloat("TurnSpeed", Mathf.Abs(turnMove));

            if (jump)
            {
                jumpY = jumpSpeed;
            }
        }

        // Apply gravity. Gravity is multiplied by deltaTime twice (once here, and once below
        // when the moveDirection is multiplied by deltaTime). This is because gravity should be applied
        // as an acceleration (ms^-2)
        jumpY -= gravity * Time.fixedDeltaTime;

        moveDirection = new Vector3(moveDirection.x, jumpY, moveDirection.z);

        // Move the controller
        characterController.Move(moveDirection * Time.fixedDeltaTime);
    }

    // Control input
    void Update()
    {
        turnMove = Input.GetAxis("Horizontal");
        forwardMove = Input.GetAxis("Vertical");
        jump = Input.GetButton("Jump");
    }

}