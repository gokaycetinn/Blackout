#  BLACKOUT

<div align="center">
  <img src="assets/ui/main_menu_bg.png" alt="Blackout Main Menu" width="100%">
  <p><i>Flickering light, dying batteries, and claws echoing through the pitch-black corridors...</i></p>
  
  <p>
    <img src="https://img.shields.io/badge/Engine-Godot%204.x-blue?style=for-the-badge&logo=godotengine&logoColor=white" alt="Godot Engine">
    <img src="https://img.shields.io/badge/Genre-Survival%20Horror%20%2F%20Stealth-red?style=for-the-badge" alt="Genre">
    <img src="https://img.shields.io/badge/Platform-PC-orange?style=for-the-badge" alt="Platform">
  </p>
</div>

---

**BLACKOUT** is a tense, atmospheric **2D Top-Down Survival-Horror & Stealth** prototype built on the Godot 4 engine. Players assume the role of an **Inspector** sent to investigate a sudden power failure and blackout at a remote subterranean research facility. Soon, you find yourself trapped with horrific biological threats. Armed only with a flashlight and a submachine gun, you must restore power to the console systems, manage your scarce resources, and confront the monstrous Queen spider lurking in the deepest sector.

---

##  Gameplay Demo (Video)

Watch the atmospheric gameplay dynamics, tactical stealth mechanics, flashlight battery drainage, and intense boss encounter below:

<div align="center">
  <video src="Blackout.mp4" width="100%" controls alt="Blackout Gameplay Demo"></video>
  <p><i>(Once the demo video file <b>Blackout.mp4</b> is added to the repository, it will be playable directly in this section.)</i></p>
</div>

---

##  Key Gameplay Systems

###  Dynamic Flashlight & Battery Management
The facility is shrouded in complete darkness. Your primary tool is a flashlight that runs on batteries. As power drains, the beam will flicker and grow dim. You must scan rooms carefully to locate spare batteries to survive the darkness.

###  Stealth & Noise-Detection AI
Enemies respond dynamically to the sounds you make and your visibility level:
- **Crouch-walking (Ctrl):** Generates zero noise, lowering your visibility but reducing movement speed.
- **Sprinting (Shift):** Allows rapid evasion but creates significant noise, instantly alerting nearby guards.
- **Combat / Gunfire:** Discharging your weapon alerts and attracts all hostiles in the sector immediately.

### 🔋 Power Generators
In order to unlock the heavy security gates and reach the exit, you must locate and interact with the **Generator Consoles** to restore power. Activating them is a loud process that draws unwanted attention.

---

##  Characters & Enemies

### 🕵️‍♂️ The Inspector (Player Character)
<table align="center">
  <tr>
    <td width="30%" align="center">
      <img src="assets/sci-fi-facility-asset-pack/inspector_spritesheet.png" width="150px" alt="The Inspector"><br>
      <code>inspector_spritesheet.png</code>
    </td>
    <td width="70%">
      <strong>The Inspector</strong><br><br>
      A high-ranking security investigator sent to investigate the silent facility. Highly trained but physically vulnerable to the horrors in the dark.
      <ul>
        <li><strong>Abilities:</strong> 8-directional movement, Sprinting, Crouch-stealth, and a quick evasion Dash (Space).</li>
        <li><strong>Inventory:</strong> Flashlight (battery-powered), SMG (Submachine gun with limited ammo), and Medkits.</li>
      </ul>
    </td>
  </tr>
</table>

###  Corrupted Facility Guards
<table align="center">
  <tr>
    <td width="30%" align="center">
      <img src="assets/sci-fi-facility-asset-pack/guard_orange_spritesheet.png" width="150px" alt="Corrupted Guard"><br>
      <code>guard_orange_spritesheet.png</code>
    </td>
    <td width="70%">
      <strong>Orange Guard</strong><br><br>
      Former facility security personnel mutated by an airborne pathogen. They patrol the corridors blindly, relying on advanced hearing and movement detection to hunt down survivors.
      <ul>
        <li><strong>AI States:</strong> Patrol, Suspicious, Investigating, Chasing, and Searching.</li>
      </ul>
    </td>
  </tr>
</table>

###  Spider Boss
<table align="center">
  <tr>
    <td width="30%" align="center">
      <img src="assets/sprites/spider boss/Spider Actions/walk/actions0001.png" width="180px" alt="The Queen Walk"><br>
      <code>The Queen (Spider Boss)</code>
    </td>
    <td width="70%">
      <strong>The Queen</strong><br><br>
      A massive mutated arachnid queen nesting in the deep maintenance levels (Level 2). She possesses a dedicated health bar UI, dynamic combat phases, and lethal melee slash attacks.
      <ul>
        <li><strong>Advanced Combat AI:</strong> Transitions dynamically through walking, lunging, staggering, and attacking.</li>
        <li><strong>Special Attack:</strong> Unleashes a wide claw slash causing screen-shakes and massive damage.</li>
      </ul>
    </td>
  </tr>
</table>

---

##  Death Sequence

To emphasize her mechanical defeat in Level 2, the Queen Spider Boss features a dramatic, multi-frame collapse and death animation, transitioning from her imposing active state to a curled, lifeless form:

<div align="center">
  <table>
    <tr>
      <td align="center" width="33%"><b>1. Active / Battle State</b></td>
      <td align="center" width="33%"><b>2. Collapsing / Hurt State</b></td>
      <td align="center" width="33%"><b>3. Defeated / Lifeless State</b></td>
    </tr>
    <tr>
      <td align="center"><img src="assets/sprites/spider boss/Spider Actions/idle/actions0081.png" width="180px" alt="Active Queen"></td>
      <td align="center"><img src="assets/sprites/spider boss/Spider Actions/death/actions0185.png" width="180px" alt="Collapsing Queen"></td>
      <td align="center"><img src="assets/sprites/spider boss/Spider Actions/death/actions0217.png" width="180px" alt="Defeated Queen"></td>
    </tr>
    <tr>
      <td align="center"><code>idle/actions0081.png</code></td>
      <td align="center"><code>death/actions0185.png</code></td>
      <td align="center"><code>death/actions0217.png</code></td>
    </tr>
  </table>
</div>

---

##  Controls

| Input | Action | Description |
| :--- | :--- | :--- |
| **W / A / S / D** | Movement | Moves the Inspector in 8 directions. |
| **Shift** | Sprint | Moves faster but emits high noise levels (alerts AI). |
| **Ctrl** | Crouch | Walks silently, lowering visibility and noise profile. |
| **Space** | Dash | Performs a swift directional dodge to evade close-range strikes. |
| **F** | Flashlight | Toggles the flashlight beam ON/OFF. |
| **E** | Interact | Collects items, hides in lockers, or operates consoles. |
| **Left Click** | Shoot | Fires the SMG weapon (creates loud deafening noise). |
| **Esc** | Pause | Halts gameplay and opens the options/pause menu. |

---

##  Installation & Setup

1. Install **Godot Engine 4.x** (version 4.6 or later recommended).
2. Clone the repository to your local directory:
   ```bash
   git clone https://github.com/gokaycetinn/Blackout.git
   ```
3. Open Godot Project Manager, select **Import**, and choose the `project.godot` file.
4. Run the project from the main menu scene: `scenes/ui/main_menu.tscn` or `scenes/main.tscn`.

---

<div align="center">
  <p><b>BLACKOUT</b> is a CENG361 Final Project.</p>
  <p>© 2026. All Rights Reserved.</p>
</div>
