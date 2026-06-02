# Registro de Uso de IA - App Móvil

**Herramienta:** Antigravity (Google DeepMind)  
**Modelo:** Gemini 3.5 Flash / Pro

---

### 1. Creación de la pantalla del Asistente (Chatbot)
*   **Prompt:** "Créame la pantalla del asistente siguiendo la lógica del creado en web pero con el diseño de mensajes de la app."
*   **Incoherencias:** El compilador de Flutter reportó un error crítico en `assistant_screen.dart` debido a que `Border.top` no existe como propiedad estática.
*   **Solución:** Se corrigió en `assistant_screen.dart` utilizando el constructor correcto `Border(top: BorderSide(...))` para dibujar el borde superior de la barra de entrada del chat.
