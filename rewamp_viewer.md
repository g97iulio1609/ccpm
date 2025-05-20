# Piano di Rewamp UI/UX - ExerciseTimer

## Obiettivi
- Modernizzazione completa dell'interfaccia
- Miglioramento dell'esperienza utente
- Aggiunta di nuove funzionalità
- Ottimizzazione per l'accessibilità

## 1. Modernizzazione del Design

### Interfaccia Base
- **Tema Scuro Evoluto**: Migliorare il contrasto e utilizzare sfumature più profonde per evidenziare meglio i controlli
- **Sistema di Elevazione**: Utilizzare shadow e blur più sofisticati per creare gerarchia visiva
- **Palette Colori**: Introdurre accenti di colore secondari per distinguere funzionalità (es. verde per avvio, rosso per stop)

### Timer Circolare
- **Visualizzazione Avanzata**: Aggiungere un'animazione fluida più avanzata con effetto pulse negli ultimi 5 secondi
- **Design Bicolore**: Utilizzare un anello esterno statico e uno interno animato con effetto sfumato
- **Indicatori a Tacca**: Aggiungere tacche sul cerchio per indicare i quarti (15s, 30s, 45s)

## 2. Miglioramenti UX

### Navigazione e Controlli
- **Gesture Control**: Implementare swipe verticale per passare tra input e timer
- **Modalità Compatta**: Aggiungere pulsante per ridurre il bottom sheet a una visualizzazione mini-timer flottante
- **Haptic Feedback**: Vibrazioni sottili alla fine del countdown o quando si cambia serie

### Presets Timer
- **Presets Visivi**: Sostituire i bottoni testuali con cards visive dimensionate proporzionalmente al tempo
- **Categorizzazione**: Aggiungere colori o icone per categorizzare (recupero breve/lungo, HIIT, ecc.)
- **Quick-add**: Aggiungere pulsante "+" direttamente accanto all'ultimo preset usato

## 3. Nuove Funzionalità

### Smart Tracking
- **Suggerimento Automatico**: Analizzare gli ultimi allenamenti per suggerire tempi di recupero ottimali
- **Serie Progressive**: Implementare un indicatore visivo che mostri quando il peso aumenta nella serie successiva
- **Stato Allenamento**: Aggiungere indicatore di progresso dell'allenamento complessivo (es. "3/8 serie completate")

### Sound Design
- **Alert Sonori**: Suoni distintivi per inizio/fine timer con possibilità di personalizzazione
- **Countdown Vocale**: Opzione per annuncio vocale degli ultimi 5 secondi
- **Musica Integration**: Controllo volume musica durante il timer (abbassare automaticamente)

## 4. Accessibilità
- **Modalità Alto Contrasto**: Visualizzazione ottimizzata per persone con problemi di vista
- **Pulsanti Dimensionati**: Ingrandire aree touch per facilitare l'uso durante l'allenamento
- **VoiceOver Support**: Migliorare compatibilità con screen reader

## Piano di Implementazione

### Fase 1: Design e Prototipazione
- **1.1**: Ridisegnare il timer circolare con nuovo stile e animazioni
- **1.2**: Creare nuova UI per la selezione dei preset
- **1.3**: Redesign degli input fields e dei controlli
- **1.4**: Progettare modalità compatta

### Fase 2: Implementazione Core UI
- **2.1**: Implementare nuovo timer circolare con animazioni avanzate
- **2.2**: Sviluppare nuova visualizzazione preset
- **2.3**: Integrare nuovi controlli e input
- **2.4**: Implementare gesture control

### Fase 3: Implementazione Funzionalità Avanzate
- **3.1**: Aggiungere modalità compatta
- **3.2**: Implementare smart tracking e suggerimenti
- **3.3**: Integrare haptic feedback
- **3.4**: Sviluppare sistema sonoro

### Fase 4: Ottimizzazione e Accessibilità
- **4.1**: Implementare modalità alto contrasto
- **4.2**: Ottimizzare aree touch
- **4.3**: Migliorare supporto screen reader
- **4.4**: Test di usabilità e performance

### Fase 5: Finalizzazione
- **5.1**: Raccolta feedback e iterazioni finali
- **5.2**: Documentazione
- **5.3**: Rilascio e monitoraggio

## Priorità delle Funzionalità

### Priorità Alta
1. Redesign timer circolare
2. Nuova UI per preset
3. Gesture control
4. Haptic feedback

### Priorità Media
1. Modalità compatta
2. Smart tracking
3. Alert sonori
4. Miglioramenti accessibilità

### Priorità Bassa
1. Countdown vocale
2. Integrazione musica
3. Categorizzazione avanzata preset 