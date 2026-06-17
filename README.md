# EETAC Virtual Assistant - Mobile App (EA_APP_G5)

Aquest és el directori de l'aplicació mòbil en Flutter per a la implementació de l'assistent virtual acadèmic **"Toni"** de la EETAC.

## Descripció de l'Estat de l'Exercici
L'exercici s'ha completat al **100%** i es troba completament connectat amb el backend local i operatiu.

---

## Parts Operatives

1. **Pantalla de l'Assistent (`lib/screens/assistant_screen.dart`)**:
   - Desenvolupament de la interfície de xat (`AssistantScreen`) per a dispositius mòbils seguint les directrius de disseny d'Atenea/EETAC.
   - Bombolles de diàleg diferenciades per colors (`AppColors.accent` per a l'usuari i `AppColors.containerBg` amb vores per a Toni).
   - Neteja de caràcters de capçalera Markdown (`#`, `##`, `###`) i processament de negretes (`**texto**`) per a una llegibilitat perfecta.
   - Indicador de càrrega dinàmic ("Toni está pensando...") mentre es rep la resposta del servidor.
   - Desplaçament automàtic cap a baix al rebre respostes.

2. **Accés i Navegació (`lib/screens/messages_screen.dart`)**:
   - Afegit un nou botó de robot (`Icons.smart_toy_outlined`) a la barra superior (`AppBar`) de la pantalla de missatges, just al costat del botó de menjar/afegir `+`.
   - Navegació integrada utilitzant GetX (`Get.to`) cap a la pantalla del xatbot.

3. **Servei i Integració API (`lib/services/assistant_service.dart`)**:
   - Creat el servei de connexió utilitzant la instància de `AuthService.dio` per incloure automàticament les capçaleres de seguretat `Bearer Token`.
   - Peticions POST configurades contra l'endpoint `/assistant/chat` del backend.

4. **Configuració de Xarxa (`lib/constants/api_constants.dart` i `lib/services/notification_service.dart`)**:
   - Enllaç de l'aplicació actualitzat per utilitzar `http://localhost:1337` (localhost del backend) en comptes d'una IP estàtica de desenvolupament prèvia.

---

## Parts Pendents de Codificar
- **Cap**: Totes les funcionalitats del xatbot per a l'aplicació mòbil estan 100% desenvolupades i operatives.
