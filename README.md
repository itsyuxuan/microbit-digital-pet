# microbit-digital-pet

An interactive digital pet DJ on the BBC micro:bit v2 (ANU COMP2300 assignment).

## Design

### Program

We develop an ARMv7 assembly program that simulates a digital pet DJ. The digital pet is displayed by the LEDs on the micro:bit, and it allows interactions with the buttons. Theoretically, it contains three attributes: state, health value and hunger value. And particularly, the interactions vary in terms of four states. 

- **Normal state**
  - **Display: ** The normal face is shown randomly over the screen, interspersed with some rare faces.
  - **Interaction: ** The user can press buttons A and B to manipulate the tone of the byte beat music, and arrows will show accordingly. The pet's hunger value is increasing by this time, and it will trigger the hunger state eventually.
- **Hunger state**
  - **Display: ** A sad face is shown, with a byte beat imitating the sound of a siren.
  - **Interaction: ** The user can touch the LOGO to proceed to the eating state, otherwise the pet's health value continues to drop until death.
- **Eating state**
  - **Display: ** A beating heart is shown, with a byte beat imitating the sound of a pump.
  - **Interaction: ** The user can press either of the buttons to increase the pet's health. If the pet's health value drops out, the death state will be triggered. If the pet's health value is full, the pet will return to its normal state.
- **Death state**
  - **Display: ** A skull is shown, with a byte beat imitating the sound of pulses.
  - **Interaction: ** The user can touch the LOGO to reset the digital pet and start over from the normal state.

## Implementation

### Project structure

```
src
 ┣ frame.S
 ┣ main.S
 ┣ rand.S
 ┗ shinLED.S
```

### Control flow

The `main` function first initialises the micro:bit audio function by calling `audio_init`, then enters an infinite loop, waiting for interrupts to occur.

`SysTick` interrupts are set up to occur every 1/4 seconds to renew the light and sound for the next frame of the display according to the pet attributes.

`GPIOTE` interrupts are connected to BTN_A, BTN_B, and LOGO, and they are used to change the pet attribute data essentially.

## Analysis

### Validity

Our program imitates a pet DJ that is vivid on-screen and capable of manipulating byte beat music through buttons, which lives up to our goal of an interactive digital pet.

### Decisions

- We decide to cool down the channel that triggers the GPIOTE interrupt for a certain time. It is because when a button/logo is pressed/touched, the change of voltage isn't straight as going from low to high; hence user experience can be hurt.

### Future work

- When the power is disconnected, the digital pet data won't exist. This can be improved by using non-volatile memory to store the pet data.

  
