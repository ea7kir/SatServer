# CONNECTIONS

**TODO:** add more pictures and diagrams.

## AC Power Switching

![Power Distriibution](Images/PowerDistriibution.jpg)

## Raspberry Pi 4B 40 Pin Connector

**This is likely to change!** Relays 6 an 7 are reserved for future use.

![RPi Sever Pins](Images/RPiSeverPins.jpg)

Note 1: The 8 Relay GPIOs use inverse logic levels, so require pull up resistors to prevent the relays engaging befores the SatServer first runs. **However, because the optical couplers will be supplied with only 3.3v, NO PULLUP RESISTORS SHOULD BE INSTALLED**.

Note 2: Enter `ls -l /sys/bus/w1/devices/` to discover the 1-Wire slave IDs.

Note 3: The I2C BUS and 1-Wire BUS also require pull up resistors.

Note 4: Enter `sudo i2cdetect -y 1` to discover the I2C addresses.

## 8 Channel DC 5V Relay Module with Optocoupler

![8-Way Relay Board](Images/8-WayRelayBoard.jpg)

Power the relays from the 5v power supply by removing the jumper and connect as follows.

```
BLACK   GND         GND
WHITE   VCC         3.3v PWR
RED     JD-VCC      5v power supply
```

##  DS18B20 TO-92 Temperature Sensors

2 are used to monitor the PA Driver and Final PA.  Each device comes with a unique slave ID.

```
SCREEN  1          GND
WHITE   2          DATA
RED     3          3.3v PWR
```

## SHT31 Outdoor Humidity & Temperature Sensor

An SHT31 is used to monitor the enclosure.  The default I2C address is 0x44.

```
RED        3.3v PWR
GREEN      SDA
YELLOW     SCL
BLACK      GND
```

## INA226 0-36V 20A Voltage Current Sensor Module

Three are used to monitor the 5v, 12b and 28v power supplies. The default I2C address is 0x40, so 2 of the devices will need to be changed as follows...

```
    |       5V = 0x40      |      12V = 0x41      |      28V = 0x42      |
    |   G    V    L    A   |   G    V    L    A   |   G    V    L    A   |
A0  |   X                  |        X             |                  X   |
    |                      |                      |                      |
A1  |   X                  |   X                  |   X                  |

                        G=GND, V=VS, L=SCL, A=SDA
```

I2C BUS connections...

```
BLACK   1          GND
YELLOW  2          SCL
GREEN   3          SDA
RED     4          3.3v PWR
```

Power supply and load connections...

```
PSU +ve ----> V+(VBUS)

PSU +ve ----> ISENSE+

              ISENSE- ----> LOAD +ve

PSU -ve -----> GND -------> GND -ve
```

## Interconnections

```
BUS

5v	    -> Ethernet Switch
        -> Server Pi
        -> Server Fan
        -> 8-Way Relay 5v
        -> Relay 2 -> RX Pi - if psu12vIsOn
        -> Relay 4 -> TX Pluto Vcc - if psu28vIsOn
        -> Relay 5 -> TX Driver Vcc PTT - if psu28vIsOn

12v	    -> RX MiniTiouner, RX Fan, Intake Fan, Extract Fan
        -> Relay 3 -> Pluto Fan, Driver Fan, PA LH Fan, PA RH Fan - if psu28vIsOn

28v	    -> PA Vcc
        -> Relay 6 -> PA Bias PTT

RELAYS 0...7

24v AC	Relay 0 -> 12v Contactor

24v AC	Relay 1 -> 28v Contactor

5v	    Relay 2 -> RX Pi Vcc

12v	    Relay 3 -> Pluto Fan, Driver Fan, PA LH Fan, PA RH Fan - if psu28vIsOn

5v	    Relay 4 -> TX Pluto Vcc - if psu28vIsOn

5v	    Relay 5 -> TX Driver Vcc PTT - if psu28vIsOn

28v	    Relay 6 -> PA Bias PTT

        Relay 7 -> reserved
```
