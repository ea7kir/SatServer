# PTT SEQUENCE

This is how the PTT action is implemented.

## RF CONNECTIONS:

### Pluto --> CN4017 --> Filter -->  PA input --> PA final --> POTY

## DC CONNECTIONS:

 When 12v & 28v PSUs are ON
 
 5v  --> Pluto
 5v  --> Relay 5 --> CN4017
 28v --> PA input stage
 28v -->  Relay 6 --> PA Bias
 28v --> PA final stage

## ENABLE PTT: only when Relays 5 & 6 OFF

 1 - transfer & lock Pluto parameters
 2 - delay 200ms
 3 - enable Relay 6 PA Bias (only when NO RF is applied)
 4 - delay 200ms
 5 - enable Relay 5 TX CN4017 Driver

## DISABLE PTT: only when Relays 5 & 6 are ON

 1 - disable Relay 5 CN4017 TX Driver
 2 - delay 200ms
 3 - disable Relay 6 PA Bias to save current
 4 - delay 200ms
 5 - unlock Pluto parametrs
