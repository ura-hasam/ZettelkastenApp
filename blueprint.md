# Zettelkasten App Blueprint

## Overview

This document outlines the plan for creating a Zettelkasten app. The app will allow users to create and manage notes, with AI-powered features for linking and organizing them. This will provide an easy way for users to experience the Zettelkasten method.

## Current Plan

### Milestone 2: Note-Taking and Management

4.  **Note Persistence:** Store notes locally on the device.

### Milestone 3: AI-Powered Linking

1.  **AI Integration:** Integrate a generative AI model for text analysis.
2.  **Link Generation:** Use the AI to suggest links between notes based on their content.
3.  **Link Visualization:** Display the generated links in a user-friendly way.

## Implemented Features

### Milestone 1: Core App Structure and UI

*   **Project Initialization:** The project has been created.
*   **Blueprint:** The `blueprint.md` file has been created.
*   **Dependencies:** `google_fonts` for typography, `provider` for theme management and `uuid` for unique id generation have been added.
*   **Theming:** Implemented a `ThemeProvider` to handle light and dark modes.
*   **Initial UI:** Designed a basic UI with a home screen and navigation to the note creation screen.

### Milestone 2: Note-Taking and Management

*   **Note Model:** Defined a data model for the notes in `lib/note.dart`.
*   **Note Creation:** Implemented the UI for creating new notes in `lib/note_edit_screen.dart`.
*   **Note Display:** Implemented a view to display a list of existing notes in `lib/main.dart`.
