---
applyTo: '**'
---
# Figma Design Implementation Guidelines

This project uses Figma designs as the source of truth for UI/UX. The Figma folder contains reference images for each screen. Follow these standards when implementing or updating UI:

## General Principles
- Match layouts, spacing, and alignment to the Figma images as closely as possible.
- Use the specified fonts, font weights, and colors from the Figma designs.
- Use consistent padding and margin as shown in the Figma screenshots.
- Use the correct icons and images as per the Figma assets.
- Button shapes, sizes, and colors should match the Figma reference.
- Follow the navigation flow and screen transitions as depicted in the Figma screens.
- **AI Assistant Interaction:** When providing code modifications or suggestions, do not alter the existing frontend UI code (e.g., the `build` method of widgets, UI layout, styling, or visual presentation) unless explicitly instructed to do so. Focus on backend logic, state management, data handling, and functional implementations as requested. If a backend change necessitates a frontend change for it to function, please state this clearly and await explicit instruction before modifying the frontend.

## Naming and Structure
- Name widgets, classes, and files according to the screen/function shown in Figma (e.g., `LoginScreen`, `RegisterScreen`).
- Organize code so each major screen in Figma has a corresponding Dart file.
- Use custom widgets for reusable UI components that appear in multiple Figma screens.

## Colors & Typography
- Use the exact color codes and font families as shown in Figma. If not available, use the closest match in Flutter.
- Font sizes and weights should match the Figma design. Use custom fonts if provided in the assets/fonts directory.

## Images & Assets
- Use images from the assets/images directory that correspond to those in the Figma folder.
- If an image or icon is missing, use a placeholder and note it for later replacement.

## Responsiveness
- Ensure layouts are responsive and look good on different device sizes, while maintaining the proportions from Figma.

## Review
- Before finalizing a screen, compare the implementation side-by-side with the Figma image in the Figma folder.
- Adjust spacing, font sizes, and colors as needed to achieve visual parity.

## Figma Screens Reference
- Each PNG in the Figma/ folder corresponds to a screen or feature. Refer to the appropriate image when working on a screen.
- Example mapping:
  - `Figma/Welcome.png` → Welcome screen
  - `Figma/Login.png` → Login screen
  - `Figma/Register.png` → Register screen
  - ...and so on for all images in the Figma folder.

## Collaboration
- If you make UI changes, update this file if new standards or patterns are introduced.
- Communicate with the team if you find discrepancies between Figma and the current implementation.