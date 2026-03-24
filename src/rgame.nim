import raylib

# ----------------------------------------------------------------------------------------
# Global Variables Definition
# ----------------------------------------------------------------------------------------

let
  screenWidth  = (1080 * getWindowScaleDPI().x).int32
  screenHeight  = (720 * getWindowScaleDPI().x).int32

# ----------------------------------------------------------------------------------------
# Program main entry point
# ----------------------------------------------------------------------------------------

proc main =
  # Initialization
  # --------------------------------------------------------------------------------------
  initWindow(screenWidth, screenHeight, "raylib [core] example - basic window")
  defer: closeWindow()
  setTargetFPS(60) 
  # --------------------------------------------------------------------------------------
  # Main game loop
  while not windowShouldClose(): # Detect window close button or ESC key
    # Update
    # ------------------------------------------------------------------------------------
    # TODO: Update your variables here
    # ------------------------------------------------------------------------------------
    # Draw
    # ------------------------------------------------------------------------------------
    beginDrawing()
    clearBackground(RayWhite)
    drawText("Congrats! You created your first window!", 190, 200, 20, LightGray)
    endDrawing()
    # ------------------------------------------------------------------------------------
  # De-Initialization
  # --------------------------------------------------------------------------------------


when isMainModule:
  main()
