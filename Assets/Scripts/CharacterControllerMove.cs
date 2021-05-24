using UnityEngine;
using System.Collections;



public class CharacterControllerMove : MonoBehaviour
{
    CharacterController characterController;

    public float speed = 6.0f;
    public float jumpSpeed = 8.0f;
    public float gravity = 20.0f;

    private Vector3 moveDirection = Vector3.zero;

    public Animator animator;

    private float xMove;
    private float yMove;
    bool jump;

    void Start()
    {
        characterController = GetComponent<CharacterController>();
       

    }

    private void FixedUpdate()
    {
        animator.SetBool("Grounded", characterController.isGrounded);

        if (characterController.isGrounded)
        {
            // We are grounded, so recalculate
            // move direction directly from axes
            moveDirection = new Vector3(xMove, 0.0f, yMove);
            moveDirection *= speed;

            // Face in direction of movement.
            if (moveDirection.magnitude > float.Epsilon)
            {
                transform.rotation = Quaternion.LookRotation(moveDirection);
            }

            animator.SetFloat("MoveSpeed", moveDirection.magnitude);

            if (jump)
            {
                moveDirection.y = jumpSpeed;
            }



        }

        // Apply gravity. Gravity is multiplied by deltaTime twice (once here, and once below
        // when the moveDirection is multiplied by deltaTime). This is because gravity should be applied
        // as an acceleration (ms^-2)
        moveDirection.y -= gravity * Time.fixedDeltaTime;

        // Move the controller
        characterController.Move(moveDirection * Time.fixedDeltaTime);


        
    }

    void Update()
    {
        xMove = Input.GetAxis("Horizontal");
        yMove = Input.GetAxis("Vertical");

        jump = Input.GetButton("Jump");
    }

}